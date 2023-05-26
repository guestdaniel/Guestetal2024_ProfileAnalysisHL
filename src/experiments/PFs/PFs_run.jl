@everywhere cd(expanduser("~/cl_code/ProfileAnalysis"))
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere begin 
    using ProfileAnalysis
    using Utilities
end

run(ProfileAnalysis_PFTemplateObserver())
