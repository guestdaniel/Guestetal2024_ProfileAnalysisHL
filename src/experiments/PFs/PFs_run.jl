@everywhere cd(expanduser("~/cl_code/ProfileAnalysis"))
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere begin 
    using ProfileAnalysis
    using Utilities
end

# Run main simulations
#run(ProfileAnalysis_PFTemplateObserver())

# Run hearing-impaired simulations 
#run(ProfileAnalysis_PFTemplateObserver_HearingImpaired())

# Run wideband control simulations
#run(ProfileAnalysis_PFTemplateObserver_WidebandControl())

# Run pure-tone control conditions
run(ProfileAnalysis_PFTemplateObserver_PureToneControl())