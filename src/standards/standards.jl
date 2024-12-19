export standardfields, standardclims, standardylims, standardcmap, standardlabel, standardavg

"""
    standardfields(x)

Returns typical fields worth looking at when generating automated labels, names, etc.
"""
standardfields(::Type{AuditoryNerveZBC2014}) = [:τ_e_ic, :τ_i_ic, :d_i_ic, :S_ic, :A_ic]
standardfields(::Type{InferiorColliculusSFIEBE}) = [:τ_e_ic, :τ_i_ic, :d_i_ic, :S_ic, :A_ic]
standardfields(::Type{InferiorColliculusSFIEBS}) = [:species, :fiber_type, :audiogram]

"""
    standardclims

Returns tuple containing suitable default color limits for type
"""
standardclims(::Type{AuditoryNerveZBC2014}) = (0.0, 1000.0)
standardclims(::Type{InferiorColliculusSFIEBE}) = (0.0, 200.0)
standardclims(::Type{InferiorColliculusSFIEBS}) = (0.0, 500.0)

"""
    standardylims

Returns tuple containing suitable default ylims for type
"""
standardylims(::Type{AuditoryNerveZBC2014}) = (0.0, 500.0)
standardylims(::Type{InferiorColliculusSFIEBE}) = (0.0, 100.0)
standardylims(::Type{InferiorColliculusSFIEBS}) = (0.0, 500.0)
function standardylims(x::String)
    @match x begin
        "hsr" => (0.0, 500.0)
        "lsr" => (0.0, 150.0)
        "mocwdr" => (0.0, 70.0)
        "ic" => (0.0, 200.0)
        "mocic" => (0.0, 70.0)
        "gain" => (0.0, 1.1)
        "spectrum" => (20.0, 70.0)
    end
end

"""
    standardcmap

Returns colormap or identifier that can be used in place of colormaps in Makie
"""
standardcmap(x) = :acton

"""
    standardlabel

Returns suitable ylabel for type
"""
standardlabel(x) = "Firing rate (sp/s)"

"""
    standardavg

Returns a function that computes a reasonable average given input type
"""
function standardavg(x::String)
    @match x begin
        "ihc" => rms
        "hsr" => mean
        "lsr" => mean
        "ic" => mean
    end
end
