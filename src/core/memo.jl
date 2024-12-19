export cachepath, loadcache, savecache, deletecache, @memo, call_memoized, @purge


"""
    cachepath(config, func, comps...)

Given a Config, a Function, and any number of components, return path to cache file

Uses extensions of the `hash` function to compute a hash encoding the combination of the
current Config, a function, and Components. The hash is then combined with root path 
specified by the Config and a filetype, specified as a keyword argument. The assumption is
that the output of `func(comps...)` will be stored at `cachepath(config, func, comps...)`
"""
function cachepath(config::Config, func::Function, comps...; filetype=".jld2")
    # Hash config, func, and comps and then reduce with xor to single hash
    hashid = reduce(⊻, [hash(config), hash(func), hash(comps...)])

    # Concatenate all path elements together
    joinpath(cachepath(config), string(hashid, base=16) * filetype)
end

function Base.isfile(config::Config, func::Function, sims...; kwargs...)
    isfile(cachepath(config, func, sims...; kwargs...))
end

function Base.isfile(sim::Component)
    isfile(cachepath(Config(), simulate, sim))
end

function loadcache(config::Config, func::Function, sims...; kwargs...) 
    load(cachepath(config, func, sims...; kwargs...))["data"]
end

function savecache(data, config::Config, func::Function, sims...; kwargs...) 
    save(cachepath(config, func, sims...; kwargs...), Dict("data" => data))
end

function deletecache(config::Config, func::Function, sims...; kwargs...) 
    fn = cachepath(config, func, sims...; kwargs...)
    @info "Delete cache file at $fn"
    rm(fn)
end

"""
    call_memoized(config, func, sims...)

Given a Config, execute func(sims...) in a memoized fashion.
"""
function call_memoized(config::Config, func::Function, sims...; kwargs...)
    if isfile(config, func, sims...; kwargs...) & config.load_from_cache
        r = loadcache(config, func, sims...; kwargs...)
    else
        r = func(sims...)
        if config.save_to_cache
            savecache(r, config, func, sims...; kwargs...)
        end
    end
    return r
end

function call_memoized(config::Config, func::Function, sims::Vector{S}; kwargs...) where {S <: Component}
    map(sims) do sim
        call_memoized(config, func, sim; kwargs...)
    end
end

"""
    @memo config func(sims...)

Evaluates `call_memoized(config, func, sims...)` in lieu of `func(sims...)`
"""
macro memo(config, expr)
    Expr(:call, :call_memoized, esc(config), esc(expr.args[1]), esc.(expr.args[2:end])...)
end

"""
    @purge config func(sims...)

Evaluates `deletecache(config, func, sims...)` in lieu of `func(sims...)`
"""
macro purge(config, expr)
    Expr(:call, :deletecache, esc(config), esc(expr.args[1]), esc.(expr.args[2:end])...)
end