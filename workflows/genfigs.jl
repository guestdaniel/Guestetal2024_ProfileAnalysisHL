# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 1 // beh_1kHz
# Behavior at 1 kHz
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_beh_1kHz_psychometric_functions()
save(projectdir("plots", "beh_1kHz", "01_psychometric_functions.svg"), fig)

fig = genfig_beh_1kHz_bowls()
save(projectdir("plots", "beh_1kHz", "02_bowls.svg"), fig)

fig = genfig_beh_1kHz_rove_effects()
save(projectdir("plots", "beh_1kHz", "03_rove_effects.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 2 // beh_frequency
# Behavior at all frequencies, unroved only
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_beh_frequency_psychometric_functions()
save(projectdir("plots", "beh_frequency", "01_psychometric_functions.svg"), fig)

fig = genfig_beh_frequency_bowls()
save(projectdir("plots", "beh_frequency", "02_bowls.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 3 // beh_hearing_loss
# Correlation between behavior and degree of HL
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_beh_hearing_loss()
save(projectdir("plots", "beh_hearing_loss", "01_hearing_loss.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 4 // sim_methods
# Modeling methods figures
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_sim_methods_rlfs()
save(projectdir("plots", "sim_methods", "02_rlfs.svg"), fig)

fig = genfig_sim_methods_tcs()
save(projectdir("plots", "sim_methods", "03_tcs.svg"), fig)

fig = genfig_sim_methods_mtfs()
save(projectdir("plots", "sim_methods", "04_mtfs.svg"), fig)

fig = genfig_sim_methods_example_responses()
save(projectdir("plots", "sim_methods", "05_example_responses.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 5 // sim_psychometric_functions
# Modeling detailed example results figure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_sim_psychometric_functions_profiles()
save(projectdir("plots", "sim_psychometric_functions", "01_profiles.svg"), fig)

fig = genfig_sim_psychometric_functions_rate_curves("singlechannel")
save(projectdir("plots", "sim_psychometric_functions", "02_rate_curves_singlechannel.svg"), fig)

fig = genfig_sim_psychometric_functions_rate_curves("profilechannel")
save(projectdir("plots", "sim_psychometric_functions", "03_rate_curves_profilechannel.svg"), fig)

fig = genfig_sim_psychometric_functions_rate_curves("templatebased")
save(projectdir("plots", "sim_psychometric_functions", "04_rate_curves_templatebased.svg"), fig)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 6 // sim_bowls
# Modeling results overview figure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create main bowl figures
fig = genfig_sim_bowls_density_and_frequency_bowls(; rove_size=0.001)
save(projectdir("plots", "sim_bowls", "01_density_and_frequency_bowls_fixed_level.svg"), fig)
fig = genfig_sim_bowls_density_and_frequency_bowls(; rove_size=10.0)
save(projectdir("plots", "sim_bowls", "01_density_and_frequency_bowls_roved_level.svg"), fig)

# Create bowl figure showing data as function of modulation frequency, possible supplemental
# figure or alternative version of main bowls
fig = genfig_sim_bowls_gmmf(; rove_size=10.0)
save(projectdir("plots", "sim_bowls", "s01_gmmf_bowls_roved_level.svg"), fig)

# Spot check suspicious conditions (e.g., roved LSR 1 kHz data)
plot_histograms_versus_increment_sound_level_control(
    summon_pf(; 
        center_freq=1000.0,
        n_comp=21,
        mode="singlechannel",
        rove_size=10.0,
        model=2,
    )
)

# Rove effect figure (possible supplemental figure)
fig = genfig_sim_bowls_density_and_frequency_bowls_rove_effects()
save(projectdir("plots", "sim_bowls", "s01_density_and_frequency_bowls.svg"), fig)

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