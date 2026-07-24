@doc raw"""
	load_cap_reserve_margin_multihours!(setup::Dict, path::AbstractString, inputs::Dict)

Read input parameters related to planning reserve margin constraints for exogenously selected hours
"""
function load_cap_reserve_margin_multihours!(setup::Dict, path::AbstractString, inputs::Dict)
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    # Slack variables
    filename = "CRM_multihours_slack.csv"
    if isfile(joinpath(path, filename))
        df = load_dataframe(joinpath(path, filename))
        inputs["dfCapRes_slack"] = df
        inputs["dfCapRes_slack"][!, :PriceCap] ./= scale_factor
    end

    # Core reserve margin requirements
    filename = "CRM_multihours.csv"
    df = load_dataframe(joinpath(path, filename))

    mat = extract_matrix_from_dataframe(df, "CapRes")
    inputs["dfCapRes"] = mat

    NCRM = size(mat, 2)
    inputs["NCapacityReserveMargin"] = NCRM

    # #####################################
    # load t for each region
    # #####################################
    filename = "CRM_multihours_selected.csv"
    df_selected = load_dataframe(joinpath(path, filename))

    selected_hours = Dict{Int, Vector{Int}}()
    for res in 1:NCRM
        selected_hours[res] = df_selected[df_selected.CapRes .== res, :t]
    end
    inputs["selected_capres_multihours"] = selected_hours

    println(filename * " Successfully Read!")
end

@doc raw"""
	load_cap_reserve_margin_multihours_trans!(setup::Dict, inputs::Dict, network_var::DataFrame)

Read input parameters related to participation of transmission imports/exports in multihours capacity reserve margin constraint
"""
function load_cap_reserve_margin_multihours_trans!(setup::Dict, inputs::Dict, network_var::DataFrame)
    mat = extract_matrix_from_dataframe(network_var, "DerateCapRes")
    inputs["dfDerateTransCapResMulti"] = mat

    mat = extract_matrix_from_dataframe(network_var, "CapRes_Excl")
    inputs["dfTransCapResMulti_excl"] = mat
end