# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 1 // beh_1kHz
# Behavior at 1 kHz
#
# Shows group-average psychometric functions for each HL group w/ and w/o a level rove in 
# 1-kHz condition. Also shows the "bowl" for the 1-kHz condition for each group w/ and w/o
# a level rove and the "rove effect" in dB for the 1-kHz condition for each group.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate psychometric functions
fig = genfig_beh_1kHz_psychometric_functions()
save(projectdir("plots", "beh_1kHz", "01_psychometric_functions.svg"), fig)

# Generate bowls
fig = genfig_beh_1kHz_bowls()
save(projectdir("plots", "beh_1kHz", "02_bowls.svg"), fig)

# Generate "rove effect" plot
fig = genfig_beh_1kHz_rove_effects()
save(projectdir("plots", "beh_1kHz", "03_rove_effects.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 2 // beh_frequency
# Behavior at all frequencies, unroved only
#
# Shows group-average psychometric functions at all target frequencies for fixed-level 
# conditions in each HL group. Also shows thresholds as a function of target frequency for 
# each HL group in each component-count condition.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate psychometric functions
fig = genfig_beh_frequency_psychometric_functions()
save(projectdir("plots", "beh_frequency", "01_psychometric_functions.svg"), fig)

# Generate "frequency" bowls
fig = genfig_beh_frequency_bowls()
save(projectdir("plots", "beh_frequency", "02_bowls.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 3 // beh_hearing_loss
# Behavioral data analyzed as a function of degree of hearing loss
#
# Shows behavioral thresholds as a function of audiometric threshold at the target frequency 
# for fixed-level data in each target-frequency and component-count condition.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate correlations with hearing loss
fig = genfig_beh_hearing_loss()
save(projectdir("plots", "beh_hearing_loss", "01_hearing_loss.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 4 // sim_methods
# Modeling methods figures
#
# Summary of modeling methods, depicting on top a flow diagram of the various stages of the 
# computational model and on bottom rate-level functions, iso-level tuning curves, MTFs, and
# example profile-analysis responses for each tested model stage.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate rate-level functions
fig = genfig_sim_methods_rlfs()
save(projectdir("plots", "sim_methods", "02_rlfs.svg"), fig)

# Generate tuning curves
fig = genfig_sim_methods_tcs()
save(projectdir("plots", "sim_methods", "03_tcs.svg"), fig)

# Generate MTFs
fig = genfig_sim_methods_mtfs()
save(projectdir("plots", "sim_methods", "04_mtfs.svg"), fig)

# Generate example profile-analysis responses
fig = genfig_sim_methods_example_responses()
save(projectdir("plots", "sim_methods", "05_example_responses.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 5 // sim_psychometric_functions
# Modeling detailed example results figure
#
# Shows "delta" / increment responses for each model on top, and deltas / distances for 
# each observer strategy and model stage + example psychometric functions for each observer 
# strategy and model stage on bottom
# 
# TODO:
# - Add docstrings to functions, clean up
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate population responses to a level increment
fig = genfig_sim_psychometric_functions_profiles()
save(projectdir("plots", "sim_psychometric_functions", "01_profiles.svg"), fig)

# Generate "rate curve" plots based on each decoding strategy
fig = genfig_sim_psychometric_functions_rate_curves("singlechannel")
save(projectdir("plots", "sim_psychometric_functions", "02_rate_curves_singlechannel.svg"), fig)

fig = genfig_sim_psychometric_functions_rate_curves("profilechannel")
save(projectdir("plots", "sim_psychometric_functions", "03_rate_curves_profilechannel.svg"), fig)

fig = genfig_sim_psychometric_functions_rate_curves("templatebased")
save(projectdir("plots", "sim_psychometric_functions", "04_rate_curves_templatebased.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 6 // sim_bowls
# Modeling results overview figure
# 
# Shows model thresholds vs behavioral thresholds for each condition for single-channel
# and template-based models in the LSR, BE, and BS model stages on top, and on bottom 
# average behavior vs model thresholds as a function of frequency and correlations between 
# behavior and model thresholds.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create main bowl figure
fig = genfig_sim_bowls_density_and_frequency_bowls_simple()
save(projectdir("plots", "sim_bowls", "01_density_and_frequency_bowls_simple.svg"), fig)

# Create summary showing patterns w.r.t. frequency for NH versus model
fig = genfig_sim_bowls_frequency_summary()
save(projectdir("plots", "sim_bowls", "02_density_and_frequency_summary.svg"), fig)

# Create summary showing correlations between model and simulated responses
fig = genfig_sim_bowls_modelbehavior_correlations()
save(projectdir("plots", "sim_bowls", "03_density_and_modelbehavior_correlations.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 7 // sim_bowls
# LSR results follow-up simulations
# 
# Shows the "pure-tone control" LSR simulations, comparisons of sound level vs LSR rate
# distributions, rate-level functions for the LSR model w/ and w/o flankers, and "increment
# enhancement" measurements as a function of flanker level and spacing. For historical 
# reasons, this figure is geneated as if it were a supplemental figure to Figure 6.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate pure-tone control figure 
fig = genfig_sim_bowls_puretonecontrol_LSR_only()
save(projectdir("plots", "sim_bowls", "s02_pure_tone_control.svg"), fig)

# Generate "stackplots" of target level distributions vs LSR rate distributions
fig = genfig_followup_puretonecontrol()
save(projectdir("plots", "sim_bowls", "s02_pure_tone_control_stackplots.svg"), fig)

# LSR pure-tone control mechanism followup
fig = genfig_puretonecontrol_mechanism()
save(projectdir("plots", "sim_bowls", "s02_pure_tone_control_flankers.svg"), fig)

# LSR pure-tone control RL function followup
fig = genfig_puretonecontrol_rl_functions()
save(projectdir("plots", "sim_bowls", "s02_pure_tone_control_rl_functions.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 7 // sim_hi
# Hearing-impaired simulations figure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_audiograms_and_cohc()
save(projectdir("plots", "sim_hi", "01_audiograms_and_cohc_cihc.svg"), fig)

fig = __genfig_sim_hi_cohc_correlations()
save(projectdir("plots", "sim_hi", "s01_hi_sim_cohc_correlations.svg"), fig)

fig = __genfig_sim_hi_behavior_correlations()
save(projectdir("plots", "sim_hi", "s02_hi_sim_correlations.svg"), fig)