export StandardBE, StandardBS

StandardBE = Dict(
    :τ_e_ic => 1e-3,
    :τ_i_ic => 2e-3,
    :d_i_ic => 1e-3, 
    :A_ic => 2.0,
    :S_ic => 1.0,
)

StandardBS = Dict(
    :τ_e_ic => 1e-3,
    :τ_i_ic => 2e-3,
    :d_i_ic => 1e-3, 
    :A_ic => 2.0,
    :S_ic => 1.0,
    :τ_i_bs => 2e-3,
    :d_i_bs => 1e-3,
    :S_bs => 20.0,
    :A_bs => 0.2,
)