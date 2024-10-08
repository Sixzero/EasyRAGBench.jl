
# Note: The DatasetStore is designed to efficiently store multiple indices in a single file.
# This approach allows for significant compression due to repetitions across indices.
# The `indexes` field is a Dict of Dicts, where each inner Dict represents an index.
# This structure enables efficient storage and retrieval of multiple related indices.

"""
    DatasetStore

A struct to store collections of indices and their compression strategy.

# Fields
- `indexes::Dict{String, OrderedDict{String, Union{String, AbstractChunkFormat}}}`: A dictionary of indices, where each index is an OrderedDict mapping sources to chunks.
- `compression::CompressionStrategy`: The compression strategy used for storing chunks.
- `cache_dir::String`: The directory where cache files are stored.
"""
@kwdef struct DatasetStore
    indexes::Dict{String, OrderedDict{String, Union{String, AbstractChunkFormat}}} = Dict()
    compression::CompressionStrategy = RefChunkCompression()
    cache_dir::String = joinpath(dirname(@__DIR__), "benchmark_data")
end

"""
    append!(store::DatasetStore, index::OrderedDict{String, String})

Append a new index to the DatasetStore.

# Arguments
- `store::DatasetStore`: The DatasetStore object to update.
- `index::OrderedDict{String, String}`: New index to add, where keys are sources and values are chunks.

# Returns
- `String`: The ID of the newly added index.
"""
function Base.append!(store::DatasetStore, index::OrderedDict{String, String})
    index_id = fast_cache_key(index)
    compressed_index = create_collection(index, store.compression, index_id)
    store.indexes[index_id] = compressed_index
    
    save_dataset_store(joinpath(store.cache_dir, "dataset_store.jld2"), store)
    
    return index_id
end

"""
    get_index(store::DatasetStore, index_id::String)

Retrieve an index from the DatasetStore.

# Arguments
- `store::DatasetStore`: The DatasetStore object to query.
- `index_id::String`: The ID of the index to retrieve.

# Returns
- `OrderedDict{String, String}`: The retrieved index with decompressed chunks.
"""
function get_index(store::DatasetStore, index_id::String)
    if haskey(store.indexes, index_id)
        return OrderedDict(source => reconstruct_data(chunk, store.indexes[index_id]) 
                           for (source, chunk) in store.indexes[index_id])
    else
        throw(KeyError("Index $index_id not found in the store"))
    end
end

"""
    save_dataset_store(filename::String, store::DatasetStore)

Save a DatasetStore object to a JLD2 file.

# Arguments
- `filename::String`: The name of the file to save the store to.
- `store::DatasetStore`: The DatasetStore object to save.
"""
function save_dataset_store(filename::String, store::DatasetStore)
    jldsave(filename; indexes=store.indexes, compression=store.compression)
end

"""
    load_dataset_store(filename::String) -> DatasetStore

Load a DatasetStore object from a JLD2 file.

# Arguments
- `filename::String`: The name of the file to load the store from.

# Returns
- `DatasetStore`: The loaded DatasetStore object.
"""
function load_dataset_store(filename::String)
    data = load(filename)
    return DatasetStore(
        indexes = data["indexes"],
        compression = data["compression"],
        cache_dir = dirname(filename)
    )
end