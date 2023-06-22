# Provide definitions and functionality for "ProfileAnalysis_PF", an experiment
# subtype for generating psychometric function objects for profile-analysis experiments

# Handle exports
export ProfileAnalysis_PF, ProfileAnalysis_PFTemplateObserver, ProfileAnalysis_PFObserver,
       obs_dec_rate_at_tf, obs_inc_rate_at_tf, pre_emphasize_profile, getpffunc

# Declare experiment types
abstract type ProfileAnalysis_PF <: ProfileAnalysisExperiment end
struct ProfileAnalysis_PFTemplateObserver <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFObserver <: ProfileAnalysis_PF end

# Declare setup function to set up entire experiment for batch run
function Utilities.setup(experiment::ProfileAnalysis_PFTemplateObserver)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 9, 13, 17, 21, 25, 29, 33, 37]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = Utilities.setup(experiment, center_freq)

        # Loop over models and assemble PFs
        map(models) do model
            Utilities.setup(experiment, model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end

# Declare setup function to return PF for combination of model, increments, center_freq, and n_comp
function Utilities.setup(
    ::ProfileAnalysis_PFTemplateObserver, 
    model::Model, 
    increments=[-20.0, -10.0, 0.0], 
    center_freq::Float64=1000.0, 
    n_comp::Int64=21,
    rove_size::Float64=0.001,
)
    # Get template
    template = Utilities.setup(ProfileAnalysis_Templates(), model, center_freq, n_comp, rove_size)

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

# Declare setup function to return PF for combination of model, increments, center_freq, and n_comp
function Utilities.setup(
    ::ProfileAnalysis_PFObserver, 
    model::Model, 
    increments=[-20.0, -10.0, 0.0], 
    center_freq::Float64=1000.0, 
    n_comp::Int64=21,
    rove_size::Float64=0.001;
    preprocessor=Utilities.pre_nothing,
    observer=obs_maxrate,
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
function Utilities.viz!(::ProfileAnalysis_PF, ax, x, μ, σ, mod)
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
        pffunc = (args...) -> Utilities.setup(exp, args...; observer=obs)
    elseif mode == "profilechannel"
        obs = typeof(model) == InferiorColliculusSFIEBE ? obs_dec_rate_at_tf : obs_inc_rate_at_tf
        pffunc = (args...) -> Utilities.setup(exp, args...; observer=obs, preprocessor=pre_emphasize_profile)
    elseif mode == "templatebased"
        pffunc = (args...) -> Utilities.setup(exp, args...)
    end
    return pffunc
end

