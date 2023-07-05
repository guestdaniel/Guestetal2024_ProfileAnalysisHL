# Provide definitions and functionality for "ProfileAnalysis_PF", an experiment
# subtype for generating psychometric function objects for profile-analysis experiments

# Handle exports
export ProfileAnalysis_PF, ProfileAnalysis_PFTemplateObserver, ProfileAnalysis_PFObserver,
       ProfileAnalysis_PFTemplateObserver_HearingImpaired,
       obs_dec_rate_at_tf, obs_inc_rate_at_tf, pre_emphasize_profile, getpffunc

# Declare experiment types
abstract type ProfileAnalysis_PF <: ProfileAnalysisExperiment end
struct ProfileAnalysis_PFTemplateObserver <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_ControlConditions <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFTemplateObserver_HearingImpaired <: ProfileAnalysis_PF end
struct ProfileAnalysis_PFObserver <: ProfileAnalysis_PF end

# Declare setup function to set up entire experiment for batch run
function Utilities.setup(experiment::ProfileAnalysis_PFTemplateObserver)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5, 13, 21, 29, 37]
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

# Declare setup functon to set up control conditions for batch run. This control experiment
# tests the 5-component condition with a larger frequency range [2^-2.5, 2^2.5] to capture
# the full ~4.6 octave bandwidth around the target frequency
function Utilities.setup(experiment::ProfileAnalysis_PFTemplateObserver_ControlConditions)
    # Choose frequencies, component counts, and rove sizes to loop over
    center_freqs = [500.0, 1000.0, 2000.0, 4000.0]
    n_comps = [5]
    rove_sizes = [0.001, 10.0]

    # Configure other values
    increments=vcat(-999.9, -45.0:2.5:5.0)

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes)) do (center_freq, n_comp, rove_size)
        # Get possible models
        models = Utilities.setup(experiment, center_freq, [2^-2.5, 2^2.5])

        # Loop over models and assemble PFs
        map(models) do model
            Utilities.setup(experiment, model, increments, center_freq, n_comp, rove_size)
        end
    end

    vcat(sims...)
end

# Declare setup functon to setup hearing impaired simulations
function Utilities.setup(experiment::ProfileAnalysis_PFTemplateObserver_HearingImpaired)
    # Choose frequencies, component counts, and rove sizes to loop over
#    center_freqs = [1000.0, 2000.0, 4000.0]
    center_freqs = [1000.0, 2000.0]
    n_comps = [5, 13, 21, 29, 37]
#    rove_sizes = [0.001, 10.0]
    rove_sizes = [0.001]

    # Configure other values
    increments=-30.0:2.5:5.0

    # Load behavioral data and fetch list of unique subject IDs
    subjs = unique(fetch_behavioral_data().subj)

    # Load audiograms, grab only needed rows, and transform into Audiogram objects
    if (Sys.KERNEL == :Linux)
        audiograms = DataFrame(CSV.File("/home/dguest2/thresholds_2022-07-18.csv"))
    else
        audiograms = DataFrame(CSV.File("C:\\Users\\dguest2\\cl_data\\pahi\\raw\\thresholds_2022-07-18.csv"))
    end
    audiograms[audiograms.Subject .== "S98", :Subject] .= "S098"
    audiograms = @subset(audiograms, in.(:Subject, Ref(subjs)))
    audiograms = map(subjs) do subj
        # Subset row
        row = audiograms[audiograms.Subject .== subj, :]

        # Select frequencies and thresholds
        f = [250.0, 500.0, 1000.0, 1500.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]
        θ = Vector(row[1, 4:12])

        # Combine into Audiogram objects
        Audiogram(; freqs=f, thresholds=θ, species="human", desc=subj)
    end

    # Get simulations
    sims = map(Iterators.product(center_freqs, n_comps, rove_sizes, audiograms)) do (center_freq, n_comp, rove_size, audiogram)
        # Get possible models
        models = setup_nohsr(experiment, center_freq, cf_range, audiogram; n_cf=n_cf_reduced)

        # Loop over models and assemble PFs
        map(models) do model
            Utilities.setup(
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

# Declare setup function to return PF for combination of model, increments, center_freq, and n_comp
function Utilities.setup(
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
    template = Utilities.setup(
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

