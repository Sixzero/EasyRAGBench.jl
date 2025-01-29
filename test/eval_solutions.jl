using EasyRAGBench: run_generation, run_benchmark_comparison
using EasyRAGStore: RAGStore
using EasyContext: TwoLayerRAG, TopK, ReduceGPTReranker, create_jina_embedder, create_voyage_embedder, create_openai_embedder, BM25Embedder

# Define configurations to test
configs = [
    # Single embedder configs without reranker

    TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=40),
    TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=10),
    TopK([create_jina_embedder(model="jina-embeddings-v3")], top_k=40),
    TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=40),
    TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=10),
    TopK([create_voyage_embedder(model="voyage-3")], top_k=40),
    TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    TopK([create_voyage_embedder(model="voyage-code-2")], top_k=10),
    
    # TwoLayerRAG configs with reranker - Voyage embedder variations
    TwoLayerRAG(
        topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
        reranker=ReduceGPTReranker(batch_size=60, top_n=10, model="gem20f", strict=true)
    ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=60, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="orgf", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=60, top_n=10, model="claudeh", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="claudeh", strict=true)
    # ),
    TopK([BM25Embedder()], top_k=40),
    TopK([BM25Embedder()], top_k=10),
    
    
    # TwoLayerRAG configs with other embedders
    # TwoLayerRAG(
    #     topK=TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v3")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-3")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # # TwoLayerRAG configs with BM25 and reranker
    # TwoLayerRAG(
    #     topK=TopK([create_openai_embedder(model="text-embedding-3-small"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v3"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v2-base-code"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-3"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om", strict=true)
    # )
]

# Define RAG dataset name and solution file
rag_dataset_name = "workspace_chunks"
solution_file = "all_sols4.jld2"

 ## %% 1. Generate solutions for all configurations
@time solution_store = run_generation(rag_dataset_name, solution_file, configs);

#%% 2. Run benchmark comparison against the first config as reference
using EasyContext: humanize
import EasyRAGBench
reference_config = humanize(configs[1])
results = run_benchmark_comparison(solution_file, reference_config, "benchmark_results")
;
