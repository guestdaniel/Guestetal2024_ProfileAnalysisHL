# fig_beh_alternatives_hl.jl
#
# Code for alternative versions of figures showing hearing loss behavioral PA results

export genfig_beh_1kHz_bowls_v2, 
       genfig_beh_hearing_loss_v2, genfig_beh_frequency_bowls_v2, genfig_beh_1kHz_rove_effects_v2,
       genfig_beh_1kHz_psychometric_functions_v3

function genfig_beh_1kHz_bowls_v2(grouper=grouper_threeway)
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :freq .== 1000)#, :include .== true)

    # Group data based on grouper function
    df = grouper(df)

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
    sf = 0.9
    fig = Figure(; resolution=(150 * length(unique(df.hl_group)) * sf, 190 * sf))
    axs = map(1:length(unique(df.hl_group))) do i
        Axis(
            fig[1, i], 
            xticks=sort(unique(df.n_comp)),
            xminorticksvisible=false,
        )
    end
    ylims!.(axs, -20.0, 1.0)
    xlims!.(axs, 2, 40)
    neaten_grid!(axs, "horizontal")

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_group, group) in enumerate(unique(df.hl_group)[[2, 1, 3]])
        sub_group = @subset(df_summary, :hl_group .== group)
        for (idx_rove, rove) in enumerate(["fixed level", "roved level"])
            # Subset means and filled data
            sub = @orderby(@subset(sub_group, :rove .== rove), :n_comp)

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
        axs[idx_group].title = group * "\n(n = $(length(unique(df[df.hl_group .== group, :].subj))))"
    end

    # Adjust spacing
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

"""
    genfig_beh_1kHz_rove_effects_v2()

Plot differences between roved-level and fixed-level profile-analysis thresolds at 1 kHz

Plot the "rove effect" magnitude, or the difference beween the roved-level threshold and
the fixed-level threshold for every listener at 1 kHz. This figure is placed in the bottom
left of Figure 1, and is Subfigure C.
"""
function genfig_beh_1kHz_rove_effects_v2(grouper=grouper_threeway)
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :freq .== 1000)

    # Group data based on grouper function
    df = grouper(df)

    # Summarize as function of number of components and group
    df_ind = @chain df begin
        # Select only what we need
        @select(:rove, :n_comp, :hl_group, :subj, :threshold, :include)

        unstack(:rove, :threshold)
    end

    df_ind[!, :diff] .= df_ind[:, 6] .- df_ind[:, 5]
    df_ind = df_ind[completecases(df_ind), :]

    df_summary = @chain df_ind begin
        # Eliminate elements that aren't in "include"
        @subset(:include .== true)

        # Group by rove, component count, and group
        groupby([:n_comp, :hl_group, :include])

        # Summarize
        @combine(
            :stderr = std(:diff)/sqrt(length(:diff)),
            :diff = mean(:diff),
        )
    end

    # Configure plotting parameters
    set_theme!(theme_carney; Scatter=(markersize=10.0, ))

    # Create figure and axes
    sf = 0.9
    fig = Figure(; resolution=(150 * length(unique(df.hl_group)) * sf, 190 * sf))
    axs = map(1:length(unique(df.hl_group))) do i
        Axis(
            fig[1, i], 
            xticks=sort(unique(df.n_comp)),
            xminorticksvisible=false,
            yticks=0:5:15,
        )
    end
    ylims!.(axs, -5.0, 17.0)
    xlims!.(axs, 2, 40)
    neaten_grid!(axs, "horizontal")

    # Add solid hline at 0.0
    hlines!.(axs, [0.0]; color=:black, linewidth=1.0)

    # Loop through combinations of component spacing (rows) and rove (columns), plot data
    for (idx_group, group) in enumerate(unique(df.hl_group)[[2, 1, 3]])
        # Subset means and filled data
        sub = @subset(df_summary, :hl_group .== group, :include .== true)
        ind = @subset(df_ind, :hl_group .== group, :include .== true)
        ind_excl = @subset(df_ind, :hl_group .== group, :include .== false)

        # Plot bowl
        errorbars!(axs[idx_group], sub.n_comp, sub.diff, 1.96 .* sub.stderr; color=color_group(group))
        scatter!(axs[idx_group], sub.n_comp, sub.diff; color=color_group(group), marker=:utriangle)
        scatter!(axs[idx_group], ind.n_comp .+ 2, Float64.(ind.diff); color=color_group(group), markersize=fig_defaults["markersize"]/1.4, marker=:utriangle)
        scatter!(axs[idx_group], ind_excl.n_comp .+ 2, Float64.(ind_excl.diff); color=:gray, markersize=fig_defaults["markersize"]/1.4, marker=:xcross)
        axs[idx_group].title = group * "\n(n = $(length(unique(df[df.hl_group .== group, :].subj))))"
    end

    # Adjust spacing
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

function genfig_beh_hearing_loss_v2(xaxis=:hl, xlims=(-5.0, 80.0))
    # Write mini function to fit lm to data and return interpolated fits
    function fit_lm(x, y)
        X = hcat(ones(length(x)), x)
        m = lm(X, y)
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
    xlims!.(axs, xlims...)
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
                scatter!(axs[idx_n_comp, idx_freq], sub[:, xaxis], sub.threshold; color=color_group(group))
                scatter!(axs[idx_n_comp, idx_freq], sub_excl[:, xaxis], sub_excl.threshold; color=:gray, marker=:xcross)
            end

            # Fit regression to pooled data and plot (only use "legal" rows)
            sub = @subset(df, :n_comp .== n_comp, :freq .== freq, :include .== true)
            x̂, ŷ = fit_lm(sub[:, xaxis], sub[:, :threshold])
            sig = CorrelationTest(sub[:, xaxis], sub.threshold)
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

