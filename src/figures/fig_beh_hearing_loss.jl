export genfig_beh_hearing_loss  # Figure 3

"""
    genfig_beh_hearing_loss()

Plot correlations between degree of hearing loss and profile-analysis thresholds

Plotted correlations between degree of hearing loss (quantified by audiometric threshold at
frequency corresponding to target frequency) and fixed-level profile-analysis thresholds in
each tested condition. Includes a demarcation of degrees of hearing loss for which we might
expect some part of the stimulus to be inaudible (because per-component level falls below
audiometric thresholds) and linear trend lines. Is Figure 3.
"""
function genfig_beh_hearing_loss()
    # Write mini function to fit lm to data and return interpolated fits
    function fit_lm(df)
        m = lm(@formula(threshold ~ hl), df)
        b, m = coef(m)
        x̂ = LinRange(-15.0, 90.0, 1000)
        ŷ = m .* x̂ .+ b
        return x̂, ŷ
    end

    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Manually note which conditions are significant (as of 3/17/23)
    significant = [
        (5, 500),
        (13, 500),
        (5, 1000),
        (13, 2000),
        (21, 2000),
        (29, 2000),
        (37, 2000),
        (37, 4000),
    ]

    # Filter data only to include relevant subsections (unroved data) 
    df = @subset(df, :rove .== "fixed level")

    # Configure plotting parameters
    set_theme!(theme_carney)

    # Create figure and axes
    sf = 0.8
    fig = Figure(; resolution=(600 * sf, 615 * sf))
    axs = map(Iterators.product(1:5, 1:4)) do (i, j)
        Axis(
            fig[i, j], 
            yticks=-20:10:10,
        )
    end
    ylims!.(axs, -20.0, 20.0)
    xlims!.(axs, -15.0, 90.0)
    neaten_grid!(axs)

    # Loop through combinations of component spacing (rows) and frequency (columns), plot data
    for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
        for (idx_freq, freq) in enumerate([500, 1000, 2000, 4000])
            # Calculate SL cutoff and plot
            level_per_component = total_to_comp(70.0, n_comp)
            level_per_component_in_hl = spl_to_hl(level_per_component, freq)
            band!(axs[idx_n_comp, idx_freq], [level_per_component_in_hl, 90.0], [-20, -20], [20, 20]; color=HSL(0.0, 0.5, 0.95))

            # Summarize data and plot
            for (idx_group, group) in enumerate(["< 5 dB HL", "5-15 dB HL", "> 15 dB HL"])
                # Subset data
                sub = @subset(df, :n_comp .== n_comp, :freq .== freq, :hl_group .== group, :include .== true)
                sub_excl = @subset(df, :n_comp .== n_comp, :freq .== freq, :hl_group .== group, :include .== false)

                # Plot curve fit
                scatter!(axs[idx_n_comp, idx_freq], sub.hl, sub.threshold; color=color_group(group))
                scatter!(axs[idx_n_comp, idx_freq], sub_excl.hl, sub_excl.threshold; color=:gray, marker=:xcross)
            end

            # Fit regression to pooled data and plot (only use "legal" rows)
            sub = @subset(df, :n_comp .== n_comp, :freq .== freq, :include .== true)
            x̂, ŷ = fit_lm(sub)
            sig = CorrelationTest(sub.hl, sub.threshold)
            if pvalue(sig) > 0.05
                lines!(axs[idx_n_comp, idx_freq], x̂, ŷ; color=:black, linestyle=:dash)
            else
                lines!(axs[idx_n_comp, idx_freq], x̂, ŷ; color=:black, linestyle=:solid)
            end
        end
    end

    # Add labels
    [Label(fig[0, i], label; tellwidth=false) for (i, label) in enumerate(["500 Hz", "1000 Hz", "2000 Hz", "4000 Hz"])]
    [Label(fig[i, 5], label; tellheight=false) for 
        (i, label) in enumerate(string.(sort(unique(df.n_comp))))]
    Label(fig[1:5, 0], "Profile-analysis threshold (dB SRS)"; rotation=π/2)
    Label(fig[6, 1:4], "Audiometric threshold at target frequency (dB HL)")

    # Adjust spacing
    rowgap!(fig.layout, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end