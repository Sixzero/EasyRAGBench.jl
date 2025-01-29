using EasyContext
using EasyRAGStore
using PromptingTools
using PromptingTools.Experimental.RAGTools
using OrderedCollections
using JLD2
using EasyContext: search, AbstractRAGConfig, get_source
using EasyRAGStore: get_questions
using ProgressMeter
using Dates
using EasyRAGStore: ensure_loaded!


function generate_solution(store::RAGStore, index_id::String, config::AbstractRAGConfig, existing_solutions::OrderedDict{String, Vector{String}})
    chunks = EasyRAGStore.get_index(store, index_id)
    questions = get_questions(store, index_id)

    solutions = OrderedDict{String, Vector{String}}()
    timings = OrderedDict{String, Float64}()

    for question in questions
        if haskey(existing_solutions, question.question)
            solutions[question.question] = existing_solutions[question.question]
        else
            time_taken = @elapsed begin
                filtered_results = search(config, chunks, question.question)
                solutions[question.question] = get_source.(filtered_results)
            end
            timings[question.question] = time_taken
        end
    end

    metadata = Dict{String,Any}("config" => config)
    current_time = now()
    return SolutionResult(solutions, timings, current_time, metadata)
end

function generate_all_solutions(store::RAGStore, solution_store::SolutionStore, configs::Vector{<:AbstractRAGConfig})
    ensure_loaded!(store)
    index_ids = collect(keys(store.dataset_store.chunks))
    total_indices = length(index_ids)
    
    @info "Starting to generate solutions for $total_indices indices"
    
    progress = Progress(total_indices, desc="Generating solutions: ", showspeed=true)

    ntasks = Threads.nthreads()
    ntasks = 8
    # ntasks = 1
    map(enumerate(index_ids)) do (i, index_id)
        for (j, config) in enumerate(configs)
            @show config
            config_id = humanize(config)
            existing_solutions = get_solutions(solution_store, index_id, config_id)
            result = generate_solution(store, index_id, config, existing_solutions)
            add_solutions!(solution_store, index_id, config_id, result)
            
            println("  Completed config $j/$(length(configs)) for index $index_id")
        end
        
        next!(progress; showvalues = [(:index, "$i/$total_indices"), (:current_id, index_id)])
        println()
    end
    
    @info "Generated and saved all solutions to $(solution_store.filename)"
    @info "Total indices processed: $total_indices"
end

# Example usage
function run_generation(rag_dataset_name::String, solution_file::String, configs::Vector{<:AbstractRAGConfig})
    rag_store = RAGStore(rag_dataset_name)
    solution_store = SolutionStore(solution_file)
    
    generate_all_solutions(rag_store, solution_store, configs)
    
    return solution_store
end

