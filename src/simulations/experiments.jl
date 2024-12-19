export Experiment           # abstract tpyes
#export Subexperiments
export status, setup, purge, viz       # functions

"""
    Experiment

Abstract type for bundling together related code for sequences or groups of simulations
"""
abstract type Experiment end

# Declare methods that must be provided by user
function setup(::Experiment) end
function viz(::Experiment, ::Config) end

# Declare methods provided by us
function Base.run(experiment::Experiment, config::Config=Default())
    # Set up simulations and context
    sims = setup(experiment)

    # Loop through simulations and evaluate
    @info "Running $experiment"
    @showprogress for sim in sims
        @memo config run(sim)
    end

    # Visualize
    viz(config, experiment)
end

function status(experiment::Experiment, config::Config=Default())
    @info "Checking status of $experiment"
    display(config)
    sims = setup(experiment)
    cached = map(sims) do sim
        isfile(cachepath(sim, config))
    end
    if allcached(cached)
        @info "Experiment complete and cached!"
    else
        @info "Experiment incomplete!"
        display(cached)
    end
    return cached
end

function purge(experiment::Experiment, config::Config=Default())
    @info "Purging cache for $experiment"
    sims = setup(experiment)
    map(sims) do sim
        rm(cachepath(config, sim))
    end
    @info "Cache purged!"
end

allcached(cached::Any) = all(map(allcached, cached))
allcached(cached::Vector{Bool}) = all(cached)
allcached(cached::Matrix{Bool}) = all(cached)
sumcache(cached::Any) = sum(map(sumcache, cached))
sumcache(cached::Vector{Bool}) = sum(cached)
sumcache(cached::Matrix{Bool}) = sum(cached)
lencache(cached::Any) = sum(map(lencache, cached))
lencache(cached::Vector{Bool}) = length(cached)
lencache(cached::Matrix{Bool}) = length(cached)

# """
#     Subexperiments

# Container type wrapping small "subexperiments" 

# On iterating, emits pairs of names and corresponding sub-experiments
# """
# @with_kw struct Subexperiments 
#     names::Vector{String}
#     subexps::Vector
# end

# # Useful constructor
# function Subexperiments(inputs::Vararg{Pair, N}) where N
#     Subexperiments(
#         [x[1] for x in inputs],
#         [x[2] for x in inputs],
#     )
# end

# # Iteration interface
# Base.iterate(x::Subexperiments) = (x.names[1], x.subexps[1]), 2
# function Base.iterate(x::Subexperiments, state)
#     if state <= length(x.subexps) 
#         (x.names[state], x.subexps[state]), state+1
#     else
#         nothing
#     end
# end
# Base.getindex(x::Subexperiments, index) = x.subexps[index]
# Base.length(x::Subexperiments) = length(x.subexps)

# # Print interface
# function Base.display(x::Subexperiments)
#     println("Subexperiments")
#     for (name, subexp) in x
#         println("$name => $(typeof(subexp))")
#     end
# end