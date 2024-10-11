using EasyContext
using EasyRAGBench
using PromptingTools
using PromptingTools.Experimental.RAGTools
using OrderedCollections
using JLD2
using EasyContext: get_index
using EasyRAGBench: get_questions
using ProgressMeter

@kwdef struct StrongFilterConfig
    voyage_model::String = "voyage-code-2"
    top_k::Int = 120
    batch_size::Int = 50
    reranker_model::String = "claude"
    top_n::Int = 10
end

struct StrongFilter
    similarity_filter::Any
    reranker::Any
    config::StrongFilterConfig
    index::Any  # Store the index here

    function StrongFilter(config::StrongFilterConfig, ordered_dict)
        voyage_embedder = create_voyage_embedder(model=config.voyage_model)
        similarity_filter = create_combined_index_builder(voyage_embedder; top_k=config.top_k)
        reranker = ReduceRankGPTReranker(
            batch_size=config.batch_size,
            model=config.reranker_model,
            top_n=config.top_n,
        )
        index = get_index(similarity_filter, ordered_dict, verbose=false)
        new(similarity_filter, reranker, config, index)
    end
end

function (filterer::StrongFilter)(question)
    reranked_results = filterer.similarity_filter(filterer.index, question)
    return filterer.reranker(reranked_results, question)
end

function generate_solution(store::RAGStore, index_id::String, existing_solutions::Vector{NamedTuple}=NamedTuple[])
    ordered_dict = EasyRAGBench.get_index(store, index_id)
    questions = get_questions(store, index_id)
    
    config = StrongFilterConfig()  # Using default values
    strong_filter = StrongFilter(config, ordered_dict)

    solutions = Vector{NamedTuple}()

    for question in questions
        existing_solution = findfirst(s -> s.question == question.question, existing_solutions)
        
        if !isnothing(existing_solution) && haskey(existing_solutions[existing_solution], :solution_claude)
            # If solution_claude exists, use the existing solution
            push!(solutions, existing_solutions[existing_solution])
        else
            # Use the StrongFilter to get the filtered and reranked results
            filtered_results = strong_filter(question.question)
            
            # Store the results
            push!(solutions, (question=question.question, solution_claude=collect(keys(filtered_results))))
        end
    end
    
    return solutions
end

function merge_solutions(existing_solutions, new_solutions)
    # Create a dictionary for quick lookup of existing questions
    solution_dict = Dict(sol.question => sol for sol in existing_solutions)
    
    # Merge existing solutions with new ones
    for new_sol in new_solutions
        if haskey(solution_dict, new_sol.question)
            # Merge all fields from both solutions
            merged_sol = merge(solution_dict[new_sol.question], new_sol)
            solution_dict[new_sol.question] = merged_sol
        else
            solution_dict[new_sol.question] = new_sol
        end
    end
    
    return collect(values(solution_dict))
end

function generate_all_solutions(store::RAGStore, output_file::String)
    output_file = joinpath(dirname(@__DIR__), "solution", output_file)
    
    # Try to load existing solutions
    solutions = if isfile(output_file)
        JLD2.load(output_file, "solutions")
    else
        Dict{String, Vector{NamedTuple}}()
    end
    
    index_ids = collect(keys(store.dataset_store.indexes))
    total_indices = length(index_ids)
    
    @info "Starting to generate solutions for $total_indices indices"
    
    progress = Progress(total_indices, desc="Generating solutions: ", showspeed=true)

    for (i, index_id) in enumerate(index_ids)
        existing_solutions = get(solutions, index_id, NamedTuple[])
        new_solutions = generate_solution(store, index_id, existing_solutions)
        
        # Merge or add new solutions
        solutions[index_id] = merge_solutions(existing_solutions, new_solutions)
        
        # Save progress after each index
        temp_output_file = output_file * ".temp"
        jldsave(temp_output_file; solutions)
        mv(temp_output_file, output_file, force=true)
        
        next!(progress; showvalues = [(:index, "$i/$total_indices"), (:current_id, index_id)])
    end
    
    @info "Generated and saved all solutions to $output_file"
    @info "Total indices processed: $total_indices"
end
