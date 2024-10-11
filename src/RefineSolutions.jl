
function check_and_modify_solution(solution::Vector{String}, question::String)
  check_prompt = """
  Given the following question and solution chunks, determine if the solution is satisfactory or needs modification:
  
  Question: $question
  
  Solution chunks:
  $(join(solution, "\n\n"))
  
  Is this solution satisfactory? If not, what modifications are needed?
  """
  
  check_result = aigenerate(check_prompt; model="gpt4o")
  
  if occursin("satisfactory", lowercase(check_result.content))
      return solution
  else
      improve_prompt = """
      The current solution for the following question needs improvement:
      
      Question: $question
      
      Current solution chunks:
      $(join(solution, "\n\n"))
      
      Please provide an improved set of solution chunks that better answer the question.
      """
      
      improved_result = aigenerate(improve_prompt; model="gpt-4-1106-preview")
      
      improved_chunks = split(improved_result.content, "\n\n")
      
      return improved_chunks
  end
end