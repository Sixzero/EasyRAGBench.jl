
function print_solution_store_results(solution_store::SolutionStore)
  if haskey(solution_store.data, "benchmarks")
      for (unique_id, benchmark) in solution_store.data["benchmarks"]
          println("Benchmark $unique_id:")
          println("  Config: $(benchmark.config)")
          print_overall_results(benchmark.overall_avg)
          println()
      end
  else
      println("No benchmark results found in the solution store.")
  end
end

function print_question_results(relevance_scores, index, total_indices, q_idx, total_questions)
  println("Index $index/$total_indices, Question $q_idx/$total_questions")
  println("  Recall: $(round(relevance_scores.recall, digits=3))")
  println("  Precision: $(round(relevance_scores.precision, digits=3))")
  println("  F1 Score: $(round(relevance_scores.f1_score, digits=3))")
end

function print_running_averages(current_index_metrics)
  avg_recall = mean(m.recall for m in current_index_metrics)
  avg_precision = mean(m.precision for m in current_index_metrics)
  avg_f1 = mean(m.f1_score for m in current_index_metrics)
  println("  Running averages for current index:")
  println("    Avg Recall: $(round(avg_recall, digits=3))")
  println("    Avg Precision: $(round(avg_precision, digits=3))")
  println("    Avg F1 Score: $(round(avg_f1, digits=3))")
  println()  # Add a blank line for better readability
end

function print_overall_results(overall_avg)
  @info "Benchmark complete. Overall average scores:" *
        "\n  Recall: $(round(overall_avg.recall, digits=3))" *
        "\n  Precision: $(round(overall_avg.precision, digits=3))" *
        "\n  F1 Score: $(round(overall_avg.f1_score, digits=3))" *
        "\n  True Positives: $(overall_avg.true_positives)" *
        "\n  False Positives: $(overall_avg.false_positives)" *
        "\n  False Negatives: $(overall_avg.false_negatives)"
end
