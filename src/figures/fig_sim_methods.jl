export genfig_sim_methods_rlfs,
       genfig_sim_methods_tcs,
       genfig_sim_methods_mtfs,
       genfig_sim_methods_example_responses

"""
    genfig_sim_methods_rlfs()

Plot rate-level functions for each tested auditory model
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

Plot noise MTFs for each tested auditory model
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

function plot_model_mtf!(ax, cf=2000.0, fiber_type::String="high")
    # Handle model
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, fractional=false, cf=[cf])

    # Simulate responses and plot
    sim = NoiseMTF(model, 8.0, 512.0, 31; l=20.0)
    out = @memo Default() simulate(sim)
    ax = plot_mtf!(ax, axis(sim), out, zeros(size(out)))
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

function plot_model_mtf!(ax, cf=2000.0, modeltype::DataType=InferiorColliculusSFIEBE, param::Dict=StandardBE)
    # Handle model
    frontend = AuditoryNerveZBC2014(; fiber_type="high", fractional=false, cf=[cf])
    model = modeltype(; frontend=frontend, param...)

    # Simulate responses and plot
    sim = NoiseMTF(model, 8.0, 512.0, 31; l=20.0)
    out = @memo Default() simulate(sim)
    ax = plot_mtf!(ax, axis(sim), out, zeros(size(out)); color=parse(RGBA, :black))
    ylims!(ax, 0.0, 1.25 * maximum(out))

    # Return
    ax 
end

"""
    genfig_sim_methods_example_responses

Plot example responses for a profile-analysis tone for each tested auditory model
"""
function genfig_sim_methods_example_responses()
    # Set up plot
    set_theme!(theme_carney; fontsize=10.0)
    fig = Figure(; resolution=(400, 125))
    axs = [Axis(fig[1, i]) for i in 1:4]

    # Do each plot
    _plot_pair!(axs[1], _prep_sims(-10.0, "high")...; color=:black)
    _plot_pair!(axs[2], _prep_sims(-10.0, "low")...; color=:black)
    _plot_pair!(axs[3], _prep_sims(-10.0, InferiorColliculusSFIEBE, StandardBE)...; color=:black)
    _plot_pair!(axs[4], _prep_sims(-10.0, InferiorColliculusSFIEBS, StandardBS)...; color=:black)

    # Adjust
    axs[1].ylabel = "Firing rate (sp/s)"
    Label(fig[2, 2:3], "CF (oct re: target frequency)"; tellwidth=false)
    rowgap!(fig.layout, 1, Relative(0.03))
    colgap!(fig.layout, Relative(0.02))

    # Render and save
    fig
end

function _prep_model(fiber_type::String; center_freq=1000.0)
    model = AuditoryNerveZBC2014(; fiber_type=fiber_type, cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    return model
end

function _prep_model(modeltype::DataType, params::Dict; center_freq=1000.0)
    frontend = AuditoryNerveZBC2014(; cf=LogRange(center_freq/2, center_freq*2, 91), fractional=false)
    model = modeltype(; frontend=frontend, params...)
    return model
end

function _prep_sims(increment, args...; center_freq=1000.0, n_comp=21)
    # Get model
    model = _prep_model(args...; center_freq=center_freq)

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

function _plot_pair!(ax, cf, r, t; color=:black)
    lines!(ax, cf, r; color=color)
    lines!(ax, cf, t; color=:red)
    ylims!(ax, 0.0, 1.25 * max(maximum(r), maximum(t)))
end

