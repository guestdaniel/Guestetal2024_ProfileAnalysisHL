# Provide definitions and functionality for "ProfileAnalysis_PF", an experiment
# subtype for generating psychometric function objects for profile-analysis experiments

# Handle exports
export ProfileAnalysis_PF, ProfileAnalysis_PFTemplateObserver, ProfileAnalysis_PFObserver,
       obs_dec_rate_at_tf, obs_inc_rate_at_tf, pre_emphasize_profile

# Declare experiment types
abstract type ProfileAnalysis_PF <: ProfileAnalysisExperiment end
struct ProfileAnalysis_PFTemplateObserver <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFObserver <: ProfileAnalysis_PF end

# Declare setup function to return PF for combination of model, increments, center_freq, and n_comp
function Utilities.setup(
    ::ProfileAnalysis_PFTemplateObserver, 
    model::Model, 
    increments=[-20.0, -10.0, 0.0], 
    center_freq::Float64=1000.0, 
    n_comp::Int64=21
)
    # Get template
    template = Utilities.setup(ProfileAnalysis_Templates(), model, center_freq, n_comp)

    # Make stimuli and bind with model into vector of DeltaPatterns
    patterns = map(increments) do increment
        # Make stimuli
        stim_ref = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(60.0, 80.0)
        )
        stim_tar = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=increment), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(60.0, 80.0)
        )
        ( 
            AvgPattern(; stimuli=stim_ref, model=model),
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
    n_comp::Int64=21;
    preprocessor=Utilities.pre_nothing,
    observer=obs_maxrate,
)
    # Make stimuli and bind with model into vector of DeltaPatterns
    patterns = map(increments) do increment
        # Make stimuli
        stim_ref = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=-Inf), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(60.0, 80.0)
        )
        stim_tar = RovedStimulus(
            ProfileAnalysisTone(; n_comp=n_comp, center_freq=center_freq, increment=increment), 
            n_rep_trial; 
            rove_params=[:pedestal_level], 
            rove_dist=Uniform(60.0, 80.0)
        )
        ( 
            AvgPattern(; stimuli=stim_ref, model=model),
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
    idx = Int(round(length(v1)/2))
    x2[idx] > x1[idx] ? 2 : 1
end

function obs_dec_rate_at_tf(x1::Vector, x2::Vector)
    idx = Int(round(length(v1)/2))
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

    # Plot data with errorbars
    scatter!(ax, x, μ; color=:black)
    errorbars!(ax, x, μ, 1.96 .* σ; color=:black)

    # Plot interpolated curve fit
    x̂ = -30.0:0.1:20.0
    lines!(ax, x̂, logistic_predict(x̂, (mod.param)...))

    # Add threshold text
    if threshold < -15.0
        text!(ax, [threshold + 2.0], [1.03]; text=string(round(threshold)), color=:red, align=(:left, :bottom))
    else
        text!(ax, [threshold - 2.0], [1.03]; text=string(round(threshold)), color=:red, align=(:right, :bottom))
    end

    # Set limits and such
    xlims!(ax, -40.0, 10.0)
    ylims!(ax, 0.40, 1.15)

end