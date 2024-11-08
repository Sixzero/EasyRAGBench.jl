using Test
using EasyRAGBench: SolutionStore, load_solutions, get_config, get_solution, get_all_solutions, get_solutions, add_solutions!
using OrderedCollections
using Base.Threads: ReentrantLock

# Example struct for testing
@kwdef struct TestConfig
    value::String
end

@testset "SolutionStore" begin
    @testset "Basic Operations" begin
        # Create temp test file
        test_file = "test_solutions.arrow"
        # Cleanup any leftover files first
        rm(joinpath(dirname(dirname(@__FILE__)), "solution", test_file), force=true)
        
        store = SolutionStore(test_file)
        
        # Test initial state
        @test isfile(store.filename)
        @test store.lock isa ReentrantLock
        @test size(store.df, 1) == 0  # Empty DataFrame initially
        
        # Test adding solutions
        index_id = "test_index"
        config_id = "test_config"
        solutions = OrderedDict("test_question" => ["source1", "source2"])
        test_config = TestConfig(value="test_config_data")
        metadata = Dict("config" => test_config)
        
        add_solutions!(store, index_id, config_id, solutions, metadata)
        
        # Verify the data was added correctly
        @test !isempty(store.df)
        @test size(store.df, 1) == 1
        @test store.df[1, :index_id] == index_id
        @test store.df[1, :config_id] == config_id
        @test store.df[1, :filtered_sources] == ["source1", "source2"]
        
        # Test retrieving solutions
        retrieved_solutions = get_solutions(store, index_id, config_id)
        @test retrieved_solutions == solutions
        
        # Test get_solution for specific question
        solution = get_solution(store, index_id, config_id, "test_question")
        @test solution == ["source1", "source2"]
        
        # Test get_config
        config = get_config(store, index_id, config_id)
        @test config isa TestConfig
        @test config.value == "test_config_data"
        
        # Test get_all_solutions
        all_solutions = get_all_solutions(store, index_id)
        @test haskey(all_solutions, config_id)
        @test all_solutions[config_id] == solutions
        
        # Cleanup
        rm(joinpath(dirname(dirname(@__FILE__)), "solution", test_file), force=true)
    end
    
    @testset "Multiple Configs and Indices" begin
        test_file = "test_multi_solutions.arrow"
        store = SolutionStore(test_file)
        
        # Add multiple configurations and indices
        for i in 1:2
            index_id = "index_$i"
            for j in 1:2
                config_id = "config_$j"
                solutions = OrderedDict("question_$j" => ["source$(j)_1", "source$(j)_2"])
                test_config = TestConfig(value="config_$(j)_data")
                metadata = Dict("config" => test_config)
                add_solutions!(store, index_id, config_id, solutions, metadata)
            end
        end
        
        # Test structure using DataFrame
        for i in 1:2
            index_id = "index_$i"
            index_rows = @view store.df[store.df.index_id .== index_id, :]
            @test length(unique(index_rows.config_id)) == 2  # Two configs per index
            
            # Test retrieving from different configs
            solutions = get_all_solutions(store, index_id)
            @test length(solutions) == 2
            for j in 1:2
                config_id = "config_$j"
                @test haskey(solutions, config_id)
                @test solutions[config_id]["question_$j"] == ["source$(j)_1", "source$(j)_2"]
            end
        end
        
        # Cleanup
        rm(joinpath(dirname(dirname(@__FILE__)), "solution", test_file), force=true)
    end
    
    @testset "Error Cases" begin
        test_file = "test_error_solutions.arrow"
        store = SolutionStore(test_file)
        
        # Test non-existent index
        @test isempty(get_solutions(store, "nonexistent_index", "config"))
        @test isempty(get_all_solutions(store, "nonexistent_index"))
        @test isnothing(get_config(store, "nonexistent_index", "config"))
        @test isnothing(get_solution(store, "nonexistent_index", "config", "question"))
        
        # Cleanup
        rm(joinpath(dirname(dirname(@__FILE__)), "solution", test_file), force=true)
    end
end
;