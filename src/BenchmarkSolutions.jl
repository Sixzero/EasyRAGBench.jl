using EasyContext
using EasyRAGStore
using Statistics
using OrderedCollections
using DataFrames  # Add this import

export RelevanceMetrics, evaluate_relevance, summarize
export compare_solutions, compare_solutions_to_reference
export run_benchmark_comparison

# Simple config lookup with clear warnings
function findfirst(solution_store::SolutionStore, config_id::String)
    matches = [(id, data[config_id].metadata["config"]) 
               for (id, data) in solution_store.data 
               if haskey(data, config_id)]
    
    isempty(matches) && (@warn "Config '$config_id' not found"; return nothing)
    length(matches) > 1 && @warn "Config '$config_id' found in multiple indices: $(join(first.(matches), ", "))"
    
    last(first(matches))
end

# Simplified comparison collection
function collect_comparisons(search_results, reference_config_id::String)
    @info "Collecting comparisons" reference_config_id keys(search_results)
    
    !haskey(search_results, reference_config_id) && (@warn "Reference config not found"; return Dict())
    ref_config = search_results[reference_config_id].metadata["config"]
    ref_solutions = search_results[reference_config_id].solutions
    
    results = Dict()
    for (config_id, config_data) in search_results
        config_id == reference_config_id && continue
        
        solutions = config_data.solutions
        missing_questions = setdiff(keys(ref_solutions), keys(solutions))
        !isempty(missing_questions) && @warn "Model $config_id missing solutions for questions: $(join(missing_questions, ", "))"
        
        metrics = compare_solutions_to_reference(search_results, reference_config_id, config_id)
        isnothing(metrics) && continue
        
        results["$reference_config_id vs $config_id"] = (
            metrics = metrics,
            ref_config = ref_config,
            config = config_data.metadata["config"]
        )
    end
    
    @info "Collected comparisons" num_results=length(results) comparison_pairs=keys(results)
    return results
end

# ... other code remains same until calculate_scores ...

struct BenchmarkScores
    # Each row is a reference config, each column is a compared config
    comparison_matrix::DataFrame  # Contains f1, recall, precision for each ref-config pair
    per_chunk_scores::Dict{String, DataFrame}  # Same structure but per chunk
    summary::DataFrame  # Overall summary statistics
end

function calculate_scores(comparison_results)
    @info "Calculating scores" num_chunks=length(comparison_results)
    
    # First collect all unique configs
    ref_configs = Set{String}()
    compared_configs = Set{String}()
    for (_, chunk_comparisons) in comparison_results
        @info "Processing chunk" num_comparisons=length(chunk_comparisons)
        for comparison in keys(chunk_comparisons)
            ref_config, compared_config = split(comparison, " vs ")
            push!(ref_configs, ref_config)
            push!(compared_configs, compared_config)
        end
    end
    ref_configs = sort(collect(ref_configs))
    compared_configs = sort(collect(compared_configs))
    @info "Found configs" num_ref_configs=length(ref_configs) num_compared_configs=length(compared_configs)
    
    # Create per-chunk score matrices
    per_chunk_scores = Dict{String, DataFrame}()
    for (chunk_id, chunk_comparisons) in comparison_results
        scores_df = DataFrame(
            ref_config = String[],
            compared_config = String[],
            f1_score = Float64[],
            recall = Float64[],
            precision = Float64[],
            timing = Float64[]  # Add timing column
        )
        
        for (comparison, result) in chunk_comparisons
            ref_config, compared_config = split(comparison, " vs ")
            # Get mean timing for this config's solutions
            mean_timing = mean(values(result.config.timings))
            push!(scores_df, (
                ref_config,
                compared_config,
                result.metrics.f1_score,
                result.metrics.recall,
                result.metrics.precision,
                mean_timing
            ))
        end
        
        per_chunk_scores[chunk_id] = scores_df
        @info "Chunk scores" chunk_id size(scores_df)
    end
    
    # Create overall comparison matrix
    comparison_matrix = DataFrame(
        ref_config = String[],
        compared_config = String[],
        f1_score = Float64[],
        recall = Float64[],
        precision = Float64[]
    )
    
    # Calculate mean scores across all chunks
    for ref_config in ref_configs
        for compared_config in compared_configs
            ref_config == compared_config && continue
            
            comparison = "$ref_config vs $compared_config"
            
            # Collect scores from all chunks that have this comparison
            chunk_scores = Float64[]
            chunk_recalls = Float64[]
            chunk_precisions = Float64[]
            
            for df in values(per_chunk_scores)
                rows = df[(df.ref_config .== ref_config) .& (df.compared_config .== compared_config), :]
                if nrow(rows) > 0
                    push!(chunk_scores, rows.f1_score[1])
                    push!(chunk_recalls, rows.recall[1])
                    push!(chunk_precisions, rows.precision[1])
                end
            end
            
            # Only add if we have scores
            if !isempty(chunk_scores)
                push!(comparison_matrix, (
                    ref_config,
                    compared_config,
                    mean(chunk_scores),
                    mean(chunk_recalls),
                    mean(chunk_precisions)
                ))
            end
        end
    end
    
    @info "Final matrices" comparison_size=size(comparison_matrix) num_chunks=length(per_chunk_scores)
    
    # Create summary statistics
    summary = combine(
        groupby(comparison_matrix, :ref_config),
        :f1_score => mean => :mean_f1,
        :recall => mean => :mean_recall,
        :precision => mean => :mean_precision,
        :f1_score => std => :std_f1,
        :recall => std => :std_recall,
        :precision => std => :std_precision
    )
    
    BenchmarkScores(comparison_matrix, per_chunk_scores, summary)
end

# Update the benchmark function to use new scoring
function benchmark_against_reference(solution_store::SolutionStore, reference_config_id::String)
    @info "Starting benchmark" reference_config_id
    reference_config = findfirst(solution_store, reference_config_id)
    isnothing(reference_config) && (@warn "Reference config not found"; return nothing)
    
    @info "Found reference config" num_indices=length(solution_store.data)
    
    comparison_results = Dict(
        chunk_id => collect_comparisons(search_results, reference_config_id)
        for (chunk_id, search_results) in solution_store.data
        if !isempty(search_results)
    )
    
    @info "Collected all comparisons" num_chunks=length(comparison_results)
    
    scores = calculate_scores(comparison_results)
    
    (comparison_results=comparison_results, scores=scores)
end

function run_benchmark_comparison(solution_file::String, reference_config_id::String, output_dir="benchmark_results")
    solution_store = SolutionStore(solution_file)
    results = benchmark_against_reference(solution_store, reference_config_id)
    isnothing(results) && return nothing
    
    @info "Benchmark results" comparison_results_size=length(results.comparison_results) scores_size=size(results.scores.comparison_matrix)
    
    # Update plotting function call to use the new DataFrame structure
    generate_benchmark_plots(
        results.scores.comparison_matrix,
        results.scores.per_chunk_scores,
        results.scores.summary,
        output_dir
    )
    results
end
