export logistic, logistic_fit, logistic_predict, hearing_group, hl_offsets,
    hl_to_spl, spl_to_hl, total_to_comp, fit_psychometric_function, modelstr,
    variance_explained, get_hl_colors, color_group

"""
    logistic(x, λ; L, offset)

Returns the logistic function value evaluated at X

# Arguments
- `x`: Argument
- `λ`: Midpoint and slope of the logistic function (in a tuple/array)
- `L=1.0`: Maximum value of the logistic function (before offset)
- `offset=0.0`: Offset of the logistic function
"""
function logistic(x, λ; L=1.0, offset=0.0)
    L/(1 + exp(-λ[2]*(x-λ[1]))) + offset
end

"""
    logistic(x, t, s; L, offset)

Returns the logistic function value evaluated at X

# Arguments
- `x`: Argument
- `t`: Midpoint of the logistic function
- `s`: Slope of the logistic function
- `L=1.0`: Maximum value of the logistic function (before offset)
- `offset=0.0`: Offset of the logistic function
"""
function logistic(x, t, s; L=1.0, offset=0.0)
    L/(1 + exp(-s*(x-t))) + offset
end

# Vector-valued function that maps from vector x and pair p (threshold and
# slope) to logistic output
@. logistic_fit(x, p) = logistic(x, p[1], p[2]; L=0.5, offset=0.5)

# Vector-valued function that maps from vector x, vector p1 (threshold), and
# vector p2 (slope) to logistic output
logistic_predict(x, p1, p2) = logistic.(x, p1, p2; L=0.5, offset=0.5)

# Function that handles fitting using above functions automatically
function fit_psychometric_function(x, y)
    curve_fit(
        logistic_fit,
        x,
        y,
        [0.0, 1.0];
        lower=[-30.0, 0.01],
        upper=[20.0, 1.0]
    )
end


### Define other useful functions
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
#total_to_comp(x, n) = 20 * log10(10^(x/20)/n)
total_to_comp(x, n) = 10 * log10(10^(x/10)/n)

# Define function that maps from model objects to convenient name strings
function modelstr(model::Model)
    if typeof(model) == AuditoryNerveZBC2014
        string(typeof(model)) * "_" * model.fiber_type
    else
        string(typeof(model))
    end
end

# Define function to compute variance explained
function variance_explained(y, ŷ)
    var_total = sum((y .- mean(y)).^2)
    var_resid = sum((ŷ .- y).^2)
    return 1 - var_resid/var_total
end

# Function to return current values for HL-group colors
function get_hl_colors()
    [
        HSL(120, 0.51, 0.58), 
        HSL(265, 0.45, 0.63), 
        HSL(29, 0.97, 0.63), 
    ]
end

# Function to map from integer [1, 2, 3] to corresponding group color
function color_group(group::Int) 
    get_hl_colors()[group]
end

# Function to map from group name to corresponding group color
function color_group(group::String) 
    hl_colors = get_hl_colors()
    if group == "< 5 dB HL"
        hl_colors[1]
    elseif group == "5-15 dB HL"
        hl_colors[2]
    else
        hl_colors[3]
    end
end