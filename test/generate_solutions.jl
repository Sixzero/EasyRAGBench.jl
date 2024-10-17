using EasyRAGStore: RAGStore
using EasyRAGBench: generate_all_solutions

store = RAGStore("workspace_context_log")
generate_all_solutions(store, "all_solutions.jld2")
;
#%%
using EasyRAGStore: get_index
store
dstore = store.dataset_store
# k = collect(keys(dstore.indexes))[1]
k = collect(keys(dstore.indexes))[2]
get_index(dstore,k)