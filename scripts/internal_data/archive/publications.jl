### Define utility functions for psychometric functions
# Vector-valued function that maps from vector x and pair p (threshold and
# slope) to logistic output
@. logistic_fit(x, p) = logistic(x, p[1], p[2]; L=0.5, offset=0.5)

# Vector-valued function that maps from vector x, vector p1 (threshold), and
# vector p2 (slope) to logistic output
logistic_predict(x, p1, p2) = logistic.(x, p1, p2; L=0.5, offset=0.5)

# Function that accepts observed data and fits logistic function to them using
# curve_fit
function fit_psychometric_function(x, y)
    curve_fit(
        logistic_fit,
        x,
        y,
        [0.0, 1.0];
        lower=[-25.0, 0.001],
        upper=[15.0, 1.0]
    )
end

### Define other userful functions
# Define function for hearing group, maps from HL value to string denoting a
# "hearing group"
function hearing_group(x)
    if x < 5
        return "< 5 dB HL"
    elseif 5 <= x <= 15
        return "5-15 dB HL"
    else
        return "> 15 dB HL"
    end
end

# Define function that maps from audiometric threshold in HL to absolute threshold in SPL
hl_offsets = Dict(
    125.0 => 45.0,
    250.0 => 27.0,
    500.0 => 13.5,
    750.0 => 9.0,
    1000.0 => 7.5,
    1500.0 => 7.5,
    2000.0 => 9.0,
    3000.0 => 11.5,
    4000.0 => 12.0,
    6000.0 => 16.0,
    8000.0 => 15.5,
)
function hl_to_spl(hl, freq)
    return hl + hl_offsets[freq]
end
function spl_to_hl(spl, freq)
    return spl - hl_offsets[freq]
end

# Define function that maps from overall level to level-per-component
total_to_comp(x, n) = 10 * log10((10 ^ (x/10))/n)


### Load and clean data
# Load data from disk
fullpath = datadir("int_pro", "data.csv")
df = DataFrame(CSV.File(fullpath))

# Clean up data (rename cols, add cols, etc.)
df = @chain df begin
    # Rename ΔL column to increment
    rename!(:delta_l => :increment)
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
end

### Define useful variables
x_hat_fill = -30:0.1:25
