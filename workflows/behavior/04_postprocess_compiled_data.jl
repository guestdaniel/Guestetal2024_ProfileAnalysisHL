using ProfileAnalysis
using DataFramesMeta
using DataFrames
using CSV

# Load data from disk
df = DataFrame(CSV.File(datadir("int_pro", "data.csv")))

# Clean up data (rename cols, add cols, etc.)
df = @chain df begin
    # Rename ΔL column to increment
    rename!(:delta_l => :increment)
    # Rename Sex -> sex
    rename!(:Sex => :sex)
    # Rename Age -> age
    rename!(:Age => :age)
    # Rename levels of unroved and roved
    @transform(:rove = getindex.(
        Ref(Dict("unroved" => "fixed level", "roved" => "roved level")), 
        :rove
    ))
    # Add a column indicating condition (combination of frequency and rove)
    @transform(:condition = string.(:freq) .* " Hz " .* :rove)
    # Add a column indicating HL status at each frequency
    @transform(:hl_group = hearing_group.(:hl))
    # Add a column indicating the level-per-component of the tones
    @transform(:level_per_component = total_to_comp.(:level, :n_comp))
    # Add a column the audiometric threshold in dB SPL 
    @transform(:audio_threshold_spl = hl_to_spl.(:hl, Float64.(:freq)))
    # Add a column indicating the SL of the tones
    @transform(:sl = :level_per_component .- :audio_threshold_spl)
    # Add a column indicating whether the present row is "legal" data according to our 
    # inclusion criteria
    @transform(:include = :sl .> 0.0)
end

# Save to disk
CSV.write(datadir("int_pro", "data_postproc.csv"), df)
