@doc raw"""
	load_cap_reserve_margin_peakload!(setup::Dict, path::AbstractString, inputs::Dict)

Read input parameters related to planning reserve margin constraints
"""
function load_cap_reserve_margin_peakload!(setup::Dict, path::AbstractString, inputs::Dict)
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    filename = "CRM_peakhour_slack.csv"
    if isfile(joinpath(path, filename))
        df = load_dataframe(joinpath(path, filename))
        inputs["dfCapRes_slack"] = df
        inputs["dfCapRes_slack"][!, :PriceCap] ./= scale_factor # Million $/GW if scaled, $/MW if not scaled
    end

    filename = "CRM_peakhour.csv"
    df = load_dataframe(joinpath(path, filename))

    mat = extract_matrix_from_dataframe(df, "CapRes")
    inputs["dfCapRes"] = mat
    
    NCRM = size(mat,2)
    inputs["NCapacityReserveMargin"] = NCRM

    T = inputs["T"]
    pD=inputs["pD"]

    peak_hour_idx = Vector{Int}(undef, NCRM)
    for res in 1:NCRM
        zones = findall(!iszero, inputs["dfCapRes"][:, res])
        total_load = [sum(pD[t, z] for z in zones) for t in 1:T]
        peak_hour_idx[res] = argmax(total_load)
    end

    inputs["peak_hour_idx"] = peak_hour_idx
    inputs["T_peak"] = 1  

    println(filename * " Successfully Read!")
end

@doc raw"""
	load_cap_reserve_margin_trans!(setup::Dict, inputs::Dict, network_var::DataFrame)

Read input parameters related to participation of transmission imports/exports in capacity reserve margin constraint.
"""
function load_cap_reserve_margin_peakload_trans!(setup::Dict, inputs::Dict, network_var::DataFrame)
    mat = extract_matrix_from_dataframe(network_var, "DerateCapRes")
    inputs["dfDerateTransCapRes"] = mat

    mat = extract_matrix_from_dataframe(network_var, "CapRes_Excl")
    inputs["dfTransCapRes_excl"] = mat
end