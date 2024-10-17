using EasyContext
using EasyRAGStore
using PromptingTools
using PromptingTools.Experimental.RAGTools
using OrderedCollections
using JLD2
using EasyContext: get_index
using EasyRAGStore: get_questions
using Statistics
using Dates
using SHA



function evaluate_relevance(filtered_results, reference_solution)
    new_solution_sources = Set(filtered_results)
    reference_sources = Set(reference_solution)
    
    true_positives = length(intersect(new_solution_sources, reference_sources))
    false_positives = length(setdiff(new_solution_sources, reference_sources))
    false_negatives = length(setdiff(reference_sources, new_solution_sources))
    
    recall = length(reference_sources) > 0 ? true_positives / length(reference_sources) : 0.0
    precision = length(new_solution_sources) > 0 ? true_positives / length(new_solution_sources) : 0.0
    f1_score = (precision + recall > 0) ? 2 * (precision * recall) / (precision + recall) : 0.0
    
    return (
        recall = recall,
        precision = precision,
        f1_score = f1_score,
        true_positives = true_positives,
        false_positives = false_positives,
        false_negatives = false_negatives
    )
end

function compare_solutions(solution_store::SolutionStore, index_id::String, config1_id::String, config2_id::String)
    if !haskey(solution_store.data, index_id) || 
       !haskey(solution_store.data[index_id], config1_id) || 
       !haskey(solution_store.data[index_id], config2_id)
        error("Invalid index_id or config_ids")
    end

    solutions1 = solution_store.data[index_id][config1_id]["solutions"]
    solutions2 = solution_store.data[index_id][config2_id]["solutions"]

    metrics = []

    for (question, filtered_sources1) in solutions1
        if !haskey(solutions2, question)
            error("Questions do not match between configurations")
        end
        filtered_sources2 = solutions2[question]

        relevance_scores = evaluate_relevance(filtered_sources1, filtered_sources2)
        push!(metrics, relevance_scores)
    end

    avg_metrics = (
        recall = mean(m.recall for m in metrics),
        precision = mean(m.precision for m in metrics),
        f1_score = mean(m.f1_score for m in metrics),
        true_positives = sum(m.true_positives for m in metrics),
        false_positives = sum(m.false_positives for m in metrics),
        false_negatives = sum(m.false_negatives for m in metrics)
    )

    return avg_metrics
end

function compare_all_configs(solution_store::SolutionStore)
    results = Dict()
    
    for (index_id, index_data) in solution_store.data
        results[index_id] = Dict()
        config_ids = collect(keys(index_data))
        
        for i in 1:length(config_ids)
            for j in (i+1):length(config_ids)
                config1_id = config_ids[i]
                config2_id = config_ids[j]
                
                comparison_result = compare_solutions(solution_store, index_id, config1_id, config2_id)
                results[index_id]["$(config1_id)_vs_$(config2_id)"] = comparison_result
            end
        end
    end
    
    return results
end

function print_comparison_results(comparison_results)
    for (index_id, index_comparisons) in comparison_results
        println("Index: $index_id")
        for (comparison, metrics) in index_comparisons
            println("  Comparison: $comparison")
            println("    Recall: $(round(metrics.recall, digits=3))")
            println("    Precision: $(round(metrics.precision, digits=3))")
            println("    F1 Score: $(round(metrics.f1_score, digits=3))")
            println("    True Positives: $(metrics.true_positives)")
            println("    False Positives: $(metrics.false_positives)")
            println("    False Negatives: $(metrics.false_negatives)")
        end
        println()
    end
end

# Example usage
function run_benchmarks(solution_file::String)
    solution_store = SolutionStore(solution_file)
    comparison_results = compare_all_configs(solution_store)
    print_comparison_results(comparison_results)
    return comparison_results
end
