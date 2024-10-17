using EasyContext
using EasyRAGStore
using PromptingTools
using PromptingTools.Experimental.RAGTools
using OrderedCollections
using JLD2
using EasyContext: get_index
using EasyRAGStore: get_questions
using ProgressMeter
using Dates

function generate_solution(store::RAGStore, index_id::String, config::AbstractRAGPipeConfig, existing_solutions::OrderedDict{String, Vector{String}})
    ordered_dict = EasyRAGStore.get_index(store, index_id)
    questions = get_questions(store, index_id)
    
    embedding_search_reranker = EmbeddingSearchReranker(config, ordered_dict)

    solutions = OrderedDict{String, Vector{String}}()

    for question in questions
        if haskey(existing_solutions, question.question)
            solutions[question.question] = existing_solutions[question.question]
        else
            filtered_results = embedding_search_reranker(question.question)
            solutions[question.question] = collect(keys(filtered_results))
        end
    end
    
    return solutions
end

function generate_all_solutions(store::RAGStore, solution_store::SolutionStore, configs::Vector{<:AbstractRAGPipeConfig})
    index_ids = collect(keys(store.dataset_store.indexes))
    total_indices = length(index_ids)
    
    @info "Starting to generate solutions for $total_indices indices"
    
    progress = Progress(total_indices, desc="Generating solutions: ", showspeed=true)

    for (i, index_id) in enumerate(index_ids)
        for config in configs
            config_id = get_unique_id(config)
            existing_solutions = get_solutions(solution_store, index_id, config_id)
            solutions = generate_solution(store, index_id, config, existing_solutions)
            
            # Add new solutions to the SolutionStore
            metadata = Dict(
                "timestamp" => Dates.now(),
                "config" => config
            )
            add_solutions!(solution_store, index_id, config_id, solutions, metadata)
        end
        
        next!(progress; showvalues = [(:index, "$i/$total_indices"), (:current_id, index_id)])
    end
    
    save_solutions(solution_store)
    
    @info "Generated and saved all solutions to $(solution_store.filename)"
    @info "Total indices processed: $total_indices"
end

# Example usage
function run_generation(rag_dataset_name::String, solution_file::String, configs::Vector{<:AbstractRAGPipeConfig})
    rag_store = RAGStore(rag_dataset_name)
    solution_store = SolutionStore(solution_file)
    
    generate_all_solutions(rag_store, solution_store, configs)
    
    return solution_store
end

