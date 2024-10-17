using Test
using EasyRAGBench
using EasyRAGStore
using OrderedCollections

@testset "EvaluateSolutions Tests" begin
    @testset "Basic Configuration Pipeline" begin
        # Create a mock RAGStore
        store = RAGStore(joinpath(tempdir(), "test_rag_store"))
        
        # Create a mock index and question
        index = OrderedDict("source1" => "This is a test content", "source2" => "More test content")
        question = (question="What is the test content?", answer="This is a test content and more test content")
        index_id = append!(store, index, question)
        
        # Create a mock configuration
        config = BenchmarkConfig(
            embedding_model = "test-embedding-model",
            top_k = 5,
            batch_size = 10,
            reranker_model = "test-reranker-model",
            top_n = 3
        )
        
        # Run the evaluation
        results = benchmark_pipeline(store, config, joinpath(tempdir(), "test_output.jld2"))
        
        # Test that results are produced
        @test !isempty(results)
        @test haskey(results, index_id)
        @test results[index_id] isa Float64
        
        # Clean up
        rm(store.cache_dir, recursive=true)
    end
    
    @testset "Multiple Configurations" begin
        store = RAGStore(joinpath(tempdir(), "test_rag_store_multi"))
        
        index = OrderedDict("source1" => "Multiple config test", "source2" => "Testing various configs")
        question = (question="What are we testing?", answer="Testing various configurations")
        index_id = append!(store, index, question)
        
        configs = [
            BenchmarkConfig(embedding_model="model1", top_k=5, batch_size=10, reranker_model="reranker1", top_n=3),
            BenchmarkConfig(embedding_model="model2", top_k=10, batch_size=20, reranker_model="reranker2", top_n=5)
        ]
        
        results = run_benchmarks(store, configs, joinpath(tempdir(), "test_multi_output.jld2"))
        
        @test length(results) == length(configs)
        for result in results
            @test result.config isa BenchmarkConfig
            @test result.avg_metrics isa Dict
            @test result.overall_avg isa Float64
        end
        
        # Clean up
        rm(store.cache_dir, recursive=true)
    end
end
