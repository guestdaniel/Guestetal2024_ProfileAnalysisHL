export genfig_sim_methods_rlfs,              # Figure 4B, row #1
       genfig_sim_methods_tcs,               # Figure 4B, row #2
       genfig_sim_methods_mtfs,              # Figure 4B, row #3
       genfig_sim_methods_mtf_filterbank,
       genfig_sim_methods_example_responses  # Figure 4B, row #4

"""
    genfig_sim_methods_rlfs()

Plot rate-level functions for each tested auditory model

Simulate and plot rate-level functions for HSR/LSR/BE/BS models at a nominal CF of 2 kHz. 
Demarcates the sound level corresponding to the per-component level of a 21-component 
profile-analysis stimulus presented at an overll level of 70 dB SPL. Is a subfigure in the 
left-hand side of Figure 4. Uses free y-axes to accomodate wide variation in discharge rate 
between models.
"""
function genfig_sim_methods_rlfs()
    # Set theme and other visual features
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

    # Create figure and axes for each MTF
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Do each individual plot
    plot_model_rlf!(axs[1], 2000.0, "high")
    plot_model_rlf!(axs[2], 2000.0, "low")
    plot_model_rlf!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
    plot_model_rlf!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)
    [vlines!(ax, total_to_comp(70.0, 21); color=:gray, linestyle=:dash) for ax in axs]

    # Add labels
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 2:3], "Sound level (dB SPL)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    fig
end

"""
    plot_model_rlf!(ax, cf=2000.0, fiber_type="high")

Simulate and plot-in-place rate-level function for AN model with specified parameters
"""
function plot_model_rlf!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = ToneRLF(model, 0.0, 80.0, 20)
    out = @memo Default() simulate(sim)
    scatter!(ax, axis(sim), out; color=:black)
    lines!(ax, axis(sim), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    plot_model_rlf!(ax, modeltype=InferiorColliculusSFIEBE, param=StandardBE)

Simulate and plot-in-place rate-level function for IC model with specified parameters
"""
function plot_model_rlf!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = ToneRLF(model, 0.0, 80.0, 20)
    out = @memo Default() simulate(sim)
    scatter!(ax, axis(sim), out; color=:black)
    lines!(ax, axis(sim), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    genfig_sim_methods_tcs()

Plot iso-level tuning curves for each tested auditory model

Simulate and plot iso-level tuning curves for HSR/LSR/BE/BS models at a nominal CF of 2 kHz. 
Uses a sound level of 30 dB SPL. Is a subfigure of Figure 4. Uses free y-axes to accomodate 
wide variation in discharge rate between models.
"""
function genfig_sim_methods_tcs()
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

    # Create figure and axes for each MTF
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Do each individual plot
    plot_model_tc!(axs[1], 2000.0, "high")
    plot_model_tc!(axs[2], 2000.0, "low")
    plot_model_tc!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
    plot_model_tc!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)

    # Add labels
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 2:3], "Frequency (oct re: CF)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    fig
end

