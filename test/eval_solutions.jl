
using EasyRAGBench: run_generation, run_benchmarks, EmbeddingSearchRerankerConfig
using EasyRAGStore: RAGStore

# Define configurations
configs = [
    EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=120, batch_size=50, reranker_model="gpt4om", top_n=10),
    EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=40, batch_size=50, reranker_model="gpt4om", top_n=10),
]

# Define RAG dataset name and solution file
rag_dataset_name = "workspace_context_log"
solution_file = "all_solutions.jld2"

# Run generation
solution_store = run_generation(rag_dataset_name, solution_file, configs)

# Run benchmarks
comparison_results = run_benchmarks(solution_file)

# Print comparison results
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
#%%
import EasyRAGBench
# If you want to access specific results
index_id = first(keys(solution_store.data))
config_id1 = EasyRAGBench.get_unique_id(configs[1])
config_id2 = EasyRAGBench.get_unique_id(configs[2])

if haskey(comparison_results, index_id) && haskey(comparison_results[index_id], "$(config_id1)_vs_$(config_id2)")
    specific_comparison = comparison_results[index_id]["$(config_id1)_vs_$(config_id2)"]
    println("Specific comparison between configs 1 and 2 for index $index_id:")
    println("  Recall: $(round(specific_comparison.recall, digits=3))")
    println("  Precision: $(round(specific_comparison.precision, digits=3))")
    println("  F1 Score: $(round(specific_comparison.f1_score, digits=3))")
end

# Print all solutions for a specific index and config
for (config_id, config_data) in solution_store.data[index_id]
    println("Config: ", config_id)
    # println("Configuration: ", config_data["config"])
    for (question, filtered_sources) in config_data["solutions"]
        println("  Question: ", question)
        println("  Filtered sources: ", filtered_sources)
    end
    println()
end
