using HTTP
using JSON3
using EasyRAGBench
using EasyRAGStore
using OrderedCollections

function start_server(port=9000)
    router = HTTP.Router()
    
    # Enable CORS for development
    function cors_headers(req, resp)
        resp.headers["Access-Control-Allow-Origin"] = "*"
        resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        resp.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return resp
    end
    
    # Handle OPTIONS requests for CORS preflight
    HTTP.register!(router, "OPTIONS", "*", req -> HTTP.Response(200, cors_headers(req, HTTP.Response())))
    
    # API endpoint to get available datasets
    HTTP.register!(router, "GET", "/api/datasets", function(req)
        try
            rag_store = RAGStore("rag_dataset")
            datasets = collect(keys(rag_store.dataset_store.chunks))
            resp = HTTP.Response(200, JSON3.write(datasets))
            return cors_headers(req, resp)
        catch e
            resp = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
            return cors_headers(req, resp)
        end
    end)
    
    # API endpoint to get documents from a dataset
    HTTP.register!(router, "GET", "/api/datasets/:id", function(req)
        try
            dataset_id = HTTP.URIs.splitpath(req.target)[3]
            rag_store = RAGStore("rag_dataset")
            chunks = EasyRAGStore.get_index(rag_store, dataset_id)
            
            # Convert chunks to a format suitable for JSON
            result = [Dict(
                "id" => i,
                "text" => chunk.text,
                "source" => string(get_source(chunk))
            ) for (i, chunk) in enumerate(chunks)]
            
            resp = HTTP.Response(200, JSON3.write(result))
            return cors_headers(req, resp)
        catch e
            resp = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
            return cors_headers(req, resp)
        end
    end)
    
    # API endpoint to get questions for a dataset
    HTTP.register!(router, "GET", "/api/questions/:id", function(req)
        try
            dataset_id = HTTP.URIs.splitpath(req.target)[3]
            rag_store = RAGStore("rag_dataset")
            questions = get_questions(rag_store, dataset_id)
            
            # Convert questions to a format suitable for JSON
            result = [Dict(
                "id" => i,
                "question" => q.question
            ) for (i, q) in enumerate(questions)]
            
            resp = HTTP.Response(200, JSON3.write(result))
            return cors_headers(req, resp)
        catch e
            resp = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
            return cors_headers(req, resp)
        end
    end)
    
    # API endpoint to get solutions for a dataset
    HTTP.register!(router, "GET", "/api/solutions/:index_id/:config_id", function(req)
        try
            path_parts = HTTP.URIs.splitpath(req.target)
            index_id = path_parts[3]
            config_id = path_parts[4]
            
            solution_store = SolutionStore("solutions.jld2")
            solutions = get_solutions(solution_store, index_id, config_id)
            
            resp = HTTP.Response(200, JSON3.write(solutions))
            return cors_headers(req, resp)
        catch e
            resp = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
            return cors_headers(req, resp)
        end
    end)
    
    # API endpoint to get all configs for a dataset
    HTTP.register!(router, "GET", "/api/configs/:index_id", function(req)
        try
            index_id = HTTP.URIs.splitpath(req.target)[3]
            
            solution_store = SolutionStore("solutions.jld2")
            all_solutions = get_all_solutions(solution_store, index_id)
            
            # Just return the config IDs
            configs = collect(keys(all_solutions))
            
            resp = HTTP.Response(200, JSON3.write(configs))
            return cors_headers(req, resp)
        catch e
            resp = HTTP.Response(500, JSON3.write(Dict("error" => string(e))))
            return cors_headers(req, resp)
        end
    end)
    
    # Start the server
    @info "Starting server on port $port"
    HTTP.serve(router, "0.0.0.0", port)
end

# Run the server if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    start_server()
end