@doc raw"""
	write_curtailment(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the curtailment values of the different variable renewable resources (both standalone and 
	co-located).
"""
function write_curtailment(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    gen = inputs["RESOURCES"]  # Resources (objects)
    resources = inputs["RESOURCE_NAMES"] # Resource names
    zones = zone_id.(gen)

    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)
    VRE = inputs["VRE"]
    VRE_STOR = inputs["VRE_STOR"]

    weight = inputs["omega"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    curtailment = zeros(G, T)
    curtailment[VRE, :] = (value.(EP[:eTotalCap][VRE]) .* inputs["pP_Max"][VRE, :] .-
                           value.(EP[:vP][VRE, :]))

    if !isempty(VRE_STOR)
        SOLAR = setdiff(inputs["VS_SOLAR"], inputs["VS_WIND"])
        WIND = setdiff(inputs["VS_WIND"], inputs["VS_SOLAR"])
        SOLAR_WIND = intersect(inputs["VS_SOLAR"], inputs["VS_WIND"])
        if !isempty(SOLAR)
            curtailment[SOLAR, :] = (value.(EP[:eTotalCap_SOLAR][SOLAR]).data .*
                                    inputs["pP_Max_Solar"][SOLAR, :] .-
                                    value.(EP[:vP_SOLAR][SOLAR, :]).data) .*
                                    etainverter.(gen[SOLAR])
        end
        if !isempty(WIND)
            curtailment[WIND, :] = (value.(EP[:eTotalCap_WIND][WIND]).data .*
                                    inputs["pP_Max_Wind"][WIND, :] .-
                                    value.(EP[:vP_WIND][WIND, :]).data)
        end
        if !isempty(SOLAR_WIND)
            curtailment[SOLAR_WIND, :] = ((value.(EP[:eTotalCap_SOLAR])[SOLAR_WIND].data .*
                                           inputs["pP_Max_Solar"][SOLAR_WIND, :] .-
                                           value.(EP[:vP_SOLAR][SOLAR_WIND, :]).data) .*
                                          etainverter.(gen[SOLAR_WIND])
                                          +
                                          (value.(EP[:eTotalCap_WIND][SOLAR_WIND]).data .*
                                           inputs["pP_Max_Wind"][SOLAR_WIND, :] .-
                                           value.(EP[:vP_WIND][SOLAR_WIND, :]).data))
        end
    end

    curtailment *= scale_factor

    df = DataFrame(Resource = resources,
        Zone = zones,
        AnnualSum = zeros(G))
    df.AnnualSum = curtailment * weight

    write_temporal_data(df, curtailment, path, setup, "curtailment")


    theoreticalmax = zeros(G)
    theoreticalmax[VRE] = (value.(EP[:eTotalCap][VRE]) .* inputs["pP_Max"][VRE, :]) * weight * scale_factor
    # theoreticalmax *= scale_factor
    df2 = DataFrame(Resource = resources,
        Zone = zones,
        Capacity = value.(EP[:eTotalCap]) * scale_factor,        
        AnnualSum_curtailment = curtailment * weight,
        TheoreticalMax = theoreticalmax,
        UtilizationRate = zeros(G))
    if !isempty(VRE_STOR)
        SOLAR = setdiff(inputs["VS_SOLAR"], inputs["VS_WIND"])
        WIND = setdiff(inputs["VS_WIND"], inputs["VS_SOLAR"])
        SOLAR_WIND = intersect(inputs["VS_SOLAR"], inputs["VS_WIND"])
        if !isempty(SOLAR)
            df2.TheoreticalMax[SOLAR] = (value.(EP[:eTotalCap_SOLAR][SOLAR]).data .*
                                    inputs["pP_Max_Solar"][SOLAR, :] .*
                                    etainverter.(gen[SOLAR])) * weight * scale_factor
            df2.Capacity[SOLAR] = (value.(EP[:eTotalCap_SOLAR][SOLAR]).data .*
                                    etainverter.(gen[SOLAR])) * scale_factor
        end
        if !isempty(WIND)
            df2.TheoreticalMax[WIND] = (value.(EP[:eTotalCap_WIND][WIND]).data .*
                                    inputs["pP_Max_Wind"][WIND, :]) * weight * scale_factor
            df2.Capacity[WIND] = value.(EP[:eTotalCap_WIND][WIND]).data * scale_factor
        end
        if !isempty(SOLAR_WIND)
            df2.TheoreticalMax[SOLAR_WIND] = ((value.(EP[:eTotalCap_SOLAR])[SOLAR_WIND].data .*
                                           inputs["pP_Max_Solar"][SOLAR_WIND, :] .* 
                                           etainverter.(gen[SOLAR]))
                                          +
                                          (value.(EP[:eTotalCap_WIND][SOLAR_WIND]).data .*
                                           inputs["pP_Max_Wind"][SOLAR_WIND, :])) * weight * scale_factor
            df2.Capacity[SOLAR_WIND] = ((value.(EP[:eTotalCap_SOLAR][SOLAR]).data .*
                                    etainverter.(gen[SOLAR])) + value.(EP[:eTotalCap_WIND][WIND]).data) * scale_factor
        end
    end

    has_capacity = findall(x -> x >= 1, df2.Capacity)
    Utilization_Gen = intersect(has_capacity, union(VRE_STOR, VRE))
    # We calculate utilization rate only for VRE that is larger than 1MW

    df2.UtilizationRate[Utilization_Gen] .= 1 .- ((df2.AnnualSum_curtailment[Utilization_Gen] ./
                                  df2.TheoreticalMax[Utilization_Gen]))
    CSV.write(joinpath(path, "gen_utilizationrate.csv"), df2)
    
    return nothing
end
