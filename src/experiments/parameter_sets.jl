export LowBE, StandardBE, HighBE, StandardBS

# Standard BE cell (used in most of paper)
StandardBE = Dict(
    :τ_e_ic => 1e-3,
    :τ_i_ic => 2e-3,
    :d_i_ic => 1e-3, 
    :A_ic => 2.0,
    :S_ic => 1.0,
)

# BE cell tuned to lower FM
LowBE = Dict(
    # :τ_e_ic => 1e-3*2.3,
    # :τ_i_ic => 2e-3*3.0,
    # :d_i_ic => 1e-3,
    :τ_e_ic => 2.5e-3,
    :τ_i_ic => 6e-3,
    :d_i_ic => 1.0e-3,
    :A_ic => 3.0,
    :S_ic => 1.0,
)

# BE cell tuned to lower FM
HighBE = Dict(
    :τ_e_ic => 0.4e-3, 
    :τ_i_ic => 0.7e-3,
    :d_i_ic => 0.4e-3, 
    :A_ic => 2.25,
    :S_ic => 1.0,
)

# Standard BS cell (used in most of paper)
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

# BS cell tuned to lower FM
LowBS = Dict(
    :τ_e_ic => 2.5e-3,
    :τ_i_ic => 6e-3,
    :d_i_ic => 1.0e-3,
    :A_ic => 1.0,
    :S_ic => 1.0,
    :τ_i_bs => 2e-3,
    :d_i_bs => 1e-3,
    :S_bs => 2.2,
    :A_bs => 1.5,
)

# BS cell tuned to higher FM
HighBS = Dict(
    :τ_e_ic => 0.4e-3, 
    :τ_i_ic => 0.7e-3,
    :d_i_ic => 0.4e-3, 
    :A_ic => 2.25,
    :S_ic => 1.0,
    :τ_i_bs => 1.0e-3,
    :d_i_bs => 0.5e-3,
    :S_bs => 2.2,
    :A_bs => 1.5,
)