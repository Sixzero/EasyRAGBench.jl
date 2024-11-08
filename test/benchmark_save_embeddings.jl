using Test
using JLD2
using OrderedCollections
using BenchmarkTools
using Dates
using Arrow
using DataFrames
using JSON3

function create_test_embeddings(N::Int=1000)
    data = OrderedDict{String,Vector{Float32}}()
    for i in 1:N
        data["key_$i"] = rand(Float32, 768)  # 768-dim embedding vector
    end
    return data
end

function create_update_embedding()
    key = "update_key_$(rand(1:1000))"
    value = rand(Float32, 768)
    return key, value
end

function dict_to_df(data)
    DataFrame(key=collect(keys(data)), embedding=collect(values(data)))
end

function dict_to_json(data)
    # Convert Float32 to Float64 as JSON3 doesn't directly support Float32
    json_dict = Dict(k => Array{Float64}(v) for (k,v) in data)
    JSON3.write(json_dict)
end

@testset "Embedding Save Methods" begin
    for N in [10_000, 10_000
        ]
        test_data = create_test_embeddings(N)
        update_key, update_value = create_update_embedding()
        tmp_dir = mktempdir()
        println("\nTesting with N=$N embeddings")
        local t_full, t_incremental, t_arrow_incremental, t_group_incremental
        local t_full_read, t_incr_read, t_arrow_read, t_group_read
        local full_size, incr_size, arrow_size, group_size

        @testset "Full Save Method with Update (No compression)" begin
            filename = joinpath(tmp_dir, "full_save_test.jld2")
            
            # Initial save
            jldopen(filename, "w", compress=false) do file
                for (k,v) in test_data
                    file[k] = v
                end
            end
            
            # Update with new key-value by full save
            t_full = @elapsed begin
                jldopen(filename, "w", compress=false) do file
                    for (k,v) in test_data
                        file[k] = v
                    end
                    file[update_key] = update_value
                end
            end
            full_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("Full save time (with update): $t_full seconds")
            println("Full save file size: $(round(full_size, digits=2)) MB")

            # Read timing
            t_full_read = @elapsed begin
                read_data = Dict{String,Vector{Float32}}()
                jldopen(filename, "r") do file
                    for k in keys(file)
                        read_data[k] = file[k]
                    end
                end
            end
            println("Full read time: $t_full_read seconds")

            # Verify data
            jldopen(filename, "r") do file
                for (k,v) in test_data
                    @test file[k] == v
                end
                @test file[update_key] == update_value
            end
        end

        @testset "Incremental Update Method (No compression)" begin
            filename = joinpath(tmp_dir, "incremental_save_test.jld2")
            
            # Initial save of test_data
            jldopen(filename, "w", compress=false) do file
                for (k,v) in test_data
                    file[k] = v
                end
            end
            
            # Update single key-value using append mode
            t_incremental = @elapsed begin
                jldopen(filename, "a+", compress=false) do file
                    file[update_key] = update_value
                end
            end
            incr_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("Incremental update time (single key): $t_incremental seconds")
            println("Incremental save file size: $(round(incr_size, digits=2)) MB")

            # Read timing
            t_incr_read = @elapsed begin
                read_data = Dict{String,Vector{Float32}}()
                jldopen(filename, "r") do file
                    for k in keys(file)
                        read_data[k] = file[k]
                    end
                end
            end
            println("Incremental read time: $t_incr_read seconds")

            # Verify data
            @time jldopen(filename, "r") do file
                for (k,v) in test_data
                    @test file[k] == v
                end
                @test file[update_key] == update_value
                @test length(keys(file)) == length(test_data) + 1
            end
        end

        @testset "Arrow Incremental Update Method" begin
            filename = joinpath(tmp_dir, "arrow_incremental_save_test.arrow")
            
            # Initial save of test_data as DataFrame
            df = dict_to_df(test_data)
            Arrow.append(filename, df)  # First append creates the file
            
            # Update by appending new row
            t_arrow_incremental = @elapsed begin
                update_df = DataFrame(key=[update_key], embedding=[update_value])
                Arrow.append(filename, update_df)
            end
            arrow_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("Arrow incremental update time (single key): $t_arrow_incremental seconds")
            println("Arrow file size: $(round(arrow_size, digits=2)) MB")

            # Read timing
            t_arrow_read = @elapsed res = begin
                df = Arrow.Table(filename) |> DataFrame
                # read_dict = OrderedDict(zip(df.key, df.embedding))
                OrderedDict(k => Vector{Float32}(v) for (k,v) in zip(df.key, df.embedding))
            end

            println("Arrow read time: $t_arrow_read seconds")

            # Verify data
            df_verify = Arrow.Table(filename) |> DataFrame
            loaded_dict = OrderedDict(zip(df_verify.key, df_verify.embedding))
            
            @test length(loaded_dict) == length(test_data) + 1
            @test all(loaded_dict[k] == v for (k,v) in test_data)
            @test loaded_dict[update_key] == update_value
        end

        @testset "Incremental Update Method with Groups" begin
            filename = joinpath(tmp_dir, "group_save_test.jld2")
            
            # Initial save using groups
            jldopen(filename, "w+", compress=false) do file
                JLD2.Group(file, "embeddings")
                emb_group = file["embeddings"]
                for (k,v) in test_data
                    emb_group[k] = v
                end
            end
            
            # Update single key-value using group
            t_group_incremental = @elapsed begin
                jldopen(filename, "a+", compress=false) do file
                    file["embeddings"][update_key] = update_value
                end
            end
            group_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("Group update time (single key): $t_group_incremental seconds")
            println("Group save file size: $(round(group_size, digits=2)) MB")

            # Read timing with groups
            t_group_read = @elapsed begin
                read_data = Dict{String,Vector{Float32}}()
                jldopen(filename, "r") do file
                    emb_group = file["embeddings"]
                    for k in keys(emb_group)
                        read_data[k] = emb_group[k]
                    end
                end
            end
            println("Group read time: $t_group_read seconds")

            # Verify data through groups
            @time jldopen(filename, "r") do file
                emb_group = file["embeddings"]
                for (k,v) in test_data
                    @test emb_group[k] == v
                end
                @test emb_group[update_key] == update_value
                @test length(keys(emb_group)) == length(test_data) + 1
            end
            
            # Test consecutive updates performance
            update_times = Float64[]
            for i in 1:10
                test_key = "consecutive_update_$i"
                test_value = rand(Float32, 768)
                
                t = @elapsed jldopen(filename, "a+", compress=false) do file
                    file["embeddings"][test_key] = test_value
                end
                push!(update_times, t)
            end
            println("\nConsecutive group updates performance:")
            println("  Mean update time: $(round(mean(update_times), digits=6)) seconds")
            println("  Min/Max update time: $(round(minimum(update_times), digits=6))/$(round(maximum(update_times), digits=6)) seconds")
        end


        println("\nPerformance comparison:")
        println("Append speed:")
        println("  Full save / Incremental ratio: $(round(t_full/t_incremental, digits=2))x")
        println("  Arrow / JLD2 Incremental ratio: $(round(t_incremental/t_arrow_incremental, digits=2))x")
        println("  Group / JLD2 Incremental ratio: $(round(t_incremental/t_group_incremental, digits=2))x")
        println("  Arrow / Group ratio: $(round(t_group_incremental/t_arrow_incremental, digits=2))x")
        println("\nRead speed:")
        println("  Full / Incremental read ratio: $(round(t_full_read/t_incr_read, digits=2))x")
        println("  Arrow / JLD2 read ratio: $(round(t_incr_read/t_arrow_read, digits=2))x")
        println("  Group / JLD2 read ratio: $(round(t_incr_read/t_group_read, digits=2))x")
        println("  Arrow / Group read ratio: $(round(t_group_read/t_arrow_read, digits=2))x")
        println("\nFile sizes:")
        println("  Full JLD2: $(round(full_size, digits=2)) MB")
        println("  Incremental JLD2: $(round(incr_size, digits=2)) MB")
        println("  Arrow: $(round(arrow_size, digits=2)) MB")
        println("  Group JLD2: $(round(group_size, digits=2)) MB")

        # Print relative file sizes
        println("\nRelative file sizes:")
        println("  Arrow / JLD2 ratio: $(round(arrow_size/incr_size, digits=2))x")
        println("  Group / JLD2 ratio: $(round(group_size/incr_size, digits=2))x")
        println("  Arrow / Group ratio: $(round(arrow_size/group_size, digits=2))x")

        
        # Cleanup
        rm(tmp_dir, recursive=true)
    end
end

;