export genfig_sim_bowls_density_and_frequency_bowls_simple,  # Figure 7A
       genfig_sim_bowls_density_and_frequency_bowls_simple_extended,
       genfig_sim_bowls_frequency_summary,                   # Figure 7B
       genfig_sim_bowls_roving_summary,
       genfig_sim_bowls_modelbehavior_scatterplots           # Figure 7C


"""
    genfig_sim_bowls_density_and_frequency_bowls_simple()

Generate figure "executive summary" figure of behavior vs model performance

Depicts behavioral thresholds in both fixed-level and roved-level conditions in each 
target-frequency and component-count condition by plotting all of the bowls on one axis, 
simply separated horizontally in order of target frequency. Different observer strategies
are faceted into different columns, while different model stages are faceted into different 
rows. Model thresholds are plotted in red alongside behavioral data. This is the top half of
Figure 7. 
"""
function genfig_sim_bowls_density_and_frequency_bowls_simple(grouper=grouper_threeway; color=:black, fontsize=10.0)
    # Get full dataframe of simulated thresholds
    df = @chain load_simulated_thresholds_adjusted() begin  
    end

    # Fetch relevant behavioral data and average across listeners/repeats
    beh = @chain grouper(fetch_behavioral_data()) begin
        @subset(:hl_group .== "Normal hearing", :include .== true)
        avg_behavioral_data()
    end

    # Set up figure (3x2 design)
    set_theme!(theme_carney; fontsize=13.0)
    fig = Figure(; resolution=(650, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of observer ("mode") and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1, 3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset simulated data according to observer and model
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Plot each bowl in order of target frequency
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Subset sims to current target frequency and fixed level, then further divide into adj and non-adj
            sims = @subset(df_subset, :center_freq .== freq)
            sims_fixed_raw = @subset(sims, :rove_size .== 0.001, :adjusted .== false)
            sims_fixed_adj = @subset(sims, :rove_size .== 0.001, :adjusted .== true)

            # Subset beh to current target frequency and fixed-level
            beh_fixed = @subset(beh, :freq .== freq, :rove .== "fixed level")

            # Plot bowls with scatters and lines, using solid + circles for fixed-level and 
            # dashed + squares for roved-level
            lines!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=color_group("Normal hearing"))
            scatter!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=color_group("Normal hearing"))
            lines!(ax, (1:5) .+ (idx-1)*7, sims_fixed_raw.θ; color=color)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_fixed_raw.θ; color=color)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_fixed_adj.θ; color=color, linestyle=:dash)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_fixed_adj.θ; color=color, marker=:utriangle)

            # Add text to indicate RMS error
            if (model == "InferiorColliculusSFIEBS")
                pos = (15.0, -27.0)
            else
                pos = (2.0, 5.0)
            end
            text!(ax, [pos[1]], [pos[2]]; text="RMSE = $(round(unique(sims_fixed_raw.rms)[1]; digits=1)) dB", fontsize=fontsize)
            text!(ax, [pos[1]], [pos[2] - 5.0]; text="RMSE adj. = $(round(unique(sims_fixed_adj.rms)[1]; digits=1)) dB", fontsize=fontsize)
        end

        # Manually set x-axis ticks and labels
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*7 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Adjust y-axis limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
    end
    
    # Add superlabels to x/y-axes
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2, fontsize=15.0); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Number of components // Target frequency (Hz)"; fontsize=15.0); rowgap!(fig.layout, 3, Relative(0.05));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.01))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

