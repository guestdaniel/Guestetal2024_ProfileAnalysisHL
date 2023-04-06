# Preprocess external datasets in data/ext_raw/
# Datasets include:
    # Means from Green (1985), Figure 2
    # Means from Green (1985), Figure 3
    # Means from Lentz (1999), Figure 2
# Data were extracted visually using WebPlotDigitizer

using CSV
using DataFrames

### Set wd
cd("/home/daniel/cl_code/pahi")

### Preprocess Green (1983a), Figure 4
df = map([2, 4, 10, 20]) do n_comp
    # Read in data
    file = "Green1983a_Fig2_$(n_comp).csv"
    path = joinpath("data/ext_raw", file)
    df = DataFrame(CSV.File(path; header=0))

    # Add labels
    rename!(df, ["pedestal_level_re_background", "threshold"])

    # Add additional data
    df[!, "level"] .= 45.0
    df[!, "rove_range"] .= 40.0
    df[!, "freq"] .= 948.6
    df[!, "n_comp"] .= n_comp .+ 1
    df[!, "f_low"] .= 10 .^ (log10.(df.freq) .- ((df.n_comp .- 1) ./ 2) .* (1 ./ df.n_comp))
    df[!, "f_high"] .= 10 .^ (log10.(df.freq) .+ ((df.n_comp .- 1) ./ 2) .* (1 ./ df.n_comp))
    return df
end
df = vcat(df...)

# Save clean versio n
CSV.write("data/ext_pro/Green1983a_Fig2.csv", df)

### Preprocess Green (1983b), Figure 4
df = map([3, 5, 11, 21]) do n_comp
    # Read in data
    file = "Green1983b_Fig4_$(n_comp).csv"
    path = joinpath("data/ext_raw", file)
    df = DataFrame(CSV.File(path; header=0))

    # Add labels
    rename!(df, ["spacing_au", "threshold"])

    # Add additional data
    df[!, "level"] .= 50.0
    df[!, "rove_range"] .= 40.0
    df[!, "freq"] .= 1000.0
    df[!, "n_comp"] .= n_comp
    df[!, "f_low"] .= 1000.0 ./ 1.0116 .^ (df.spacing_au .* (df.n_comp .- 1) ./ 2)
    df[!, "f_high"] .= 1000.0 .* 1.0116 .^ (df.spacing_au .* (df.n_comp .- 1) ./ 2)
    return df
end
df = vcat(df...)

# Save clean version
CSV.write("data/ext_pro/Green1983b_Fig4.csv", df)

### Preprocess Green (1985), Figure 1
# Read in data
file = "Green1985_Fig1.csv"
path = joinpath("data/ext_raw", file)
df = DataFrame(CSV.File(path; header=0))

# Add labels
rename!(df, ["freq", "threshold"])

# Add additional data
df[!, "level"] .= 60.0
df[!, "rove_range"] .= 20.0
df[!, "n_comp"] .= 21
df[!, "f_low"] .= 200.0
df[!, "f_high"] .= 5000.0

# Save clean version
CSV.write("data/ext_pro/Green1985_Fig1.csv", df)

### Preprocess Green (1985), Figure 2
# Read in data
file = "Green1985_Fig2.csv"
path = joinpath("data/ext_raw", file)
df = DataFrame(CSV.File(path; header=0))

# Add labels
rename!(df, ["freq", "threshold"])

# Add additional data
df[!, "level"] .= 60.0
df[!, "rove_range"] .= 20.0
df[!, "n_comp"] .= 5
df[!, "f_low"] .= df.freq .* (1/1.1746) .* (1/1.1746)
df[!, "f_high"] .= df.freq .* 1.1746 .* 1.1746

# Save clean version
CSV.write("data/ext_pro/Green1985_Fig2.csv", df)

### Preprocess Green (1985), Figure 3
# Read in data
file = "Green1985_Fig3.csv"
path = joinpath("data/ext_raw", file)
df = DataFrame(CSV.File(path; header=0))

# Add labels
rename!(df, ["n_comp", "threshold"])

# Add additional data
df.n_comp .= round.(df.n_comp)
df[!, "freq"] .= 1000.0
df[!, "f_low"] .= 200.0
df[!, "f_high"] .= 5000.0
df[!, "level"] .= 45.0
df[!, "rove_range"] .= 40.0

# Save clean version
CSV.write("data/ext_pro/Green1985_Fig3.csv", df)

### Preprocess Bernstein (1987), Figure 2
df = map([380, 1000, 2626]) do freq
    # Read in data
    file = "Bernstein1987_Fig2_$freq.csv"
    path = joinpath("data/ext_raw", file)
    df = DataFrame(CSV.File(path; header=0))

    # Add labels
    rename!(df, ["n_comp", "threshold"])

    # Add additional data
    df.n_comp .= round.(df.n_comp)
    df[!, "freq"] .= Float64.(freq)
    df[!, "f_low"] .= 200.0
    df[!, "f_high"] .= 5000.0
    df[!, "level"] .= 50.0
    df[!, "rove_range"] .= 20.0
    df
end
df = vcat(df...)

# Save clean version
CSV.write("data/ext_pro/Bernstein1987_Fig2.csv", df)

### Preprocess Lentz (1999), Figure 2
# Read in data
file = "Lentz1999_Fig2.csv"
path = joinpath("data/ext_raw", file)
df = DataFrame(CSV.File(path; header=0))

# Add labels
rename!(df, ["n_comp", "threshold"])

# Add additional data
df.n_comp .= round.(df.n_comp)
df[!, "freq"] .= 1000.0
df[!, "f_low"] .= 200.0
df[!, "f_high"] .= 5000.0
df[!, "level"] .= 55.0
df[!, "rove_range"] .= 20.0 # check this value

# Save clean version
CSV.write("data/ext_pro/Lentz1999_Fig2.csv", df)

### Preprocess PAHI-1
# Read in data
file = "pahi_group_avg_thresholds.csv"
path = "/home/daniel/cl_data/pahi/clean/$file"
df = DataFrame(CSV.File(path))
df = df[:, 2:(end-1)]

# Add additional data
df[!, "f_low"] .= df.freq .* 2 .^ (-1)
df[!, "f_high"] .= df.freq .* 2 .^ (1)
df[!, "level"] .= 70.0
df[!, "rove_range"] .= ifelse.(df.rove .== "unroved", 0.0, 20.0)

# Save clean version
CSV.write("data/ext_pro/pahi-1.csv", df)
