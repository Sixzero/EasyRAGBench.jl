using EasyRAGBench: run_generation, run_benchmark_comparison
using EasyRAGStore: RAGStore
using EasyRAGBench: EmbeddingSearchConfig, JinaEmbeddingSearchConfig, VoyageEmbeddingSearchConfig, OpenAIEmbeddingSearchConfig, EmbeddingSearchRerankerConfig

# Define configurations to test
configs = [
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=120, batch_size=60, reranker_model="claude", top_n=10),
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=120, batch_size=60, reranker_model="gpt4om", top_n=10),
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=120, batch_size=50, reranker_model="gpt4om", top_n=10),
    EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=40, batch_size=50, reranker_model="gpt4om", top_n=10),
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=40, batch_size=50, reranker_model="orgf", top_n=10),
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=120, batch_size=60, reranker_model="claudeh", top_n=10),
    # EmbeddingSearchRerankerConfig(embedding_model="voyage-code-2", top_k=40, batch_size=50, reranker_model="claudeh", top_n=10),
    # EmbeddingSearchConfig(embedding_model="text-embedding-3-small", top_k=40),
    # EmbeddingSearchConfig(embedding_model="text-embedding-3-small", top_k=10),
    JinaEmbeddingSearchConfig(embedding_model="jina-embeddings-v3", top_k=40),
    JinaEmbeddingSearchConfig(embedding_model="jina-embeddings-v2-base-code", top_k=40),
    JinaEmbeddingSearchConfig(embedding_model="jina-embeddings-v2-base-code", top_k=10),
    VoyageEmbeddingSearchConfig(embedding_model="voyage-3", top_k=40),
    VoyageEmbeddingSearchConfig(embedding_model="voyage-code-2", top_k=40),
    VoyageEmbeddingSearchConfig(embedding_model="voyage-code-2", top_k=10),
    OpenAIEmbeddingSearchConfig(embedding_model="text-embedding-3-small", top_k=40),
    OpenAIEmbeddingSearchConfig(embedding_model="text-embedding-3-small", top_k=10),
]

# Define RAG dataset name and solution file
rag_dataset_name = "workspace_context_log"
solution_file = "all_sols2.jld2"

 ## %% 1. Generate solutions for all configurations
@time solution_store = run_generation(rag_dataset_name, solution_file, configs);

#%% 2. Run benchmark comparison against the first config as reference
import EasyRAGBench
reference_config = EasyRAGBench.get_unique_id(configs[1])
results = run_benchmark_comparison(solution_file, reference_config, "benchmark_results")
;
#%% 3. Print overall scores

