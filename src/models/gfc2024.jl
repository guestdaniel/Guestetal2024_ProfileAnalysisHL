export GFC2024

"""
    GFC2024 <: Model

Auditory efferent model of Guest, Farhadi, and Carney (2024) 
"""
@with_kw struct GFC2024 <: Model
    # General parameters
    fs::Float64=100e3
    cf::Vector{Float64}=[1000.0]
    coi::Vector{Int64}=[Int(ceil(length(cf/2)))]
    n_chan::Int64=length(cf)
    cf_low::Float64=minimum(cf)
    cf_high::Float64=maximum(cf)
    audiogram::Audiogram=Audiogram()
    stage::String="hsr"

    # IHC parameters
    cohc::Vector{Float64}=fit_audiogram(audiogram, cf)[1]
    cihc::Vector{Float64}=fit_audiogram(audiogram, cf)[2]
    species::String="human"

    # ANF parameters
    powerlaw_mode::Int64=2
    fractional::Bool=false

    # IC parameters
    cn_tau_e::Float64=0.5e-3
    cn_tau_i::Float64=2.0e-3
    cn_delay::Float64=1.0e-3
    cn_amp::Float64=1.5
    cn_inh::Float64=0.6
    ic_tau_e::Float64=1.0/(10.0*64.0)
    ic_tau_i::Float64=ic_tau_e*1.5
    ic_delay::Float64=ic_tau_e*2.0
    ic_amp::Float64=1.0
    ic_inh::Float64=0.9

    # MOC parameters
    moc_cutoff::Float64=0.64
    moc_beta_wdr::Float64=0.015
    moc_offset_wdr::Float64=10.0*4.0
    moc_minrate_wdr::Float64=0.1
    moc_maxrate_wdr::Float64=1.0
    moc_beta_ic::Float64=0.015
    moc_offset_ic::Float64=10.0*4.0
    moc_minrate_ic::Float64=0.1
    moc_maxrate_ic::Float64=1.0
    moc_weight_ic::Float64=4.0
    moc_weight_wdr::Float64=4.0
    moc_width_wdr::Float64=0.5
    moc_delay::Float64=0.025

    # Other params
    dur_pad_left::Float64=0.1  # also used as "dur_settle"
    clip_left::Bool=dur_pad_left == 0.0 ? false : true
    dur_pad_right::Float64=0.05
    clip_right::Bool=false
end

# Some constructors for convenience
GFC2024(cf::Float64; kwargs...) = GFC2024(; cf=[cf], kwargs...)
GFC2024(cf::Vector{Float64}; kwargs...) = GFC2024(; cf=cf, kwargs...)

# compute(model, stimulus) maps from stimulus to response
function _compute(m::GFC2024, x::Vector{Float64})
    sim_gfc2023_dict(
        x,
        m.cf;
        # General parameters
        fs=m.fs,
        # IHC parameters
        cohc=m.cohc,
        cihc=m.cihc,
        species=m.species,
        # ANF parameters
        fractional=m.fractional,
        powerlaw_mode=m.powerlaw_mode,
        # IC parameters
        cn_tau_e=m.cn_tau_e,
        cn_tau_i=m.cn_tau_i,
        cn_delay=m.cn_delay,
        cn_amp=m.cn_amp,
        cn_inh=m.cn_inh,
        ic_tau_e=m.ic_tau_e,
        ic_tau_i=m.ic_tau_i,
        ic_delay=m.ic_delay,
        ic_amp=m.ic_amp,
        ic_inh=m.ic_inh,
        moc_cutoff=m.moc_cutoff,
        moc_beta_wdr=m.moc_beta_wdr,
        moc_offset_wdr=m.moc_offset_wdr,
        moc_minrate_wdr=m.moc_minrate_wdr,
        moc_maxrate_wdr=m.moc_maxrate_wdr,
        moc_beta_ic=m.moc_beta_ic,
        moc_offset_ic=m.moc_offset_ic,
        moc_minrate_ic=m.moc_minrate_ic,
        moc_maxrate_ic=m.moc_maxrate_ic,
        moc_weight_ic=m.moc_weight_ic,
        moc_weight_wdr=m.moc_weight_wdr,
        moc_width_wdr=m.moc_width_wdr,
        moc_delay=m.moc_delay,
        dur_pad_left=m.dur_pad_left,
        clip_left=m.clip_left,
        dur_pad_right=m.dur_pad_right,
        clip_right=m.clip_right,
    )
end

function compute(m::GFC2024, x::Vector{Float64})
    extract(m, _compute(m, x)[m.stage])
end