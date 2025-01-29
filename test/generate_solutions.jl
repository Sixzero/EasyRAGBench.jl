using EasyRAGStore: RAGStore
using EasyRAGBench: generate_all_solutions

store = RAGStore("workspace_context_log")
generate_all_solutions(store, "all_solutions.jld2")
;
#%%