"""
    genfig_beh_1kHz_psychometric_functions_v3()

Plot group-average psychometric functions for all 1-kHz conditions

Plot group-average psychometric functions for each HL group for each component-count
condition at 1-kHz target frequency, contrasting fixed-level and roved-level results. Placed
on left side of Figure 1 as Subfigure A. In contrast to the original figure code, this 
version displays average psychometric functions derived by fitting individual psychometric 
functions and then averaging parameter values, rather than averaging data and then 
fitting a group-level psychometric function.

TODO: Migrate to replace original
"""
function genfig_beh_1kHz_psychometric_functions_v3(grouper=grouper_threeway)
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "data_postproc.csv")))

    # Filter data only to include relevant subsections (1-kHz data)
    df = @subset(df, :freq .== 1000, :include .== true)

    # Group dataset according to grouper function
    df = grouper(df)

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
#        @subset(:count .> 2)

        # Group again
        groupby([:rove, :increment, :n_comp, :hl_group])

        # Compute μ and stderr
        @combine(
            :stderr = std(:μ)/sqrt(length(:μ)),
            :μ = mean(:μ),
        )
    end

    # Fetch psychometric functions from pre-computed dataframe
    thresholds = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))
    thresholds = @subset(thresholds, :freq .== 1000, :include .== true)
    thresholds = grouper(thresholds)
    df_fitted = @chain thresholds begin
        # Group by rove, component count, and group
        groupby([:rove, :n_comp, :hl_group, :subj])

        # Get one threshold and slope number per subject
        @combine(
            :threshold = mean(:threshold),
            :slope = mean(:slope),
        )

        # Ungroup by subj
        groupby([:rove, :n_comp, :hl_group])

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
    sf = 0.9
    fig = Figure(; resolution=(150 * length(unique(df.hl_group)) * sf, 600 * sf))
    axs = map(Iterators.product(1:5, 1:length(unique(df.hl_group)))) do (i, j)
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
        for (idx_group, group) in enumerate(unique(df.hl_group)[[2, 1, 3]])
            for (idx_rove, (rove, marker)) in enumerate(zip(["fixed level", "roved level"], [:circle, :rect]))
                # Subset means and filled data
                mean_sub = @subset(df_mean, :n_comp .== n_comp, :rove .== rove, :hl_group .== group)
                filled_sub = @subset(df_filled, :n_comp .== n_comp, :rove .== rove, :hl_group .== group)

                # Plot curve fit
                lines!(axs[idx_n_comp, idx_group], filled_sub.increment, filled_sub.pcorr; color=color_group(group))

                # Plot errorbars
                if rove == "fixed level"
                    # errorbars!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ, zeros(length(mean_sub.stderr)), 1.96 .* mean_sub.stderr; color=color_group(group))
                else
                    # errorbars!(axs[idx_n_comp, idx_group], mean_sub.increment, mean_sub.μ, 1.96 .* mean_sub.stderr, zeros(length(mean_sub.stderr)); color=color_group(group))
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
            
            if idx_n_comp == 1
                axs[idx_n_comp, idx_group].title = group * "\n(n = $(length(unique(df[df.hl_group .== group, :].subj))))"
            end

        end
    end

    # Add labels
    [Label(fig[i, length(unique(df.hl_group)) + 1], label; tellheight=false, rotation=-π/2) for 
        (i, label) in enumerate(string.(sort(unique(df.n_comp))) .* " comps")]
    Label(fig[1:5, 0], "Proportion correct"; rotation=π/2)
    Label(fig[6, 1:length(unique(df.hl_group))], "Increment (dB SRS)")

    # Adjust spacing
    rowgap!(fig.layout, Relative(0.02))
    colgap!(fig.layout, Relative(0.02))

    # Save to disk
    fig
end


function genfig_beh_frequency_bowls_v2(grouper=grouper_pta4)
    # Load in data
    df = DataFrame(CSV.File(datadir("int_pro", "thresholds.csv")))

    # Filter data only to include relevant subsections (1 kHz data)
    df = @subset(df, :rove .== "fixed level", :include .== true)

    df = grouper(df)

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
    colors = colorschemes[:Dark2_8]
    for (idx_group, (group, c)) in enumerate(zip(unique(df.hl_group), colors))
        for (idx_n_comp, n_comp) in enumerate(sort(unique(df.n_comp)))
            println("$idx_group $idx_n_comp")
            # Subset means and filled data
            sub = @subset(df_summary, :n_comp .== n_comp, :hl_group .== group)
            sub = @orderby(sub, :freq)

            # Plot bowl
            errorbars!(axs[idx_n_comp], 1:length(sub.threshold), sub.threshold, 1.96 .* sub.stderr; color=c)
            scatter!(axs[idx_n_comp], 1:length(sub.threshold), sub.threshold; color=c)
            lines!(axs[idx_n_comp], 1:length(sub.threshold), sub.threshold; color=c)
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