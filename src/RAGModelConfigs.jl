using Dates
using SHA
using EasyContext: create_openai_embedder, create_jina_embedder, create_voyage_embedder
using PromptingTools.Experimental.RAGTools: ChunkEmbeddingsIndex, AbstractChunkIndex

abstract type AbstractRAGPipeConfig end

get_unique_hash(config::String) = hash(config)
get_unique_hash(config::Number) = hash(config)
function get_unique_hash(config::AbstractRAGPipeConfig)
    reduce(xor, (get_unique_hash(getfield(config, field)) for field in fieldnames(typeof(config))); init=hash(typeof(config)))
end
function get_unique_id(config::AbstractRAGPipeConfig)
    combined_hash = get_unique_hash(config)
    return string(combined_hash, base=16, pad=16) 
end

@kwdef struct EmbeddingSearchConfig <: AbstractRAGPipeConfig
    embedding_model::String = "text-embedding-3-small"
    top_k::Int = 120
end

@kwdef struct JinaEmbeddingSearchConfig <: AbstractRAGPipeConfig
    embedding_model::String = "jina-embeddings-v2-base-code"
    top_k::Int = 120
end

@kwdef struct VoyageEmbeddingSearchConfig <: AbstractRAGPipeConfig
    embedding_model::String = "voyage-code-2"
    top_k::Int = 120
end

@kwdef struct OpenAIEmbeddingSearchConfig <: AbstractRAGPipeConfig
    embedding_model::String = "text-embedding-3-small"
    top_k::Int = 120
end

@kwdef struct EmbeddingSearchRerankerConfig <: AbstractRAGPipeConfig
    embedding_model::String = "voyage-code-2"
    top_k::Int = 120
    batch_size::Int = 50
    reranker_model::String = "claude"
    top_n::Int = 10
end

humanize_config(m::EmbeddingSearchConfig) = "Emb. $(m.embedding_model)\ntop_k=$(m.top_k)"

humanize_config(m::JinaEmbeddingSearchConfig) = "Emb. $(m.embedding_model)\ntop_k=$(m.top_k)"

humanize_config(m::VoyageEmbeddingSearchConfig) = "Emb. $(m.embedding_model)\ntop_k=$(m.top_k)"

humanize_config(m::OpenAIEmbeddingSearchConfig) = "Emb. $(m.embedding_model)\ntop_k=$(m.top_k)"

humanize_config(m::EmbeddingSearchRerankerConfig) = 
    "Reranker\n$(m.embedding_model) top_k=$(m.top_k)\n$(m.reranker_model) top_n=$(m.top_n)"

function get_filterer(config::EmbeddingSearchConfig, ordered_dict; verbose=false)
    similarity_search = create_combined_index_builder(config.embedding_model; top_k=config.top_k)
    index = get_index(similarity_search, ordered_dict, verbose=verbose)
    return EmbeddingSearch(similarity_search, config, index)
end

function get_filterer(config::JinaEmbeddingSearchConfig, ordered_dict; verbose=false, cache_prefix="")
    similarity_search = create_jina_embedder(model=config.embedding_model, top_k=config.top_k; cache_prefix)
    index = get_index(similarity_search, ordered_dict, verbose=verbose)
    return EmbeddingSearch(similarity_search, config, index)
end

function get_filterer(config::VoyageEmbeddingSearchConfig, ordered_dict; verbose=false)
    similarity_search = create_voyage_embedder(model=config.embedding_model, top_k=config.top_k)
    index = get_index(similarity_search, ordered_dict, verbose=verbose)
    return EmbeddingSearch(similarity_search, config, index)
end

function get_filterer(config::OpenAIEmbeddingSearchConfig, ordered_dict; verbose=false, cache_prefix="")
    similarity_search = create_openai_embedder(model=config.embedding_model, top_k=config.top_k; cache_prefix)
    index = get_index(similarity_search, ordered_dict, verbose=verbose)
    return EmbeddingSearch(similarity_search, config, index)
end

function get_filterer(config::EmbeddingSearchRerankerConfig, ordered_dict; verbose=false)
    return EmbeddingSearchReranker(config, ordered_dict; verbose=verbose)
end

struct EmbeddingSearch{T}
    similarity_search::T
    config::Union{EmbeddingSearchConfig, JinaEmbeddingSearchConfig, VoyageEmbeddingSearchConfig, OpenAIEmbeddingSearchConfig}
    index::Union{Vector{<:AbstractChunkIndex}, AbstractChunkIndex}
end

function (searcher::EmbeddingSearch)(question)
    search_results = searcher.similarity_search(searcher.index, question)
    return search_results
end

struct EmbeddingSearchReranker
    similarity_search::Any
    reranker::Any
    config::EmbeddingSearchRerankerConfig
    index::Union{Vector{<:AbstractChunkIndex}, AbstractChunkIndex}

    function EmbeddingSearchReranker(config::EmbeddingSearchRerankerConfig, ordered_dict; verbose=false)
        embedder = create_voyage_embedder(; model=config.embedding_model, verbose=verbose)
        similarity_search = create_combined_index_builder(embedder; top_k=config.top_k)
        reranker = ReduceRankGPTReranker(;
            batch_size=config.batch_size,
            model=config.reranker_model,
            top_n=config.top_n,
            verbose=1,
        )
        index = get_index(similarity_search, ordered_dict, verbose=false)
        new(similarity_search, reranker, config, index)
    end
end

function (searcher::EmbeddingSearchReranker)(question)
    search_results = searcher.similarity_search(searcher.index, question)
    return searcher.reranker(search_results, question)
end


