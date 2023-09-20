export genfig_beh_1kHz_psychometric_functions,  # Figure 1A
       genfig_beh_1kHz_bowls,                   # Figure 1B
       genfig_beh_1kHz_rove_effects             # Figure 1C

"""
    genfig_beh_1kHz_psychometric_functions()

Plot group-average psychometric functions for all 1-kHz conditions

Plot group-average psychometric functions for each HL group for each component-count
condition at 1-kHz target frequency, contrasting fixed-level and roved-level results. Placed
on left side of Figure 1 as Subfigure A.
"""
function genfig_beh_1kHz_psychometric_functions()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

    # Filter data only to include relevant subsections (1-kHz data)
    df = @subset(df, :freq .== 1000)

    # Calculate means in each condition and store in dataframe
    df_mean = @chain df begin
        # Group by rove, increment, component count, group, and subject
        groupby([:rove, :increment, :n_comp, :hl_group, :subj])

        # Calculate means (in each condition, for each subject)
        @combine(:μ = mean(:pcorr))

        # Group by rove, increment, component count, and group
        groupby([:rove, :increment, :n_comp, :hl_group])

        # Filter out places where we have too little data (we want at least 2 subjects at each point)
        transform(:μ => (x -> length(x)) => :count)
        @subset(:count .> 2)

        # Group again
        groupby([:rove, :increment, :n_comp, :hl_group])

        # Compute μ and stderr
        @combine(
            :stderr = std(:μ)/sqrt(length(:μ)),
            :μ = mean(:μ),
        )
    end

    # Fit psychometric functions and store in results in dataframe
    df_fitted = @chain df_mean begin
        # Group by rove, component count, and group
        groupby([:rove, :n_comp, :hl_group])

        # Fit logistic function to data
        @combine(:fit = fit_psychometric_function(:increment, :μ))

        # Extract slope and threshold
        @transform(:threshold = getindex.(getfield.(:fit, ^(:param)), 1))
        @transform(:slope = getindex.(getfield.(:fit, ^(:param)), 2))
    end

    # Expand each row of df_fitted into interpolated datapoints  
    x̂ = -30.0:0.1:20.0
    df_filled = map(eachrow(df_fitted)) do row
        pcorr = logistic_predict(x̂, row.threshold, row.slope)
        rows = map(1:length(pcorr)) do idx
            temp = copy(row)
            temp = merge(temp, (:pcorr => pcorr[idx], :increment => x̂[idx]))
        end
        rows = DataFrame(rows)
    end
    df_filled = vcat(df_filled...)

    # Configure plotting parameters
    set_theme!(theme_carney)

    # Create figure and axes
    sf = 0.8
    fig = Figure(; resolution=(450 * sf, 600 * sf))
    axs = map(Iterators.product(1:5, 1:3)) do (i, j)
        Axis(
            fig[i, j], 
            xticks=-20:10:10,
            xminorticks=-20:5:15,
            yticks=0.5:0.25:1.0, 
            yminorticks=(0.5-0.125):0.125:1.0,
        )
    end
    neaten_grid!(axs)
    ylims!.(axs, 0.27, 1.1)
    xlims!.(axs, -25.0, 16.0)

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
        for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
            for (idx_rove, (rove, marker)) in enumerate(zip(["fixed level", "roved level"], [:circle, :rect]))
                # Subset means and filled data
                mean_sub = @subset(df_mean, :n_comp .== n_comp, :rove .== rove, :hl_group .== group)
                filled_sub = @subset(df_filled, :n_comp .== n_comp, :rove .== rove, :hl_group .== group)

                # Plot curve fit
                lines!(axs[idx_n_comp, idx_group], filled_sub.increment, filled_sub.pcorr; color=color_group(group))

                # Plot errorbars
                if rove == "fixed level"
                    errorbars!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ, zeros(length(mean_sub.stderr)), 1.96 .* mean_sub.stderr; color=color_group(group))
                else
                    errorbars!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ, 1.96 .* mean_sub.stderr, zeros(length(mean_sub.stderr)); color=color_group(group))
                end

                # Plot means
                scatter!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ; color=color_group(group), marker=marker)
                if rove == "roved level"
                    scatter!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ; color=:white, markersize=fig_defaults["markersize"]/2, marker=marker)
                end

                # Plot thresholds with small markers below psychometric functions
                offset = 0.35
                fitted_fixed = @subset(df_fitted, :n_comp .== n_comp, :rove .== "fixed level", :hl_group .== group)
                fitted_roved = @subset(df_fitted, :n_comp .== n_comp, :rove .== "roved level", :hl_group .== group)
                lines!(axs[idx_n_comp, idx_group], [fitted_fixed.threshold[1], fitted_roved.threshold[1]], [offset, offset]; color=color_group(group))
                scatter!(axs[idx_n_comp, idx_group], fitted_fixed.threshold, [offset]; marker=:circle, color=color_group(group))
                scatter!(axs[idx_n_comp, idx_group], fitted_roved.threshold, [offset]; marker=:rect, color=color_group(group))
                scatter!(axs[idx_n_comp, idx_group], fitted_roved.threshold, [offset]; marker=:rect, color=:white, markersize=fig_defaults["markersize"]/2)
                # end
            end
        end
    end

    # Add labels
    [Label(fig[i, 4], label; tellheight=false, rotation=-π/2) for 
        (i, label) in enumerate(string.(sort(unique(df.n_comp))) .* " comps")]
    Label(fig[1:5, 0], "Proportion correct"; rotation=π/2)
    Label(fig[6, 1:3], "Increment (dB SRS)")

    # Adjust spacing
    rowgap!(fig.layout, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))

    # Save to disk
    fig
