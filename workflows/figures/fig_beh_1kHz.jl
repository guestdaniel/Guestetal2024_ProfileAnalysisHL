fig = genfig_beh_1kHz_psychometric_functions()
save(projectdir("plots", "beh_1kHz", "01_psychometric_functions.svg"), fig)

fig = genfig_beh_1kHz_bowls()
save(projectdir("plots", "beh_1kHz", "02_bowls.svg"), fig)

fig = genfig_beh_1kHz_rove_effects()
save(projectdir("plots", "beh_1kHz", "03_rove_effects.svg"), fig)
