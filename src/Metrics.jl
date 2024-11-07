using Statistics

@kwdef struct RelevanceMetrics
    recall::Float64
    precision::Float64
    f1_score::Float64
    true_positives::Int
    false_positives::Int
    false_negatives::Int
end

function summarize(metrics::Vector{RelevanceMetrics})
    RelevanceMetrics(
        recall = mean(m.recall for m in metrics),
        precision = mean(m.precision for m in metrics),
        f1_score = mean(m.f1_score for m in metrics),
        true_positives = sum(m.true_positives for m in metrics),
        false_positives = sum(m.false_positives for m in metrics),
        false_negatives = sum(m.false_negatives for m in metrics)
    )
end

function evaluate_relevance(filtered_results, reference_solution)
    new_solution_sources = Set(filtered_results)
    reference_sources = Set(reference_solution)
    
    true_positives = length(intersect(new_solution_sources, reference_sources))
    false_positives = length(setdiff(new_solution_sources, reference_sources))
    false_negatives = length(setdiff(reference_sources, new_solution_sources))
    
    recall = length(reference_sources) > 0 ? true_positives / length(reference_sources) : 0.0
    precision = length(new_solution_sources) > 0 ? true_positives / length(new_solution_sources) : 0.0
    f1_score = (precision + recall > 0) ? 2 * (precision * recall) / (precision + recall) : 0.0
    
    return RelevanceMetrics(
        recall = recall,
        precision = precision,
        f1_score = f1_score,
        true_positives = true_positives,
        false_positives = false_positives,
        false_negatives = false_negatives
    )
end
