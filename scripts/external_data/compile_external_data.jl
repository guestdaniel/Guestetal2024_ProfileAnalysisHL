# Preprocess external datasets in data/ext_raw/
# Datasets include:
    # Means from Green (1985), Figure 2
    # Means from Green (1985), Figure 3
    # Means from Lentz (1999), Figure 2
# Data were extracted visually using WebPlotDigitizer

using CSV
using DataFrames

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Compile experiments
# External
main = DataFrame()
green1983a_fig2 = DataFrame(CSV.File(datadir("ext_pro", "Green1983a_Fig2.csv")))
green1983a_fig2[!, :experiment] .= "Green and Kidd (1983), Figure 2"
green1983b_fig4 = DataFrame(CSV.File(datadir("ext_pro", "Green1983b_Fig4.csv")))
green1983b_fig4[!, :experiment] .= "Green, Kidd, and Picardi (1983), Figure 4"
green1985_fig1 = DataFrame(CSV.File(datadir("ext_pro", "Green1985_Fig1.csv")))
green1985_fig1[!, :experiment] .= "Green and Mason (1985), Figure 1"
green1985_fig2 = DataFrame(CSV.File(datadir("ext_pro", "Green1985_Fig2.csv")))
green1985_fig2[!, :experiment] .= "Green and Mason (1985), Figure 2"
green1985_fig3 = DataFrame(CSV.File(datadir("ext_pro", "Green1985_Fig3.csv")))
green1985_fig3[!, :experiment] .= "Green and Mason (1985), Figure 3"
bernstein1987_fig2 = DataFrame(CSV.File(datadir("ext_pro", "Bernstein1987_Fig2.csv")))
bernstein1987_fig2[!, :experiment] .= "Bernstein and Green (1987), Figure 2"
lentz1999_fig2 = DataFrame(CSV.File(datadir("ext_pro", "Lentz1999_Fig2.csv")))
lentz1999_fig2[!, :experiment] .= "Lentz, Richards, and Matiasek (1999), Figure 2"

main = vcat(main, green1983a_fig2; cols=:union)
main = vcat(main, green1983b_fig4; cols=:union)
main = vcat(main, green1985_fig1; cols=:union)
main = vcat(main, green1985_fig2; cols=:union)
main = vcat(main, green1985_fig3; cols=:union)
main = vcat(main, bernstein1987_fig2; cols=:union)
main = vcat(main, lentz1999_fig2; cols=:union)
main[!, :external] .= true

#  .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.
# / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
#`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `
### Calculate additional variables
# Calculate bandwidth of stimulus (in octaves)
main[!, :bandwidth] .= log2.(main.f_high ./ main.f_low)  # in octaves

# Calculate component spacing of stimulus (in semitones)
main[!, :spacing_st] .= main.bandwidth ./ (main.n_comp .- 1) .* 12

# Calculate component spacing of stimulus (in average Hz of adjacent components)
main[!, :spacing_hz] .= main.freq .* 2.0 .^ (main.spacing_st ./ 12) .- main.freq

### Save
CSV.write("data/ext_pro/all_data.csv", main)