"""
    genfig_sim_bowls_density_and_frequency_bowls_simple_extended()

Generate figure "executive summary" figure of behavior vs model performance for extended midbrain models

Depicts behavioral thresholds in both fixed-level and roved-level conditions in each 
target-frequency and component-count condition by plotting all of the bowls on one axis, 
simply separated horizontally in order of target frequency. Different observer strategies
are faceted into different columns, while different model stages are faceted into different 
rows. Model thresholds are plotted in red alongside behavioral data. This is the top half of
Figure 7. 
"""
function genfig_sim_bowls_density_and_frequency_bowls_simple_extended()
    # Get full dataframe of simulated thresholds
    df = @chain load_simulated_thresholds_extended() begin  
    end

    # Fetch relevant behavioral data and average across listeners/repeats
    beh = @chain fetch_behavioral_data() begin
        @subset(:hl .< 5.0, :include .== true) 
        # Group by freq, component count, and group
        groupby([:freq, :n_comp, :rove])

        # Summarize
        @combine(
            :stderr = std(:threshold)/sqrt(length(:threshold)),
            :threshold = mean(:threshold),
        )

    end

    # Set up figure (3x2 design)
    set_theme!(theme_carney)
    fig = Figure(; resolution=(350, 450))
    axs = [Axis(fig[i, j]; xticklabelrotation=π/2, xminorticksvisible=false) for i in 1:3, j in 1:1]

    # Loop over all combinations of observer ("mode") and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset simulated data according to observer and model
        df_subset = @subset(df, :model .== model, :mode .== mode)

        # Plot each bowl in order of target frequency
        map(enumerate([500.0, 1000.0, 2000.0, 4000.0])) do (idx, freq)
            # Exclude adjusted simulatd thresholds, subset to current target frequency
            sims = @subset(df_subset, :center_freq .== freq)

            # Isolate fixed-level and roved-level behavioral and model thresholds
            sims_fixed = @subset(sims, :rove_size .== 0.001)
            sims_roved = @subset(sims, :rove_size .== 10.0)
            beh_fixed = @subset(beh, :freq .== freq, :rove .== "fixed level")
            beh_roved = @subset(beh, :freq .== freq, :rove .== "roved level")

            # Plot bowls with scatters and lines, using solid + circles for fixed-level and 
            # dashed + squares for roved-level
            scatter!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=:black)
            lines!(ax, (1:5) .+ (idx-1)*7, beh_fixed.threshold; color=:black)
            if nrow(beh_roved) > 0
                scatter!(ax, (1:5) .+ (idx-1)*7, beh_roved.threshold; color=:black, marker=:rect)
                lines!(ax, (1:5) .+ (idx-1)*7, beh_roved.threshold; color=:black, marker=:rect, linestyle=:dash)
            end
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_fixed.θ; color=:red)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_fixed.θ; color=:red)
            scatter!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:red, marker=:rect)
            lines!(ax, (1:5) .+ (idx-1)*7, sims_roved.θ; color=:red, marker=:rect, linestyle=:dash)
        end

        # Manually set x-axis ticks and labels
        ax.xticks = (
            vcat([(1:5) .+ (i-1)*7 for i in 1:4]...),
            repeat(["5", "13", "21", "29", "37"], 4),
        )

        # Adjust y-axis limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
    end
    
    # Add superlabels to x/y-axes
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2);# colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1], "Number of components // Target frequency (Hz)");# rowgap!(fig.layout, 3, Relative(0.05));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    # colgap!(fig.layout, 2, Relative(0.01))
    # rowgap!(fig.layout, 1, Relative(0.01))
    # rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end


