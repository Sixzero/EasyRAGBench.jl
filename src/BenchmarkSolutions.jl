using EasyContext
using EasyRAGStore
using Statistics
using OrderedCollections


export RelevanceMetrics, evaluate_relevance, summarize
export compare_solutions, compare_solutions_to_reference
export run_benchmark_comparison

function findfirst(solution_store::SolutionStore, config_id::String)
    for (index_id, index_data) in solution_store.data
        if haskey(index_data, config_id)
            return index_data[config_id]["metadata"]["config"]
        end
    end
    nothing
end

function collect_comparisons(index_data, reference_config_id::String)
    results = Dict()
    ref_config = index_data[reference_config_id]["metadata"]["config"]
    
    for (config_id, config_data) in index_data
        config_id == reference_config_id && continue
        
        metrics = compare_solutions_to_reference(index_data, reference_config_id, config_id)
        isnothing(metrics) && continue
        
        config = config_data["metadata"]["config"]
        results["$reference_config_id vs $config_id"] = (
            metrics=metrics,
            ref_config=ref_config,
            config=config
        )
    end
    results
end

function calculate_mean_scores(comparison_results)
    mean_scores = Dict()
    
    for (index_id, index_comparisons) in comparison_results
        mean_scores[index_id] = Dict()
        for (comparison, result) in index_comparisons
            mean_scores[index_id][comparison] = (
                f1_score = result.metrics.f1_score,
                recall = result.metrics.recall,
                precision = result.metrics.precision,
                ref_config = result.ref_config,
                config = result.config
            )
        end
    end
    mean_scores
end

function calculate_config_overall_scores(mean_scores)
    scores_by_comparison = Dict()
    
    for (_, index_comparisons) in mean_scores
        for (comparison, result) in index_comparisons
            if !haskey(scores_by_comparison, comparison)
                scores_by_comparison[comparison] = Dict(
                    :f1_score => [], :recall => [], :precision => [],
                    :ref_config => result.ref_config,
                    :config => result.config
                )
            end
            push!(scores_by_comparison[comparison][:f1_score], result.f1_score)
            push!(scores_by_comparison[comparison][:recall], result.recall)
            push!(scores_by_comparison[comparison][:precision], result.precision)
        end
    end
    
    config_overall_scores = Dict()
    for (comparison, scores) in scores_by_comparison
        config_overall_scores[comparison] = Dict()
        for metric in [:f1_score, :recall, :precision]
            config_overall_scores[comparison][metric] = mean(scores[metric])
        end
        config_overall_scores[comparison][:ref_config] = scores[:ref_config]
        config_overall_scores[comparison][:config] = scores[:config]
    end
    
    config_overall_scores
end

function calculate_overall_mean_scores(mean_scores, reference_config)
    scores = Dict()
    for metric in [:f1_score, :recall, :precision]
        scores[metric] = mean(
            result[metric]
            for (_, index_comparisons) in mean_scores
            for (comparison, result) in index_comparisons
        )
    end
    scores[:ref_config] = reference_config
    scores
end

function benchmark_against_reference(solution_store::SolutionStore, reference_config_id::String)
    comparison_results = Dict()
    
    # Get reference config
    reference_config = findfirst(solution_store, reference_config_id)
    isnothing(reference_config) && @warn("Reference config not found: $reference_config_id") 
    
    # Collect comparisons
    for (index_id, index_data) in solution_store.data
        comparison_results[index_id] = collect_comparisons(index_data, reference_config_id)
        isempty(comparison_results[index_id]) && delete!(comparison_results, index_id)
    end

    # Calculate scores
    mean_scores = calculate_mean_scores(comparison_results)
    config_overall_scores = calculate_config_overall_scores(mean_scores)
    overall_mean_scores = calculate_overall_mean_scores(mean_scores, reference_config)
    
    return (;
        comparison_results,
        mean_scores,
        config_overall_scores,
        overall_mean_scores
    )
end

function run_benchmark_comparison(solution_file::String, reference_config_id::String, output_dir="benchmark_results")
    solution_store = SolutionStore(solution_file)
    results = benchmark_against_reference(solution_store, reference_config_id)
    
    generate_benchmark_plots(
        results.mean_scores,
        results.config_overall_scores,
        results.overall_mean_scores,
        output_dir
    )
    
    return results
end
