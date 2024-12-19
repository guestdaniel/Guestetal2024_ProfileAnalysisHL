# Provide definitions and functionality for "ProfileAnalysis_PF", an experiment
# subtype for generating psychometric function objects for profile-analysis experiments

# Handle exports
export ProfileAnalysis_PF, 
       ProfileAnalysis_PFTemplateObserver, 
       ProfileAnalysis_PFTemplateObserver_Reduced,
       ProfileAnalysis_PFTemplateObserver_Extended,
       ProfileAnalysis_PFObserver,
       ProfileAnalysis_PFTemplateObserver_HearingImpaired,
       ProfileAnalysis_PFTemplateObserver_PureToneControl,
       ProfileAnalysis_PFTemplateObserver_WidebandControl,
       obs_dec_rate_at_tf, obs_inc_rate_at_tf, pre_emphasize_profile, getpffunc

# Declare experiment types
abstract type ProfileAnalysis_PF <: ProfileAnalysisExperiment end
struct ProfileAnalysis_PFTemplateObserver <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_Reduced <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_Extended <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_PureToneControl <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_WidebandControl <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_HearingImpaired <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFObserver <: ProfileAnalysis_PF end

"""
    setup(::ProfileAnalysis_PFTemplateObserver)

Set up all template-based psychometric function simulations.

Set up all template-based psychometric function simulations, over the full range of
simulated parameter values:
    - Center frequencies of 0.5-4 kHz
    - Component counts from 5-37
    - Rove sizes from 0.001 (nominal 0) to 10 dB
    - Increments from -45 to 5 dB SRS

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 13, 21, 29, 37]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = setup(experiment, center_freq)

        # Loop over models and assemble PFs
        map(models) do model
            setup(experiment, model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end

"""
    setup(::ProfileAnalysis_PFTemplateObserver)

Set up all template-based psychometric function simulations (reduced resolution matching HI sims)

Set up all template-based psychometric function simulations, over the full range of
simulated parameter values:
    - Center frequencies of 0.5-4 kHz
    - Component counts from 5-37
    - Rove sizes from 0.001 (nominal 0) to 10 dB
    - Increments from -45 to 5 dB SRS

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver_Reduced)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [1000.0, 2000.0]
    n_comps = [5, 13, 21, 29, 37]
    rove_sizes = [0.001]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = setup(experiment, center_freq; n_cf=n_cf_reduced)

        # Loop over models and assemble PFs
        map(models) do model
            setup(
                ProfileAnalysis_PFTemplateObserver(), 
                model, 
                increments, 
                center_freq, 
                n_comp, 
                rove_size;
                n_rep_template=n_rep_template_reduced,
                n_rep_trial=n_rep_trial_reduced,
            )
        end
    end

    vcat(sims...)
end


"""
    setup(::ProfileAnalysis_PFTemplateObserver_Extended)

Set up all template-based psychometric function simulations for "extended" model grop.

Set up all template-based psychometric function simulations, over the full range of
simulated parameter values:
    - Center frequencies of 0.5-4 kHz
    - Component counts from 5-37
    - Rove sizes from 0.001 (nominal 0) to 10 dB
    - Increments from -45 to 5 dB SRS

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver_Extended)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 13, 21, 29, 37]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = setup_extended(experiment, center_freq)

        # Loop over models and assemble PFs
        map(models) do model
            setup(ProfileAnalysis_PFTemplateObserver(), model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end

"""
    setup(::ProfileAnalysis_PFTemplateObserver_PureToneControl)

Set up pure-tone control template-based psychometric function simulations.

Set up all template-based psychometric function simulations where we simulate pure-tone
responses instead of profile-analysis stimuli. We do this over the following parameter
ranges: 
    - Center frequencies of 0.5-4 kHz 
    - Rove sizes from 0.001 (nominal 0) to 10 dB 
    - Increments from -45 to 5 dB SRS