"""
    plot_model_tc!(ax, cf=2000.0, fiber_type="high")

Simulate and plot-in-place iso-level tuning curve for AN model with specified parameters
"""
function plot_model_tc!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = IsolevelTC(model, 30.0, cf * 2^-0.5, cf * 2^0.5, 40)
    out = @memo Default() simulate(sim)
    scatter!(ax, log2.(axis(sim)./cf), out; color=:black)
    lines!(ax, log2.(axis(sim)./cf), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    plot_model_tc!(ax, modeltype=InferiorColliculusSFIEBE, param=StandardBE)

Simulate and plot-in-place iso-level tuning curve for IC model with specified parameters
"""
function plot_model_tc!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = IsolevelTC(model, 30.0, cf * 2^-0.5, cf * 2^0.5, 40)
    out = @memo Default() simulate(sim)
    scatter!(ax, log2.(axis(sim)./cf), out; color=:black)
    lines!(ax, log2.(axis(sim)./cf), quicksmooth(out); color=:black)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    genfig_sim_methods_mtfs()

Plot noise modulation transfer functions (MTFs) for each tested auditory model

Simulate and plot MTFs for HSR/LSR/BE/BS models at a nominal CF of 2 kHz using Guassian
noise modulated at a modulation depth of 0 dB using a sinusoidal modulator. Sound level of 
the noise is in dB SPL spectrum level and is 20 dB SPL. Is a subfigure of Figure 4. 
Uses free y-axes to accomodate wide variation in discharge rate between models.
"""
function genfig_sim_methods_mtfs()
    # Set theme and other visual features
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

    # Create figure and axes for each MTF
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]; xscale=log10, xticks=(2 .^ (1:2:9), string.(2 .^ (1:2:9))), xminorticksvisible=false) for i in 1:4]

    # Do each individual plot
    plot_model_mtf!(axs[1], 2000.0, "high")
    plot_model_mtf!(axs[2], 2000.0, "low")
    plot_model_mtf!(axs[3], 2000.0, InferiorColliculusSFIEBE, StandardBE)
    plot_model_mtf!(axs[4], 2000.0, InferiorColliculusSFIEBS, StandardBS)

    # Add labels
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 2:3], "Modulation frequency (Hz)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    fig
end

"""
    plot_model_mtf!(ax, cf=2000.0, fiber_type="high")

Simulate and plot-in-place noise MTFs for AN model with specified parameters
"""
function plot_model_mtf!(ax, cf=2000.0, fiber_type::String="high"; color=:black, kwargs...)
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf], n_fiber=10)

    # Simulate responses and plot
    sim = ToneMTF(model, 4.0, 512.0, 31; l=40.0, dur=1.0, f=cf)
    # sim = NoiseMTF(model, 4.0, 512.0, 31; l=10.0, dur=1.0)
    out = @memo Default(; resolve_codename=true, codename="october") simulate(sim)
    ax = plot_mtf!(ax, axis(sim), out, zeros(size(out)); color=color, kwargs...)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    plot_model_mtf!(ax, modeltype=InferiorColliculusSFIEBE, param=StandardBE)

Simulate and plot-in-place noise MTFs for IC model with specified parameters
"""
function plot_model_mtf!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE; color=:black, normfunc=identity, kwargs...)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf], n_fiber=10)
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = ToneMTF(model, 4.0, 512.0, 31; l=40.0, dur=1.0, f=cf)
    # sim = NoiseMTF(model, 4.0, 512.0, 31; l=10.0, dur=1.0)
    out = @memo Default(; resolve_codename=true, codename="october") simulate(sim)
    ax = plot_mtf!(ax, axis(sim), normfunc(out), zeros(size(out)); color=color, kwargs...)
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    genfig_sim_methods_mtf_filterbank()

Plot noise modulation transfer functions (MTFs) for each supplementary IC cell 

Simulate and plot MTFs for supplemental IC cells at a nominal CF of 2 kHz using Guassian
noise modulated at a modulation depth of 0 dB using a sinusoidal modulator. Sound level of 
the noise is in dB SPL spectrum level and is 20 dB SPL. 
"""
function genfig_sim_methods_mtf_filterbank()
    # Set theme and other visual features
    set_theme!(theme_carney; fontsize=10.0, Scatter=(markersize=3.0, ))

    # Create figure and axes for each MTF
    #fig = Figure(; resolution=(350, 200))
    fig = Figure(; resolution=(700, 400))
    axs = [Axis(fig[1, i]; xscale=log10, xticks=(2 .^ (1:2:9), string.(2 .^ (1:2:9))), xminorticksvisible=false) for i in 1:2]

    # Do each individual plot
    plot_model_mtf!(axs[1], 2000.0, InferiorColliculusSFIEBE, LowBE; color=:red, label_bmf=true, normfunc=x -> x ./ maximum(x))
    plot_model_mtf!(axs[1], 2000.0, InferiorColliculusSFIEBE, StandardBE; color=:blue, label_bmf=true, normfunc=x-> x ./ maximum(x))
    plot_model_mtf!(axs[1], 2000.0, InferiorColliculusSFIEBE, HighBE; color=:green, label_bmf=true, normfunc=x -> x ./ maximum(x))
    ylims!(axs[1], 0.0, 1.5)

    # Do each individual plot
    plot_model_mtf!(axs[2], 2000.0, InferiorColliculusSFIEBS, LowBS; color=:red, label_wmf=true, normfunc=x -> x ./ minimum(x))
    plot_model_mtf!(axs[2], 2000.0, InferiorColliculusSFIEBS, StandardBS; color=:blue, label_wmf=true, normfunc=x -> x ./ minimum(x))
    plot_model_mtf!(axs[2], 2000.0, InferiorColliculusSFIEBS, HighBS; color=:green, label_wmf=true, normfunc=x -> x ./ minimum(x))
    ylims!(axs[2], 0.0, 5.0)

    # Add labels
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 1:end], "Modulation frequency (Hz)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))
    fig
