export get_hl_colors, color_group

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