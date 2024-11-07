using Plots
using StatsPlots
using Statistics
using Measures

function plot_overall_mean_scores(overall_mean_scores, output_dir=".")
    metrics = [:f1_score, :recall, :precision]
    values = [overall_mean_scores[metric] for metric in metrics]
    conf = overall_mean_scores[:ref_config]
    
    p = bar(String.(metrics), values,
        title="Overall Mean Scores\nReference: $conf",
        ylabel="Score",
        legend=false,
        bar_width=0.5,
        fillcolor=:blue,
        linecolor=:black)
    
    for (i, value) in enumerate(values)
        annotate!(p, i, value, text(round(value, digits=3), :bottom, 10))
    end
    
    savefig(p, joinpath(output_dir, "overall_mean_scores.png"))
end

function plot_config_scores(config_overall_scores, output_dir=".")
    comparisons = collect(keys(config_overall_scores))
    @show comparisons
    metrics = Dict(
        :f1_score => "F1 Score",
        :recall => "Recall",
        :precision => "Precision"
    )
    
    # Get reference config directly
    ref_config = config_overall_scores[first(comparisons)][:ref_config]
    ref_name = humanize_config(ref_config)
    
    # Get config names for x-axis labels
    config_names = [humanize_config(scores[:config]) 
                   for (_, scores) in config_overall_scores]
    
    for (metric_key, metric_name) in metrics
        values = [config_overall_scores[comp][metric_key] for comp in comparisons]
        @show values
        
        p = bar(config_names, values,
            title="$metric_name\n$(replace(ref_name, "\n" => " "))",
            ylabel=metric_name,
            legend=false,
            bar_width=0.6,
            rotation=45,
            size=(800, 600))
        
        # Adjusted annotation positioning
        for (j, value) in enumerate(values)
            annotate!(p, j, value + 0.02, # Added small offset
                text(round(value, digits=3), :bottom, 8, "Computer Modern"))
        end
        
        savefig(p, joinpath(output_dir, "$(lowercase(metric_name))_scores.png"))
    end
end

function plot_comparison(mean_scores, metric, output_dir=".")
    # Get unique comparisons and their config names
    all_comparisons = Set()
    config_names = Dict()
    ref_name = nothing
    
    for (_, scores) in mean_scores
        for (comparison, score) in scores
            push!(all_comparisons, comparison)
            config_names[comparison] = humanize_config(score.config)  # Changed from config_name to config
            ref_name = humanize_config(score.ref_config)             # Changed to use ref_config directly
        end
    end
    comparisons = collect(all_comparisons)
    
    n_comparisons = length(comparisons)
    n_indices = length(mean_scores)
    
    data = zeros(n_indices, n_comparisons)
    for (i, (index_id, scores)) in enumerate(mean_scores)
        for (j, comparison) in enumerate(comparisons)
            if haskey(scores, comparison)
                data[i, j] = getproperty(scores[comparison], metric)
            end
        end
    end
    
    config_labels = [config_names[comp] for comp in comparisons]
    
    p = groupedbar(data, 
        bar_position = :dodge,
        bar_width=0.7,
        xticks=(1:n_comparisons, config_labels),
        label=reshape(collect(keys(mean_scores)), 1, :),
        title="Comparison of $metric across Indices\nReference: $ref_name",
        ylabel=string(metric),
        legend=:outertopright,
        rotation=45,)
    
    savefig(p, joinpath(output_dir, "comparison_plot_$(metric).png"))
end

function generate_benchmark_plots(mean_scores, config_overall_scores, overall_mean_scores, output_dir=".")
    mkpath(output_dir)
    
    # plot_overall_mean_scores(overall_mean_scores, output_dir)
    plot_config_scores(config_overall_scores, output_dir)
    
    # for metric in [:f1_score, :recall, :precision]
    #     plot_comparison(mean_scores, metric, output_dir)
    # end
end