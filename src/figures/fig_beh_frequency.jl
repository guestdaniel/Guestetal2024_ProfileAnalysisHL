export genfig_beh_frequency_psychometric_functions,  # Figure 2A
       genfig_beh_frequency_bowls                    # Figure 2B

"""
    genfig_beh_frequency_psychometric_functions()

Plot psychometric functions for fixed-level data in every condition and HL group

Plots group-average psychometric functions for each HL group in every fixed-level conditions
(i.e., all combinations of target frequency and component count). Thresholds are indicated 
with small markers below the curves. This figure is placed in the left-hand side of Figure 
2.
"""
function genfig_beh_frequency_psychometric_functions()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :rove .== "fixed level", :include .== true)

    # Calculate means in each condition and store in dataframe
    df_mean = @chain df begin
        # Group by freq, increment, component count, group, and subject
        groupby([:freq, :increment, :n_comp, :hl_group, :subj])

        # Calculate means (in each condition, for each subject)
        @combine(:μ = mean(:pcorr))

        # Group by freq, increment, component count, and group
        groupby([:freq, :increment, :n_comp, :hl_group])

        # Filter out places where we have too little data (we want at least 2 subjects at each point)
        transform(:μ => (x -> length(x)) => :count)
        @subset(:count .> 2)

        # Group again
        groupby([:freq, :increment, :n_comp, :hl_group])

        # Compute μ and stderr
        @combine(
            :stderr = std(:μ)/sqrt(length(:μ)),
            :μ = mean(:μ),
        )
    end

    # Fetch psychometric functions from pre-computed dataframe
    thresholds = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))
    thresholds = @subset(thresholds, :rove .== "fixed level", :include .== true)
    df_fitted = @chain thresholds begin
        # Group by rove, component count, and group
        groupby([:freq, :n_comp, :hl_group, :subj, :include])

        # Get one threshold and slope number per subject
        @combine(
            :threshold = mean(:threshold),
            :slope = mean(:slope),
        )

        # Ungroup by subj
        groupby([:freq, :n_comp, :hl_group, :include])

        # Average threshold and slopes across subjects
        @combine(
            :threshold = mean(:threshold),
            :slope = mean(:slope),
        )
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
    fig = Figure(; resolution=(600 * sf, 615 * sf))
    axs = map(Iterators.product(1:5, 1:4)) do (i, j)
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
            for (idx_freq, freq) in enumerate([500, 1000, 2000, 4000])
                # Subset means and filled data
                mean_sub = @subset(df_mean, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)
                filled_sub = @subset(df_filled, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)

                # Plot curve fit
                lines!(axs[idx_n_comp, idx_freq], filled_sub.increment, filled_sub.pcorr; color=color_group(group))

                # Plot data and errorbars
                errorbars!(axs[idx_n_comp, idx_freq], mean_sub.increment, mean_sub.μ, 1.96 .* mean_sub.stderr; color=color_group(group))
                scatter!(axs[idx_n_comp, idx_freq], mean_sub.increment, mean_sub.μ; color=color_group(group))

                # Plot thresholds as small markers below curves
                offset = 0.30 + (idx_group-1)*0.05
                fitted_sub = @subset(df_fitted, :n_comp .== n_comp, :freq .== freq, :hl_group .== group)
                scatter!(axs[idx_n_comp, idx_freq], fitted_sub.threshold, [offset]; marker=:circle, color=color_group(group))
            end
        end
    end

    # Add labels
    [Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"])]
    [Label(fig[i, 5], label; tellheight=false, rotation=-π/2) for 
        (i, label) in enumerate(string.(sort(unique(df.n_comp))) .* " comps")]
    Label(fig[1:5, 0], "Proportion correct"; rotation=π/2)
    Label(fig[6, 1:4], "Increment (dB SRS)")

    # Adjust spacing
    rowgap!(fig.layout, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

"""
    genfig_beh_frequency_bowls()

Plot thresholds as a function of target frequency for fixed-level data in each HL group

Plots group-average thresholds each HL group as a function of target frequency, faceted
into different rows for each component-count condition. This figure is placed in the 
right-hand side of Figure 2.
"""
function genfig_beh_frequency_bowls()
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :rove .== "fixed level", :include .== true)

    # Summarize as function of number of components and group
    df_summary = @chain df begin
        # Group by freq, component count, and group
        groupby([:freq, :n_comp, :hl_group])

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
    fig = Figure(; resolution=(235 * sf, 620 * sf))
    axs = map(1:5) do i
        Axis(
            fig[i, 1], 
            xticklabelrotation=π/4,
            xticks=(1:4, ["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"]),
            yticks=-10:10:10,
            xminorticksvisible=false,
        )
    end
    ylims!.(axs, -20.0, 10.0)
    xlims!.(axs, 0.5, 4.5)
    neaten_grid!(axs, "vertical")

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
        for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
            # Subset means and filled data
            sub = @subset(df_summary, :n_comp .== n_comp, :hl_group .== group)
            sub = @orderby(sub, :freq)

            # Plot bowl
            errorbars!(axs[idx_n_comp], 1:4, sub.threshold, 1.96 .* sub.stderr; color=color_group(group))
            scatter!(axs[idx_n_comp], 1:4, sub.threshold; color=color_group(group))
            lines!(axs[idx_n_comp], 1:4, sub.threshold; color=color_group(group))
        end
    end

    # Adjust spacing
    axs[end].xlabel = "Target freq (Hz)"
    Label(fig[1:5, 0], "Threshold (dB SRS)"; rotation=π/2, tellheight=false)
    map(enumerate(sort(unique(df.n_comp)))) do (idx, label)
        Label(fig[idx, 2], "$label comp"; rotation=-π/2, tellheight=false)
    end
    rowgap!(fig.layout, Relative(0.02))
    colgap!(fig.layout, Relative(0.05))

    # Render and save
    fig
end