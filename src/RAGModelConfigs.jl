using Dates
using SHA

abstract type AbstractRAGPipeConfig end

function get_unique_id(config::AbstractRAGPipeConfig)
    config_str = join([getfield(config, field) for field in fieldnames(typeof(config))], "_")
    return bytes2hex(sha256(config_str))[1:16]
end


# Example concrete implementation
@kwdef struct EmbeddingSearchRerankerConfig <: AbstractRAGPipeConfig
    embedding_model::String = "voyage-code-2"
    top_k::Int = 120
    batch_size::Int = 50
    reranker_model::String = "claude"
    top_n::Int = 10
end

struct EmbeddingSearchReranker
    similarity_search::Any
    reranker::Any
    config::EmbeddingSearchRerankerConfig
    index::Any

    function EmbeddingSearchReranker(config::EmbeddingSearchRerankerConfig, ordered_dict)
        embedder = create_voyage_embedder(model=config.embedding_model)
        similarity_search = create_combined_index_builder(embedder; top_k=config.top_k)
        reranker = ReduceRankGPTReranker(
            batch_size=config.batch_size,
            model=config.reranker_model,
            top_n=config.top_n,
        )
        index = get_index(similarity_search, ordered_dict, verbose=false)
        new(similarity_search, reranker, config, index)
    end
end

function (searcher::EmbeddingSearchReranker)(question)
    search_results = searcher.similarity_search(searcher.index, question)
    return searcher.reranker(search_results, question)
end