end

"""
    genfig_beh_1kHz_bowls()

Plot classic profile-analysis "bowls" for the 1-kHz data 

Plot group-average thresholds as a function of component count for each group (faceted 
by column). This plot is LHC's profile-analysis "bowl", and one of the main goals of the 
project was to measure how the bowl shifts around due to cochlear hearing loss. This figure
is placed in the upper-right corner of Figure 1 and is Subfigure B.
"""
function genfig_beh_1kHz_bowls()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :freq .== 1000)

    # Summarize as function of number of components and group
    df_summary = @chain df begin
        # Group by rove, component count, and group
        groupby([:rove, :n_comp, :hl_group])

        # Summarize
        @combine(
            :stderr = std(:threshold)/sqrt(length(:threshold)),
            :threshold = mean(:threshold),
        )
    end

    # Configure plotting parameters
    set_theme!(theme_carney; Scatter=(markersize=10.0, ))

    # Create figure and axes
    sf = 0.8
    fig = Figure(; resolution=(450 * sf, 180 * sf))
    axs = map(1:3) do i
        Axis(
            fig[1, i], 
            xticks=sort(unique(df.n_comp)),
        )
    end
    ylims!.(axs, -20.0, 1.0)
    xlims!.(axs, 2, 40)
    neaten_grid!(axs, "horizontal")

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
        for (idx_rove, rove) in enumerate(["fixed level", "roved level"])
            # Subset means and filled data
            sub = @subset(df_summary, :rove .== rove, :hl_group .== group)

            # Plot bowl
            lines!(axs[idx_group], sub.n_comp, sub.threshold; color=color_group(group))
            if rove .== "fixed level"
                errorbars!(axs[idx_group], sub.n_comp, sub.threshold, 1.96 .* sub.stderr, zeros(5); color=color_group(group))
            else
                errorbars!(axs[idx_group], sub.n_comp, sub.threshold, zeros(5), 1.96 .* sub.stderr; color=color_group(group))
            end
            scatter!(axs[idx_group], sub.n_comp, sub.threshold; color=color_group(group), marker=rove == "fixed level" ? :circle : :rect)
            if rove == "roved level"
                scatter!(axs[idx_group], sub.n_comp, sub.threshold; color=:white, markersize=10.0/2, marker=rove == "fixed level" ? :circle : :rect)
            end
        end
    end

    # Adjust spacing
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

"""
    genfig_beh_1kHz_rove_effects()

Plot differences between roved-level and fixed-level profile-analysis thresolds at 1 kHz

Plot the "rove effect" magnitude, or the difference beween the roved-level threshold and
the fixed-level threshold for every listener at 1 kHz. This figure is placed in the bottom
left of Figure 1, and is Subfigure C.
"""
function genfig_beh_1kHz_rove_effects()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :freq .== 1000)

    # Summarize as function of number of components and group
    df_ind = @chain df begin
        # Select only what we need
        @select(:rove, :n_comp, :hl_group, :subj, :threshold)

        unstack(:rove, :threshold)

    end
    df_ind[!, :diff] .= df_ind[:, 5] .- df_ind[:, 4]
    df_ind = df_ind[completecases(df_ind), :]

    df_summary = @chain df_ind begin
        # Group by rove, component count, and group
        groupby([:n_comp, :hl_group])

        # Summarize
        @combine(
            :stderr = std(:diff)/sqrt(length(:diff)),
            :diff = mean(:diff),
        )
    end

    # Configure plotting parameters
    set_theme!(theme_carney; Scatter=(markersize=10.0, ))

    # Create figure and axes
    sf = 0.8
    fig = Figure(; resolution=(450 * sf, 180 * sf))
    axs = map(1:3) do i
        Axis(
            fig[1, i], 
            xticks=sort(unique(df.n_comp)),
            yticks=0:5:15, 
        )
    end
    ylims!.(axs, -2.5, 15.0)
    xlims!.(axs, 2, 40)
    neaten_grid!(axs, "horizontal")

    # Add solid hline at 0.0
    hlines!.(axs, [0.0]; color=:black, linewidth=1.0)

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
        # Subset means and filled data
        sub = @subset(df_summary, :hl_group .== group)
        ind = @subset(df_ind, :hl_group .== group)

        # Plot bowl
        errorbars!(axs[idx_group], sub.n_comp, sub.diff, 1.96 .* sub.stderr; color=color_group(group))
        scatter!(axs[idx_group], sub.n_comp, sub.diff; color=color_group(group), marker=:utriangle)
        scatter!(axs[idx_group], ind.n_comp .+ 2, ind.diff; color=color_group(group), markersize=fig_defaults["markersize"]/3, marker=:utriangle)
    end

    # Adjust spacing
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end