end

"""
    genfig_sim_methods_example_responses()

Plot example profile-analysis token response for each tested auditory model

Simulate and plot average population response for HSR/LSR/BE/BS models across a range of CFs
to a 21-component 2-kHz profile-analysis tone with an increment of -10 dB SRS. A reference
response is plotted in black, while a target response is plotted in red. Is a subfigure of
Figure 4. Uses free y-axes to accomodate wide variation in discharge rate between models.
"""
function genfig_sim_methods_example_responses()
    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Add vertical lines at component frequencies
    freqs = LogRange(1000.0/5, 1000.0*5, 21)  # for 1 kHz 21 components
    [vlines!(ax, log2.(freqs ./ 1000.0); color=(:gray, 0.2)) for ax in axs]

    # Do each plot
    example_plot_pair!(axs[1], example_prep_sims(-10.0, "high")...; color=:black)
    example_plot_pair!(axs[2], example_prep_sims(-10.0, "low")...; color=:black)
    example_plot_pair!(axs[3], example_prep_sims(-10.0, InferiorColliculusSFIEBE, StandardBE)...; color=:black)
    example_plot_pair!(axs[4], example_prep_sims(-10.0, InferiorColliculusSFIEBS, StandardBS)...; color=:black)

    # Adjust
    xlims!.(axs, -0.55, 0.55)
    [ax.xticks = [-0.5, 0.0, 0.5] for ax in axs]
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 2:3], "CF (oct re: target frequency)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

"""
    example_prep_model(fiber_type, center_freq)

Prepare a Model object for an AN model with the specified parameters
"""
function example_prep_model(fiber_type::String; center_freq=1000.0)
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    return model
end

"""
    example_prep_model(modeltype, params)

Prepare a Model object for an IC model with the specified parameters
"""
function example_prep_model(modeltype::DataType, params::Dict; center_freq=1000.0)
    frontend = AuditoryNerveZBC2014(; cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    model = modeltype(; frontend=frontend, params...)
    return model
end

"""
    example_prep_sims(modeltype, params)

Prepare and evaluate simulation objects that perform the simulations described above
"""
function example_prep_sims(increment, args...; center_freq=1000.0, n_comp=21)
    # Get model
    model = example_prep_model(args...; center_freq=center_freq)

    # Make stimuli
    stim_ref = ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf)
    stim_tar = ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=increment)

    # Generate resposnes
    sim_ref = Response(stim_ref, model)
    out_ref = @memo Default() run(sim_ref)

    sim_tar = Response(stim_tar, model)
    out_tar = @memo Default() run(sim_tar)

    # Return
    log2.(model.cf ./ center_freq), map(mean, out_ref), map(mean, out_tar)
end

"""
    example_plot_pair!(ax, cf, r, t)

Plot in-place two population average-rate curves (r and t)
"""
function example_plot_pair!(ax, cf, r, t; color=:black)
    lines!(ax, cf, r; color=color, linestyle=:solid)
    lines!(ax, cf, t; color=:red, linestyle=:dot)
    ylims!(ax, 0.0, 1.25 * max(maximum(r), maximum(t)))
end