"""
    genfig_sim_bowls_frequency_summary()

Generate figure highlighting model trends versus behavior as a function of target freq.

Depicts model (red) and behavioral (black) thresholds averaged across different component
counts as a function of target frequency. Different observer strategies are faceted into
different columns, while different model stages are faceted into different rows. This is the
bottom-left of Figure 7. 
"""
function genfig_sim_bowls_frequency_summary(grouper=grouper_threeway; color=:black)
    # Get full dataframe of simulated thresholds, subset to include fixed-level unadjusted only
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:rove_size .== 0.001)
    end

    # Fetch relevant behavioral data and average across listeners/repeats
    beh = @chain grouper(fetch_behavioral_data()) begin
        @subset(:rove .== "fixed level", :hl_group .== "Normal hearing", :include .== true)
        avg_behavioral_data()
    end

    # Set up figure (3x2 design)
    set_theme!(theme_carney; fontsize=18.0)
    fig = Figure(; resolution=(360, 400))
    axs = [Axis(fig[i, j]; xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1,3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset simulated data according to observer and model, average across component counts
        df_subset = @chain df begin
            @subset(:model .== model, :mode .== mode)
            groupby([:center_freq, :adjusted])
            @combine(:θ = mean(:θ))
            @orderby(:center_freq)
        end

        # Average real data across component counts 
        beh_subset = @chain beh begin
            groupby(:freq)
            @combine(:threshold = mean(:threshold))
            @orderby(:freq)
        end

        # Plot curves with markers + lines, using red for simulated and black for real data
        scatter!(ax, 1.0:1.0:4.0, @subset(df_subset, :adjusted .== true).θ; color=color, markersize=10.0, marker=:utriangle)
        lines!(ax, 1.0:1.0:4.0, @subset(df_subset, :adjusted .== true).θ; color=color, linewidth=2.0, linestyle=:dash)
        scatter!(ax, 1.0:1.0:4.0, beh_subset.threshold; color=color_group("Normal hearing"), markersize=10.0)
        lines!(ax, 1.0:1.0:4.0, beh_subset.threshold; color=color_group("Normal hearing"), linewidth=2.0)

        # Add text labels to indicate RMSE adj
        Δ = @subset(df_subset, :adjusted .== true).θ .- beh_subset.threshold
        err = sqrt(mean(Δ .^ 2))
        text!(ax, [1.0], [-25.0]; text="RMSE adj. = $(round(err; digits=1)) dB", fontsize=12.0)

        # Manually set x-axis ticks
        ax.xticks = (
            1.0:1.0:4.0,
            ["0.5", "1", "2", "4"],
        )

        # Adjust y-axis limits
        ylims!(ax, -27.0, 5.0)
        ax.yticks = -30.0:10.0:10.0
    end
    
    # Add labels
    Label(fig[:, 0], "Threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Target frequency (kHz)"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.05))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

"""
    genfig_sim_bowls_roving_summary()

Generate figure highlighting model trends versus behavior as a function of level roving
"""
function genfig_sim_bowls_roving_summary(grouper=grouper_threeway; color=:black)
    # Get full dataframe of simulated threshold, subset as needed
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:adjusted .== false, :center_freq .== 1000.0)
    end

    # Fetch relevant behavioral data and average across listeners/repeats
    beh = @chain grouper(fetch_behavioral_data()) begin
        @subset(:hl_group .== "Normal hearing", :include .== true, :freq .== 1000)
        avg_behavioral_data()
    end

    # Set up figure (3x2 design)
    set_theme!(theme_carney; fontsize=18.0)
    fig = Figure(; resolution=(360, 400))
    axs = [Axis(fig[i, j]; xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1,3]]))
    map(zip(itr, axs)) do ((model, mode), ax)

        # Subset simulated data according to observer and model, average across component counts
        df_subset = @orderby(@subset(df, :model .== model, :mode .== mode), :n_comp)

        # Average real data across component counts 
        beh_subset = @orderby(beh, :n_comp)

        # Plot curves with markers + lines, using red for simulated and black for real data
        mod_unroved = @subset(df_subset, :rove_size .== 0.001).θ
        mod_roved = @subset(df_subset, :rove_size .== 10.0).θ
        beh_unroved = @subset(beh_subset, :rove .== "fixed level").threshold
        beh_roved = @subset(beh_subset, :rove .== "roved level").threshold

        lines!(ax, 1:1:5, mod_roved .- mod_unroved; color=:black, linewidth=2.0)
        scatter!(ax, 1:1:5, mod_roved .- mod_unroved; color=:black, markersize=10.0, marker=:utriangle)
        lines!(ax, 1:1:5, beh_roved .- beh_unroved; color=color_group("Normal hearing"), linewidth=2.0)
        scatter!(ax, 1:1:5, beh_roved .- beh_unroved; color=color_group("Normal hearing"), markersize=10.0)

        # Add text labels to indicate RMSE adj
        Δ = (beh_roved .- beh_unroved) .- (mod_roved .- mod_unroved)
        err = sqrt(mean(Δ .^ 2))
        text!(ax, [1.0], [26.0]; text="RMSE = $(round(err; digits=1)) dB", fontsize=12.0)

        # Manually set x-axis ticks
        ax.xticks = (
            1:1:5,
            ["5", "13", "21", "29", "37"],
        )

        # Adjust y-axis limits
        ylims!(ax, -2.0, 30.0)
    end
    
    # Add labels
    Label(fig[:, 0], "Rove effect (dB)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Component count"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.05))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end