The use of pure tones is a handy control for evaluating the overall consequences of having
flanker tones in the stimulus (including, most relevantly, possible contributions of
two-tone suppression and similar phenomena).

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver_PureToneControl)
    # Choose superexperiment (should be handled with subtyping but oh well)
    supexp = ProfileAnalysis_PFTemplateObserver()

    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [1]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = setup(experiment, center_freq)

        # Loop over models and assemble PFs
        map(models) do model
            setup(supexp, model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end


"""
    setup(::ProfileAnalysis_PFTemplateObserver_WidebandControl)

Set up template-based psychometric function wideband control simulations.

Set up control simulations for template-based psychometric functions. This control
simulation spans a wider frequency range of (2^-2.5, 2^2.5) octaves around the center
frequency, rather than the normal more limited range of (1/2, 2) times the center frequency.
Currently, this function only generates a reduced range of simulations over the parameter
values of:
    - Center frequencies of 0.5-4 kHz
    - [!!!] Component count of 5
    - Rove sizes from 0.001 (nominal 0) to 10 dB
    - Increments from -45 to 5 dB SRS

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver_WidebandControl)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = setup(experiment, center_freq, [2^-2.5, 2^2.5])

        # Loop over models and assemble PFs
        map(models) do model
            setup(experiment, model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end

"""
    setup(::ProfileAnalysis_PFTemplateObserver_HearingImpaired)

Set up template-based psychometric function hearing-impaired simulations.

Set up simulations for template-based psychometric functions with hearing loss. Subject
audiograms are gathered, and a model + set of PFs is generated for each. Otherwise,
simulations are generated for the following parameter ranges: 
    - [!!!] Center frequencies of 1 and 2 kHz (behaviorally relevant ranges)
    - Component counts from 5-37
    - [!!!] Rove size of from 0.001 (nominal 0) dB SRS
    - Increments from -45 to 5 dB SRS

Note that these simulations are generated with the "reduced" model/sim parameter values to 
make each faster to simulate (lower numbers of reps, smaller increment range, fewer CFs, etc.)

Returns a vector of simulation objects that can be evaluted with `simulate`.
"""
function setup(experiment::ProfileAnalysis_PFTemplateObserver_HearingImpaired)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [1000.0, 2000.0]
    n_comps = [5, 13, 21, 29, 37]
    rove_sizes = [0.001]

    # Configure other values
    increments=-30.0:2.5:5.0
    audiograms = fetch_audiograms()

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes, audiograms)) do (center_freq, n_comp, rove_size, audiogram)
        # Get possible models
        models = setup_nohsr(experiment, center_freq, cf_range, audiogram; n_cf=n_cf_reduced)

        # Loop over models and assemble PFs
        map(models) do model
            setup(
                ProfileAnalysis_PFTemplateObserver(), 
                model, 
                increments, 
                center_freq, 
                n_comp, 
                rove_size;
                n_rep_template=n_rep_template_reduced,
                n_rep_trial=n_rep_trial_reduced,
            )
        end
    end

    vcat(vcat(sims...)...)
end

"""
    setup(::ProfileAnalysis_PFTemplateObserver, model, increments, center_freq, n_comp, rove_size)

Set up a psychometric function simulation object for specified model/params.

Creates AvgPatterns to simulate reference and target responses and bundles them into a PF
object for simulation. This variant specifically uses a template-based observer.
"""
function setup(
    ::ProfileAnalysis_PFTemplateObserver, 
    model::Model, 
    increments=[-20.0, -10.0, 0.0], 
    center_freq::Float64=1000.0, 
    n_comp::Int64=21,
    rove_size::Float64=0.001;
    n_rep_trial=n_rep_trial,
    n_rep_template=n_rep_template,
)
    # Get template
    template = setup(
        ProfileAnalysis_Templates(), 
        model, 
        center_freq, 
        n_comp, 
        rove_size; 
        n_rep_template=n_rep_template,
    )

    # Make stimuli and bind with model into vector of DeltaPatterns
    patterns = map(increments) do increment
        # Make stimuli
        stim_ref = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=-Inf), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size)
        )
        stim_tar = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=increment), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size)
        )
        # Construct a string to disambiguate different repeats of -Inf dB SRS
        tag = "matched_to_$(id(stim_tar[1]))"

        # Bundle into tuple of AvgPatterns
        ( 
            AvgPattern(; stimuli=stim_ref, model=model, tag=tag),
            AvgPattern(; stimuli=stim_tar, model=model),
        )
    end

    # Generate psychometric function and run
    sim = PFTemplateObserver(; 
        template=template, 
        patterns=patterns, 
        model=model,
        θ=:increment,
        θ_low=increments[1],
        θ_high=increments[end],
    )

    # Return
    sim
end

"""
    setup(::ProfileAnalysis_PFObserver, model, increments, center_freq, n_comp, rove_size)

Set up a psychometric function simulation object for specified model/params.

Creates AvgPatterns to simulate reference and target responses and bundles them into a PF
object for simulation. This variant specifically uses a template-free observer.
"""
function setup(
    ::ProfileAnalysis_PFObserver, 
    model::Model, 
    increments=[-20.0, -10.0, 0.0], 
    center_freq::Float64=1000.0, 
    n_comp::Int64=21,
    rove_size::Float64=0.001;
    preprocessor=pre_nothing,
    observer=obs_maxrate,
    n_rep_trial=n_rep_trial,
)
    # Make stimuli and bind with model into vector of DeltaPatterns
    patterns = map(increments) do increment
        # Make stimuli
        stim_ref = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=-Inf), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size),
        )
        stim_tar = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, pedestal_level=70.0, increment=increment), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(70.0 - rove_size, 70.0 + rove_size),
        )
        
        # Construct a string to disambiguate different repeats of -Inf dB SRS
        tag = "matched_to_$(id(stim_tar[1]))"

        # Combine into tuple
        ( 
            AvgPattern(; stimuli=stim_ref, model=model, tag=tag),
            AvgPattern(; stimuli=stim_tar, model=model),
        )
    end

    # Generate psychometric function and run
    sim = PFObserver(; 
        patterns=patterns, 
        model=model,
        observer=observer,
        preprocessor=preprocessor,
        θ=:increment,
        θ_low=increments[1],
        θ_high=increments[end],
    )

    # Return
    sim
end

# Declare functions used by PFs above (e.g., observer rules, preprocessing rules)
function obs_inc_rate_at_tf(x1::Vector, x2::Vector)
    idx = Int(round(length(x1)/2))
    x2[idx] > x1[idx] ? 2 : 1
end

function obs_dec_rate_at_tf(x1::Vector, x2::Vector)
    idx = Int(round(length(x1)/2))
    x2[idx] < x1[idx] ? 2 : 1
end

function pre_emphasize_profile(x::Tuple)
    map(x) do sequence
        map(sequence) do resp
            resp = resp .- mean(resp)
        end
    end
end

# Declare function useful for plotting PFs
function viz!(::ProfileAnalysis_PF, ax, x, μ, σ, mod)
    # Extract threshold from curve fit
    threshold = invlogistic(0.71, mod.param; L=0.5, offset=0.5)

    # Add vline and label indicating position of threshold
    vlines!(ax, [threshold]; color=:red)

    # Plot interpolated curve fit
    x̂ = -40.0:0.1:10.0
    lines!(ax, x̂, logistic_predict(x̂, (mod.param)...); color=:gray)

    # Plot data with errorbars
    scatter!(ax, x, μ; color=:black)
    errorbars!(ax, x, μ, 1.96 .* σ; color=:black)

    # Add threshold text
    if threshold < -15.0
        text!(ax, [threshold + 2.0], [1.03]; text=string(Int(round(threshold))), color=:red, align=(:left, :bottom))
    else
        text!(ax, [threshold - 2.0], [1.03]; text=string(Int(round(threshold))), color=:red, align=(:right, :bottom))
    end

    # Set limits and such
    xlims!(ax, -40.0, 10.0)
    ylims!(ax, 0.40, 1.15)

end

function getpffunc(mode, model, exp)
    if mode == "singlechannel"
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pffunc = (args...; kwargs...) -> setup(exp, args...; observer=obs, kwargs...)
    elseif mode == "profilechannel"
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pffunc = (args...; kwargs...) -> setup(exp, args...; observer=obs, preprocessor=pre_emphasize_profile, kwargs...)
    elseif mode == "templatebased"
        pffunc = (args...; kwargs...) -> setup(exp, args...; kwargs...)
    end
    return pffunc
end

