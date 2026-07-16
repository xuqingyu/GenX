@doc raw"""
	load_operational_reserves!(setup::Dict,path::AbstractString, inputs::Dict)

Read input parameters related to frequency regulation and operating reserve requirements
"""
function load_operational_reserves!(setup::Dict, path::AbstractString, inputs::Dict)
    filename = "Operational_reserves.csv"
    deprecated_synonym = "Reserves.csv"
    res_in = load_dataframe(path, [filename, deprecated_synonym])

    gen = inputs["RESOURCES"]

    function load_field_with_deprecated_symbol(df::DataFrame,
            columns::Vector{Symbol},
            row::Int = 1)
        best = popfirst!(columns)
        all_columns = Symbol.(names(df))
        if best in all_columns
            return float(df[row, best])
        end
        for col in columns
            if col in all_columns
                Base.depwarn(
                    "The column name $col in file $filename is deprecated; prefer $best",
                    :load_operational_reserves,
                    force = true)
                return float(df[row, col])
            end
        end
        error("None of the columns $columns were found in the file $filename")
    end

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    if setup["OperationalReserves"] == 2
        :Zone in Symbol.(names(res_in)) ||
            error("Operational_reserves.csv must include a Zone column when OperationalReserves = 2")
        reserve_zones = Int.(res_in[!, :Zone])
        Z = inputs["Z"]
        isempty(reserve_zones) &&
            error("Operational_reserves.csv must list at least one Zone when OperationalReserves = 2")
        length(unique(reserve_zones)) == length(reserve_zones) ||
            error("Each Zone in Operational_reserves.csv must appear only once")
        all(z -> 1 <= z <= Z, reserve_zones) ||
            error("Operational_reserves.csv contains a Zone outside 1:$Z")
        inputs["OPERATIONAL_RESERVE_ZONES"] = reserve_zones
        if inputs["Z"] > 1
            inputs["OPERATIONAL_RESERVE_TRANSFER_LINES"] = [
                l for l in 1:inputs["L"]
                if inputs["pTrans_Start_Zone"][l] ∉ reserve_zones &&
                   inputs["pTrans_End_Zone"][l] ∈ reserve_zones]
        else
            inputs["OPERATIONAL_RESERVE_TRANSFER_LINES"] = Int[]
        end

        inputs["pReg_Req_Demand"] = zeros(Z)
        inputs["pReg_Req_VRE"] = zeros(Z)
        inputs["pRsv_Req_Demand"] = zeros(Z)
        inputs["pRsv_Req_VRE"] = zeros(Z)
        inputs["pC_Rsv_Penalty"] = zeros(Z)
        inputs["pStatic_Contingency"] = zeros(Z)
        for (row, z) in enumerate(reserve_zones)
            inputs["pReg_Req_Demand"][z] = load_field_with_deprecated_symbol(res_in,
                [:Reg_Req_Percent_Demand, :Reg_Req_Percent_Load], row)
            inputs["pReg_Req_VRE"][z] = float(res_in[row, :Reg_Req_Percent_VRE])
            inputs["pRsv_Req_Demand"][z] = load_field_with_deprecated_symbol(res_in,
                [:Rsv_Req_Percent_Demand, :Rsv_Req_Percent_Load], row)
            inputs["pRsv_Req_VRE"][z] = float(res_in[row, :Rsv_Req_Percent_VRE])
            inputs["pC_Rsv_Penalty"][z] =
                float(res_in[row, :Unmet_Rsv_Penalty_Dollar_per_MW]) / scale_factor
            inputs["pStatic_Contingency"][z] =
                float(res_in[row, :Static_Contingency_MW]) / scale_factor
        end
    else
        inputs["OPERATIONAL_RESERVE_ZONES"] = collect(1:inputs["Z"])
        inputs["OPERATIONAL_RESERVE_TRANSFER_LINES"] = Int[]
        inputs["pReg_Req_Demand"] = load_field_with_deprecated_symbol(res_in,
            [:Reg_Req_Percent_Demand, :Reg_Req_Percent_Load])
        inputs["pReg_Req_VRE"] = float(res_in[1, :Reg_Req_Percent_VRE])
        inputs["pRsv_Req_Demand"] = load_field_with_deprecated_symbol(res_in,
            [:Rsv_Req_Percent_Demand, :Rsv_Req_Percent_Load])
        inputs["pRsv_Req_VRE"] = float(res_in[1, :Rsv_Req_Percent_VRE])
        inputs["pC_Rsv_Penalty"] =
            float(res_in[1, :Unmet_Rsv_Penalty_Dollar_per_MW]) / scale_factor
        inputs["pStatic_Contingency"] =
            float(res_in[1, :Static_Contingency_MW]) / scale_factor
    end

    if setup["UCommit"] >= 1
        if setup["OperationalReserves"] == 2
            dynamic_values = unique(Int8.(res_in[!, :Dynamic_Contingency]))
            length(dynamic_values) == 1 ||
                error("Dynamic_Contingency must have the same value for all operational reserve zones")
            inputs["pDynamic_Contingency"] = only(dynamic_values)
        else
            inputs["pDynamic_Contingency"] = Int8(res_in[1, :Dynamic_Contingency])
        end
        # Set BigM value used for dynamic contingencies cases to be largest possible cluster size
        # Note: this BigM value is only relevant for units in the COMMIT set. See operational_reserves.jl for details on implementation of dynamic contingencies
        if inputs["pDynamic_Contingency"] > 0
            inputs["pContingency_BigM"] = zeros(Float64, inputs["G"])
            for y in inputs["COMMIT"]
                inputs["pContingency_BigM"][y] = max_cap_mw(gen[y])
                # When Max_Cap_MW == -1, there is no limit on capacity size
                if inputs["pContingency_BigM"][y] < 0
                    # NOTE: this effectively acts as a maximum cluster size when not otherwise specified, adjust accordingly
                    inputs["pContingency_BigM"][y] = 5000 * cap_size(gen[y])
                end
            end
        end
    end

    println(filename * " Successfully Read!")
end
