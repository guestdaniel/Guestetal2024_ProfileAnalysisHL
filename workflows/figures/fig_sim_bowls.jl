## Old version
fig = genfig_theta_bowls("singlechannel"; marker=:rect)
save(projectdir("plots", "manuscript_fig_theta_a1.svg"), fig)

fig = genfig_theta_bowls("profilechannel"; marker=:circle)
save(projectdir("plots", "manuscript_fig_theta_a2.svg"), fig)

fig = genfig_theta_bowls("templatebased"; marker=:diamond)
save(projectdir("plots", "manuscript_fig_theta_a3.svg"), fig)

fig = genfig_theta_bowl_1kHz_vs_data()
save(projectdir("plots", "manuscript_fig_theta_a4.svg"), fig)

fig = genfig_theta_bowl_1kHz_vs_data_free()
save(projectdir("plots", "manuscript_fig_theta_a5.svg"), fig)

# fig = genfig_theta_freq_bowls("singlechannel")
# save(projectdir("plots", "manuscript_fig_theta_a1a.svg"), fig)

# fig = genfig_theta_freq_bowls("profilechannel")
# save(projectdir("plots", "manuscript_fig_theta_a2a.svg"), fig)

# fig = genfig_theta_freq_bowls("templatebased")
# save(projectdir("plots", "manuscript_fig_theta_a3a.svg"), fig)

fig = genfig_theta_freq_bowls_summary()
save(projectdir("plots", "manuscript_fig_theta_b.svg"), fig)

fig = genfig_theta_freq_bowls_summary_free()
save(projectdir("plots", "manuscript_fig_theta_b2.svg"), fig)

## New version
fig = genfig_sim_bowls_density_and_frequency_bowls()
save(projectdir("plots", "fig_sim_bowls_density_and_frequency_bowls.svg"), fig)

fig = genfig_sim_bowls_summary()
save(projectdir("plots", "fig_sim_bowls_summary.svg"), fig)
