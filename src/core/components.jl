export Component
export id, cachepath

"""
    Component

Fundamental ingredient of auditory computational modeling (e.g., Model, Stimulus)

Component is an abstract type that provides various methods useful for computational 
modeling work, such as generating unique ID values for unique combinations of field values.

# Methods:
- `id(x)`: Returns string that uniquely maps to `x`
- `id(x, y)` Returns a string that uniquely maps to the combination of `x` and `y`
- `cachepath(x...)`: Returns path of the cache file for this combination of components
- `compute(x)` or `compute(x, args...)`: runs the core computations of the Component to
  yield an output
"""
abstract type Component end

"""
    id(comp::Component[; accesses=nothing, connector="_"])

Return string uniquely mapping to field values of `comp`

Uses `DrWatson.savename` to generate a string that uniquely maps to `comp`, up to certain
limits, such as only working for fields of a limited set of types. Generates IDs for the
type:

    a=1_b=2_c=xyz

where a, b, c are field names and the values following the equals signs are the
corresponding field values converted to strings.

# Arguments:
- `comp::Component` Input component
- `accesses=nothing`: If not nothing, selects which fields of `comp` are included in
  generating the ID
- `connector="_"`: String used to connect between field names and values
"""
function id(comp::Component; accesses=nothing, connector="_", kwargs...)
    savename(
        string(typeof(comp)),
        comp; 
        accesses=accesses === nothing ? fieldnames(typeof(comp)) : accesses,
        allowedtypes=(
            Real, 
            String, 
            Symbol, 
            Function,
            Component,
            Audiogram,
        ), 
        connector=connector,
        kwargs...
    )
end

"""
    id(comps...[; kwargs...])

Return string uniquely mapping to combination of Components in `comps`
"""
function id(comps::Vararg{Component, N}; connector_super="_", connector="_", kwargs...) where N
    join(map(x -> id(x; connector=connector, kwargs...), comps), connector_super)
end

# We override DrWatson.access to give us recursive ID-generating superpowers
function DrWatson.access(comp::Component, key)
    if typeof(getproperty(comp, key)) <: Component
        id(getproperty(comp, key))
    else
        getproperty(comp, key)
    end
end
