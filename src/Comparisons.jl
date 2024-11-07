
function compare_solutions(solution_store::SolutionStore, index_id::String, config1_id::String, config2_id::String)::RelevanceMetrics
    if !haskey(solution_store.data, index_id) || 
       !haskey(solution_store.data[index_id], config1_id) || 
       !haskey(solution_store.data[index_id], config2_id)
        error("Invalid index_id or config_ids")
    end

    solutions1 = solution_store.data[index_id][config1_id]["solutions"]
    solutions2 = solution_store.data[index_id][config2_id]["solutions"]

    metrics = Vector{RelevanceMetrics}()
    for (question, filtered_sources1) in solutions1
        haskey(solutions2, question) || error("Questions do not match between configurations")
        filtered_sources2 = solutions2[question]
        push!(metrics, evaluate_relevance(filtered_sources1, filtered_sources2))
    end

    summarize(metrics)
end

function compare_solutions_to_reference(index_data::Dict{String, Dict{String, Any}}, reference_config_id::String, config_id::String)::Union{RelevanceMetrics, Nothing}
    if !haskey(index_data, reference_config_id) || !haskey(index_data, config_id)
        return nothing
    end

    reference_solutions = index_data[reference_config_id]["solutions"]
    solutions = index_data[config_id]["solutions"]

    metrics = Vector{RelevanceMetrics}()
    for (question, reference_sources) in reference_solutions
        haskey(solutions, question) || continue
        filtered_sources = solutions[question]
        push!(metrics, evaluate_relevance(filtered_sources, reference_sources))
    end

    summarize(metrics)
end

function compare_solutions_to_reference(solution_store::SolutionStore, index_id::String, reference_config_id::String, config_id::String)::Union{RelevanceMetrics, Nothing}
    haskey(solution_store.data, index_id) && return nothing
    compare_solutions_to_reference(solution_store.data[index_id], reference_config_id, config_id)
end
