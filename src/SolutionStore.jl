using JLD2
using OrderedCollections
using Dates
using Base.Threads: ReentrantLock, @spawn

"""
SolutionStore Structure:
{index1_id: {
    config1_unique_id: {
        solutions: OrderedDict{String,Vector{String}}(question .=> filtered_sources)
        config: {NamedTuple of type, or I don't want to exactly just save the type because if the type is not loaded then we would need typemap, what would be not that pleasant or maybe it would be useful?}
    },
    config2_unique_id: {...},
},
index2_id: {...}}
"""
struct SolutionStore
    filename::String
    data::Dict{String, Dict{String, Dict{String, Any}}}
    lock::ReentrantLock

    function SolutionStore(filename::String)
        full_path = joinpath(dirname(@__DIR__), "solution", filename)
        data = isfile(full_path) ? load_solutions(full_path) : Dict{String, Dict{String, Dict{String, Any}}}()
        new(full_path, data, ReentrantLock())
    end
end

function load_solutions(filename::String)
    jldopen(filename, "r") do file
        if !haskey(file, "solutions")
            return Dict{String, Dict{String, Dict{String, Any}}}()
        end
        solutions = Dict{String, Dict{String, Dict{String, Any}}}()
        solutions_group = file["solutions"]
        
        for index_id in keys(solutions_group)
            solutions[index_id] = Dict{String, Dict{String, Any}}()
            for config_id in keys(solutions_group[index_id])
                solutions[index_id][config_id] = solutions_group[index_id][config_id]
            end
        end
        return solutions
    end
end

function save_solutions(store::SolutionStore)
    lock(store.lock) do
        temp_file = store.filename * ".temp"
        solutions = store.data
        JLD2.jldsave(temp_file; solutions)
        mv(temp_file, store.filename, force=true)
    end
end

function add_solutions!(store::SolutionStore, index_id::String, config_id::String, solutions::OrderedDict{String, Vector{String}}, metadata::Dict)
    # Check if solution already exists
    if haskey(store.data, index_id) && 
       haskey(store.data[index_id], config_id) &&
       store.data[index_id][config_id]["solutions"] == solutions
        return  # Skip if identical solution already exists
    end
    
    # Append new solutions - creates or updates specific entry
    if !haskey(store.data, index_id)
        store.data[index_id] = Dict{String, Dict{String, Any}}()
    end
    
    data = Dict{String, Any}(
        "solutions" => solutions,
        "metadata" => metadata
    )
    store.data[index_id][config_id] = data
    
    lock(store.lock) do
        # Update just the specific section in the file
        if !isfile(store.filename)
            jldopen(store.filename, "w+", compress=false) do file
                JLD2.Group(file, "solutions")
            end
        end
        
        jldopen(store.filename, "r+") do file
            solutions_group = if !haskey(file, "solutions")
                JLD2.Group(file, "solutions")
            else
                file["solutions"]
            end
            
            index_group = if !haskey(solutions_group, index_id)
                JLD2.Group(solutions_group, index_id)
            else
                solutions_group[index_id]
            end
            
            # Direct update of the config data
            if haskey(index_group, config_id)
                delete!(index_group, config_id)
            end
            index_group[config_id] = data
        end
    end
end

function get_solutions(store::SolutionStore, index_id::String, config_id::String)
    if haskey(store.data, index_id) && haskey(store.data[index_id], config_id)
        return store.data[index_id][config_id]["solutions"]
    else
        return OrderedDict{String, Vector{String}}()
    end
end

function get_solution(store::SolutionStore, index_id::String, config_id::String, question::String)
    solutions = get_solutions(store, index_id, config_id)
    return get(solutions, question, nothing)
end

function get_config(store::SolutionStore, index_id::String, config_id::String)
    if haskey(store.data, index_id) && haskey(store.data[index_id], config_id)
        return store.data[index_id][config_id]["metadata"]["config"]
    end
    return nothing
end

function get_all_solutions(store::SolutionStore, index_id::String)
    if haskey(store.data, index_id)
        return Dict(config_id => data["solutions"] for (config_id, data) in store.data[index_id])
    else
        return Dict{String, OrderedDict{String, Vector{String}}}()
    end
end

function get_reference_solution(store::SolutionStore, index_id::String, question::String)
    solutions = get(store.data, index_id, NamedTuple[])
    @assert length(solutions) > 0
    reference_solution_idx = findfirst(s -> s.question == question, solutions)
    
    if !isnothing(reference_solution_idx)
        reference_solution = solutions[reference_solution_idx]
        if haskey(reference_solution, Symbol(store.solution_key))
            return getproperty(reference_solution, Symbol(store.solution_key))
        else
            @warn "Solution key not found: $store.solution_key"
        end
    else
        return nothing
    end
end

function reset_benchmark_results(solution_store::SolutionStore)
    if haskey(solution_store.data, "benchmarks")
        delete!(solution_store.data, "benchmarks")
        save_solutions(solution_store)
        @info "Benchmark results have been reset in the solution store."
    else
        @info "No benchmark results found in the solution store. Nothing to reset."
    end
end
