using Test
using AuditorySignalUtils
using Utilities
using ProfileAnalysis

const fs = 100e3

# Verify that levels in ProfileAnalysisTone are set correctly, and that currently version of
# `spectrum` correctly returns levels
@testset "Profile-analysis stimulus: levels" for dur in [0.1, 0.275, 1.0]
    # Set parameters
    center_freq = 1000.0
    n_comp = 21
    pedestal_level = 70.0

    # Using procedure from profile_analysis_tone, synthesize background and estimate gain
    background = map(LogRange(center_freq/5, center_freq*5, n_comp)) do freq
        pure_tone(freq, 0.0, dur, fs)
    end
    background = sum(background)
    gain = pedestal_level - dbspl(background)
    final_level = 90.6 + gain  # 90.6 is dB SPL value of unscaled pure tone

    # Check that a series of pure tones added together, each of which is amplified by
    # `gain`, yields a complex tone with the correct overall level (`pedestal_level`)
    background_each = dbspl(sum(map(
        f -> amplify(pure_tone(f, 0.0, dur, fs), gain), 
        LogRange(center_freq/5, center_freq*5, n_comp)
    )))
    @test ≈(background_each, pedestal_level; atol=1.0)  # must be within 1.0 dB

    # Check that a series of pure tones added together, each of which is scaled to the 
    # dB SPL value specified by `total_to_comp`, yields a complex tone with the correct 
    # overall level (`pedestal_level`)
    background_each = dbspl(sum(map(
        f -> scale_dbspl(pure_tone(f, 0.0, dur, fs), total_to_comp(pedestal_level, n_comp)),
        LogRange(center_freq/5, center_freq*5, n_comp),
    )))
   
    # Check that `spectrum` function determines the same per-component level as the nominal
    # per-component level above (`final_level`)
    f, X = spectrum(amplify(background, gain), fs; pad_factor=5)
    idx = argmin(abs.(f .- 1000.0))
    @test ≈(X[idx], final_level; atol=1.0)  # must be within 1.0 dB

    # Check that `final_level` matches the analytic form given by `total_to_comp`
    @test ≈(total_to_comp(pedestal_level, n_comp), final_level; atol=1.0)  # must be within 1.0 dB
end