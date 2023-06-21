@everywhere cd(expanduser("~/cl_code/ProfileAnalysis"))
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere begin 
    using ProfileAnalysis
    using Utilities
end

include(projectdir("papers", "Guestetal2023", "figures", "fig_zeta", "c_psychometric_functions.jl"))