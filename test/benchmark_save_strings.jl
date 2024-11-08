using Test
using JLD2
using OrderedCollections
using BenchmarkTools
using Dates
using Arrow
using DataFrames
using HDF5

function create_test_data(N::Int=1000)
    data = OrderedDict{String,Vector{String}}()
    for i in 1:N
        data["key_$i"] = ["value_$(rand(1:10))" for _ in 1:5]
    end
    return data
end

function create_update_data()
    key = "update_key_$(rand(1:1000))"
    value = ["update_value_$(rand(1:10))" for _ in 1:5]
    return key, value
end

function dict_to_df(data)
    DataFrame(key=collect(keys(data)), value=collect(values(data)))
end

function dict_to_json(data)
    JSON3.write(data)
end

@testset "Solution Save Methods" begin
    for N in [1000, 10_000, 100_000
        ]
        test_data = create_test_data(N)
        update_key, update_value = create_update_data()
        tmp_dir = mktempdir()
        println("\nTesting with N=$N entries")
        local t_full, t_incremental, t_arrow_incremental, t_json_incremental, t_hdf5_incremental
        local t_full_read, t_incr_read, t_arrow_read, t_json_read, t_hdf5_read
        local full_size, incr_size, arrow_size, hdf5_size

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
                read_data = Dict{String,Vector{String}}()
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
                read_data = Dict{String,Vector{String}}()
                jldopen(filename, "r") do file
                    for k in keys(file)
                        read_data[k] = file[k]
                    end
                end
            end
            println("Incremental read time: $t_incr_read seconds")

            # Verify data
            jldopen(filename, "r") do file
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
                update_df = DataFrame(key=[update_key], value=[update_value])
                Arrow.append(filename, update_df)
            end
            arrow_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("Arrow incremental update time (single key): $t_arrow_incremental seconds")
            println("Arrow file size: $(round(arrow_size, digits=2)) MB")

            # Read timing
            t_arrow_read = @elapsed read_dict = begin
                df = Arrow.Table(filename) |> DataFrame
                OrderedDict(k => Vector{String}(v) for (k,v) in zip(df.key, df.value))
            end
            println("Arrow read time: $t_arrow_read seconds")

            # Verify data
            df_verify = Arrow.Table(filename) |> DataFrame
            loaded_dict = OrderedDict(k => Vector{String}(v) for (k,v) in zip(df_verify.key, df_verify.value))
            
            @test length(loaded_dict) == length(test_data) + 1
            @test all(loaded_dict[k] == v for (k,v) in test_data)
            @test loaded_dict[update_key] == update_value
        end


        @testset "HDF5 Update Method" begin
            filename = joinpath(tmp_dir, "hdf5_save_test.h5")
            
            # Initial save of test_data
            h5open(filename, "w") do file
                for (k,v) in test_data
                    file[k] = v
                end
            end
            
            # Update by reading, modifying and writing
            t_hdf5_incremental = @elapsed begin
                h5open(filename, "r+") do file
                    file[update_key] = update_value
                end
            end
            hdf5_size = filesize(filename) / 1024 / 1024  # Size in MB
            println("HDF5 update time: $t_hdf5_incremental seconds")
            println("HDF5 file size: $(round(hdf5_size, digits=2)) MB")

            # Read timing
            t_hdf5_read = @elapsed begin
                read_dict = OrderedDict{String,Vector{String}}()
                h5open(filename, "r") do file
                    for k in keys(file)
                        read_dict[k] = read(file[k])
                    end
                end
            end
            println("HDF5 read time: $t_hdf5_read seconds")

            # Verify data
            loaded_dict = OrderedDict{String,Vector{String}}()
            h5open(filename, "r") do file
                for k in keys(file)
                    loaded_dict[k] = read(file[k])
                end
            end
            
            @test length(loaded_dict) == length(test_data) + 1
            @test all(loaded_dict[k] == v for (k,v) in test_data)
            @test loaded_dict[update_key] == update_value
        end

        println("\nPerformance comparison:")
        println("Append speed:")
        println("  Append / Full JLD2 save: $(round(t_full/t_incremental, digits=2))x")
        println("  Arrow / Full JLD2 save: $(round(t_full/t_arrow_incremental, digits=2))x")
        println("  HDF5 / Full JLD2 save: $(round(t_full/t_hdf5_incremental, digits=2))x")
        println("\nRead speed:")
        println("  Full / Incremental read ratio: $(round(t_full_read/t_incr_read, digits=2))x")
        println("  Arrow / JLD2 read ratio: $(round(t_incr_read/t_arrow_read, digits=2))x")
        println("  HDF5 / JLD2 read ratio: $(round(t_incr_read/t_hdf5_read, digits=2))x")
        println("\nFile sizes:")
        println("  Full JLD2: $(round(full_size, digits=2)) MB")
        println("  Incremental JLD2: $(round(incr_size, digits=2)) MB")
        println("  Arrow: $(round(arrow_size, digits=2)) MB")
        println("  HDF5: $(round(hdf5_size, digits=2)) MB")

        # Print relative file sizes
        println("\nRelative file sizes:")
        println("  HDF5 / JLD2 ratio: $(round(hdf5_size/incr_size, digits=2))x")
        println("  Arrow / JLD2 ratio: $(round(arrow_size/incr_size, digits=2))x")

        # Cleanup
        rm(tmp_dir, recursive=true)
    end
end;
