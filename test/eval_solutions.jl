using EasyRAGBench: run_generation, run_benchmark_comparison
using EasyRAGStore: RAGStore
using EasyContext: TwoLayerRAG, TopK, ReduceGPTReranker, create_jina_embedder, create_voyage_embedder, create_openai_embedder, BM25Embedder
using EasyContext: rerank_prompt_v4

# Define configurations to test
configs = [
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="claude"),
    # ),
    TwoLayerRAG(
        topK=TopK([create_voyage_embedder()], top_k=120),
        reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="o3m")
    ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="minimax")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(), BM25Embedder()], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="minimax")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="minimax", rank_gpt_prompt_fn=rerank_prompt_v4)
    # ),
    TwoLayerRAG(
        topK=TopK([create_voyage_embedder()], top_k=50),
        reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="gpt4om", rank_gpt_prompt_fn=rerank_prompt_v4)
    ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="dscode", rank_gpt_prompt_fn=rerank_prompt_v4)
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="gem20f", rank_gpt_prompt_fn=rerank_prompt_v4),
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder()], top_k=90),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="gem20f"),
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="dscode"),
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=50),
    #     reranker=ReduceGPTReranker(batch_size=30, top_n=10, model="claude"),
    # ),
    # Single embedder configs without reranker


    # TwoLayerRAG configs with reranker - Voyage embedder variations
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=60, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="orgf")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=120),
    #     reranker=ReduceGPTReranker(batch_size=60, top_n=10, model="claudeh")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="claudeh")
    # ),

    
    # TwoLayerRAG configs with other embedders
    # TwoLayerRAG(
    #     topK=TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v3")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-3")], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # # TwoLayerRAG configs with BM25 and reranker
    # TwoLayerRAG(
    #     topK=TopK([create_openai_embedder(model="text-embedding-3-small"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v3"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_jina_embedder(model="jina-embeddings-v2-base-code"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-3"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # ),
    # TwoLayerRAG(
    #     topK=TopK([create_voyage_embedder(model="voyage-code-2"), BM25Embedder()], top_k=40),
    #     reranker=ReduceGPTReranker(batch_size=50, top_n=10, model="gpt4om")
    # )
]
embedder_configs = [
    # TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=40),
    # TopK([create_openai_embedder(model="text-embedding-3-small")], top_k=10),
    # TopK([create_jina_embedder(model="jina-embeddings-v3")], top_k=40),
    # TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=40),
    # TopK([create_jina_embedder(model="jina-embeddings-v2-base-code")], top_k=10),

    TopK([create_voyage_embedder(model="voyage-3")], top_k=40),
    TopK([create_voyage_embedder(model="voyage-code-2")], top_k=40),
    TopK([create_voyage_embedder(model="voyage-code-2")], top_k=10),
    TopK([BM25Embedder()], top_k=40),
    TopK([BM25Embedder()], top_k=10),
]
# Define RAG dataset name and solution file
rag_dataset_name = "workspace_chunks"
solution_file = "all_solutions.jld2"

 ## %% 1. Generate solutions for all configurations
@time solution_store = run_generation(rag_dataset_name, solution_file, configs);

#%% 2. Run benchmark comparison against the first config as reference
using EasyContext: humanize
import EasyRAGBench
reference_config = humanize(configs[1])
@show reference_config

results = run_benchmark_comparison(solution_file, reference_config, "benchmark_results")
;
