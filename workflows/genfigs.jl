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
# TODO Regenerate
fig = genfig_sim_psychometric_functions_profiles()
save(projectdir("plots", "sim_psychometric_functions", "01_profiles.svg"), fig)

# TODO update and regenerate eta/zeta once bluehive is done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Figure 6 // sim_bowls
# Modeling results overview figure
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig = genfig_sim_bowls_density_and_frequency_bowls()
save(projectdir("plots", "sim_bowls", "01_density_and_frequency_bowls.svg"), fig)