"""
    genfig_sim_bowls_modelbehavior_scatterplots()

Generate figure summarizing model performance in terms of model-behavior correlation

Plots correlations between behavioral thresholds (x-axis) and modeled threhsolds (y-axis)
along with a linear fit line. Different observer strategies are faceted into different
columns, while different model stages are faceted into different rows. Marker shape
indicates target frequency, using the mapping provided by the function `pick_marker(freq)`.
This is the bottom right of Figure 7. 
"""
function genfig_sim_bowls_modelbehavior_scatterplots(grouper=grouper_threeway)
    # Get full dataframe
    df = @chain load_simulated_thresholds_adjusted() begin  
        @subset(:rove_size .== 0.001, :adjusted .== false)
    end

    # Compile relevant behavioral data
    beh = @chain grouper(fetch_behavioral_data()) begin
        @subset(:rove .== "fixed level", :hl_group .== "Normal hearing")
        avg_behavioral_data()
        @orderby(:n_comp, :freq)
    end

    # Set up figure
    set_theme!(theme_carney; fontsize=18.0)
    fig = Figure(; resolution=(360, 400))
    axs = [Axis(fig[i, j]; xminorticksvisible=false) for i in 1:3, j in 1:2]

    # Loop over all combinations of mode and model
    itr = collect(Iterators.product(unique(df.model), unique(df.mode)[[1,3]]))
    map(zip(itr, axs)) do ((model, mode), ax)
        # Subset modeled data
        df_subset = @chain df begin
            @subset(:model .== model, :mode .== mode)
            @orderby(:n_comp, :center_freq)
        end

        # Loop through frequencies and plot each as separate scatter
        for freq in [500, 1000, 2000, 4000]
            beh_temp = beh[beh.freq .== freq, :]
            mod_temp = df_subset[df_subset.center_freq .== freq, :]

            scatter!(
                ax, 
                beh_temp.threshold, 
                mod_temp.θ; 
                color=:black, 
                marker=pick_marker(freq), 
                label=string(freq/1000),
                markersize=10.0
            )
        end

        # Fit lm 
        temp = DataFrame(behavior=beh.threshold, model=df_subset.θ)
        m = lm(@formula(model ~ behavior), temp) 
        varexp = string(round(r2(m) * 100.0; digits=2))
        x̂ = -30.0:0.1:10.0
        β₀ = coef(m)[1]
        β = coef(m)[2]
        lines!(ax, x̂, β₀ .+ x̂ .* β; color=:gray, linewidth=2.0)
        text!(ax, [-33.0], [0.0]; text=string(varexp) * "%")

        # Set limits
        ylims!(ax, -35.0, 10.0)
        ax.yticks = -30.0:10.0:10.0
        xlims!(ax, -35.0, 10.0)
        ax.xticks = -30.0:10.0:10.0

        # Add axis legend
        # if (model == "InferiorColliculusSFIEBS") & (mode == "singlechannel")
        #     axislegend(ax; orientation=:horizontal, position=:lb)
        # end
    end
    
    # Add labels
    Label(fig[:, 0], "Model threshold (dB SRS)"; rotation=π/2); colgap!(fig.layout, 1, Relative(0.01));
    Label(fig[4, 1:2], "Behavioral threshold (dB SRS)"); rowgap!(fig.layout, 3, Relative(0.01));

    # Adjust colgaps and neaten grid
    neaten_grid!(axs)
    colgap!(fig.layout, 2, Relative(0.05))
    rowgap!(fig.layout, 1, Relative(0.01))
    rowgap!(fig.layout, 2, Relative(0.01))

    # Return
    fig
end

"""
    genfig_sim_bowls_error_summary()

Plots errors between data and model for adjusted and unadjusted model thresholds
"""
function genfig_sim_bowls_error_summary()
    
end