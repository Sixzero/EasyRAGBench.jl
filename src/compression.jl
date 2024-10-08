using Random

# Abstract type for compression strategies
abstract type CompressionStrategy end
abstract type AbstractChunkFormat end

# Concrete types for different compression strategies
struct NoCompression <: CompressionStrategy end
struct RefChunkCompression <: CompressionStrategy end

# RefChunk to store references to other chunks
struct RefChunk <: AbstractChunkFormat
    collection_id::String
    source::String
end

# Generate an incremental ID
mutable struct IDGenerator
    counter::Int
end

const id_generator = IDGenerator(0)

function generate_id()
    id_generator.counter += 1
    return "CC_$(id_generator.counter)"
end

# Initialize ID generator from existing collections
function initialize_id_generator(collections::Dict{String, Dict{String, Union{String, RefChunk}}})
    if !isempty(collections)
        max_id = maximum(parse(Int, split(id, "_")[2]) for id in keys(collections))
        id_generator.counter = max_id
    end
end

# Generate a large, non-repetitive content
function generate_large_content(size_kb::Int)
    Random.seed!(42)
    chars = ['a':'z'..., 'A':'Z'..., '0':'9'..., ' ', '.', ',', '!', '?', '-', ':', ';', '(', ')', '\n']
    content = String(rand(chars, size_kb * 1024))
    return content
end

# Create collections
function create_collections(source_chunks_list::Vector{Dict{String, String}}, compression::CompressionStrategy)
    collections = Dict{String, Dict{String, Union{String, RefChunk}}}()
    
    for source_chunks in source_chunks_list
        collection_id = generate_id()
        collection = create_collection(source_chunks, compression, collection_id)
        collections[collection_id] = collection
    end
    
    return collections
end

# Create a single collection (dispatch on compression strategy)
function create_collection(source_chunks::Dict{String, String}, ::NoCompression, collection_id::String)
    return Dict(source => chunk for (source, chunk) in source_chunks)
end

function create_collection(source_chunks::Dict{String, String}, ::RefChunkCompression, collection_id::String)
    collection = Dict{String, Union{String, RefChunk}}()
    unique_chunks = Dict{String, Tuple{String, String}}()
    
    for (source, chunk) in source_chunks
        found = false
        for (existing_chunk, (existing_id, existing_source)) in unique_chunks
            if existing_chunk == chunk
                collection[source] = RefChunk(existing_id, existing_source)
                found = true
                break
            end
        end
        
        if !found
            unique_chunks[chunk] = (collection_id, source)
            collection[source] = chunk
        end
    end
    
    return collection
end

# Update collections
function update_collections(collections::Dict{String, Dict{String, Union{String, RefChunk}}}, 
                            source_chunks::Dict{String, String}, compression::CompressionStrategy)
    for (source, chunk) in source_chunks
        collection_id = generate_id()
        
        if compression isa RefChunkCompression
            # Check if this chunk already exists in any collection
            for (existing_id, existing_collection) in collections
                for (existing_source, existing_chunk) in existing_collection
                    if existing_chunk isa String && existing_chunk == chunk
                        # If found, create a RefChunk
                        collections[collection_id] = Dict(source => RefChunk(existing_id, existing_source))
                        return
                    end
                end
            end
        end
        
        # If not found or not using RefChunks, add as a new chunk
        collections[collection_id] = Dict(source => chunk)
    end
end

# Reconstruct data from RefChunk (dispatch on chunk type)
function reconstruct_data(collection::Dict{String, Union{String, RefChunk}}, source::String)
    chunk = collection[source]
    return reconstruct_data(chunk, collection)
end

reconstruct_data(chunk::String, _) = chunk

function reconstruct_data(chunk::RefChunk, collection::Dict{String, Union{String, RefChunk}})
    return reconstruct_data(collection, chunk.source)
end

# Utility functions for generating cache keys
function fast_cache_key(chunks::OrderedDict{String, String})
    fast_cache_key(keys(chunks))
end

function fast_cache_key(keys::AbstractSet)
    if isempty(keys)
        return string(zero(UInt64))  # Return a zero hash for empty input
    end
    
    # Combine hashes of all keys
    combined_hash = reduce(xor, hash(key) for key in keys)
    
    return string(combined_hash, base=16, pad=16)  # Convert to 16-digit hexadecimal string
end

function fast_cache_key(fn::Function, keys)
    if isempty(keys)
        return string(zero(UInt64))  # Return a zero hash for empty input
    end

    # Combine hashes of all keys
    combined_hash = reduce(xor, hash(fn(key)) for key in keys)

    return string(combined_hash, base=16, pad=16)
end
