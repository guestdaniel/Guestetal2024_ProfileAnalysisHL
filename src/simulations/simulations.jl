export Simulation#, SimulationSet
export Response
export simulate, simulate_memoized, cachepath, loadcache, savecache, @memo, viz, viz!

"""
    Simulation <: Component

Abstract type for encoding how to combine Components to achieve a result 

Simulations are composed of a handful of Components or iterable containers of Components.
Simulations must provide an implementation of `simulate(::Simulation)`, which describes how
to combine Components to produce a result or output (most typically, a numeric value or some
Array of numeric values, such as a vector of firing rates).

Simulations have a flexible disk-based memoization system implemented via a small set of
macros and higher-order functions. This provides an easy way to automatically cache
simulation results to disk and reuse in place of recomputation appropriately and
configurably

# Methods
- `simulate(::Simulation)`: produce the output of the simulation
- `cache(::String, ::Simulation, ::Any)`: cache result of simulation
"""
abstract type Simulation <: Component end

function simulate(::Simulation) "Hitting this when you're not supposed to!" end
simulate(sim::Simulation, ::Config) = simulate(sim)

function viz(::Simulation, args...; kwargs...) end
function viz!(::Simulation, args; kwargs...) end

function simulate_memoized(sim::Simulation, config::Config)
    if isfile(cachepath(sim, config)) & config.load_from_cache
        r = loadcache(sim, config)
    else
        r = simulate(sim, config)
        if config.save_to_cache
            savecache(sim, r, config)
        end
    end
    return r
end

function cachepath(sim::Simulation, config::Config=Default(); filetype=".jld2")
    joinpath(cachepath(config), bytes2hex(sha256(id(config) * id(sim))) * filetype)
end

function Base.isfile(sim::Simulation, config::Config=Default(); kwargs...)
    isfile(cachepath(sim, config; kwargs...))
end

loadcache(sim::Simulation, config::Config=Default()) = load(cachepath(sim, config))["x"]
savecache(sim::Simulation, x, config::Config=Default()) = save(cachepath(sim, config), Dict("x" => x))

"""
    @memo config simulate(sim)

Evaluates `simulate_memoized(config, sim)` in lieu of `simulate(sim)`
"""
macro memo(config, expr)
    Expr(:call, :simulate_memoized, esc(expr.args[2]), esc(config))
end

"""
    Response{S, M}

Simulation consisting of generating a response from a model::M for a stimulus::S
"""
@with_kw struct Response{S, M} <: Simulation where {S <: Stimulus, M <: Model}
    stimulus::S
    model::M
end

function simulate(r::Response)
    compute(r.model, r.stimulus)
end

timeaxis(r::Response) = collect(0.0:(1/r.model.fs):(r.stimulus.dur - 1/r.model.fs))
cfaxis(r::Response) = r.model.cf