using Test

@testset "EasyRAGBench.jl" begin
    include("test_solution_store.jl")
    include("test_evaluate_solutions.jl")
end