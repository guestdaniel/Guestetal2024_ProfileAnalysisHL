export grouper_identity, grouper_pta3, grouper_pta4, grouper_hl, grouper_threeway

grouper_identity(df) = df

# Group based on whether PTA exceeds 25 dB HL
function grouper_pta3(df)
    df[!, :hl_group] = convert.(String, df[!, :hl_group])
    df[df.pta_3 .> 25.0, :hl_group] .= "Hearing impaired"
    df[df.pta_3 .<= 25.0, :hl_group] .= "Normal hearing"
    df
end

# Group based on whether PTA exceeds 25 dB HL
function grouper_pta4(df)
    df[!, :hl_group] = convert.(String, df[!, :hl_group])
    df[df.pta_4 .> 25.0, :hl_group] .= "Hearing impaired"
    df[df.pta_4 .<= 25.0, :hl_group] .= "Normal hearing"
    df
end

# Group based on whether audiometric threshold at target frequency kHz exceeds 20 dB HL
function grouper_hl(df)
    df[!, :hl_group] = convert.(String, df[!, :hl_group])
    df[df.hl .> 20.0, :hl_group] .= "Hearing impaired"
    df[df.hl .<= 20.0, :hl_group] .= "Normal hearing"
    df
end

# Group into three groups:
# Assign subjects to groups as:
#   1) Hearing-impaired: PTA3 > 25 dB HL
#   2) Intermediate: PTA3 < 25 dB HL but PTAUPPER > 25 dB HL
#   3) NH: PTA3 and PTAUPPER < 25 dB HL
function grouper_threeway(df)
    df[!, :hl_group] = convert.(String, df[!, :hl_group])
    df[df.pta_jama .> 25.0, :hl_group] .= "Hearing loss\n(LF and HF)"
    df[(df.pta_jama .<= 25.0) .& (df.pta_upper .> 25.0), :hl_group] .= "Hearing loss\n(HF only)"
    df[(df.pta_jama .<= 25.0) .& (df.pta_upper .<= 25.0), :hl_group] .= "Normal hearing"
    df
end

