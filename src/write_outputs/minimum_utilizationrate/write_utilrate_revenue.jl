@doc raw"""
    write_minur_revenue(path::AbstractString, inputs::Dict, setup::Dict, dfPower::DataFrame, dfMinCF::DataFrame, EP::Model)
"""
function write_utilrate_revenue(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        dfPower::DataFrame,
        dfMinUtilRate::DataFrame,
        EP::Model)
    gen = inputs["RESOURCES"]
    regions = region.(gen)
    clusters = cluster.(gen)
    zones = zone_id.(gen)
    rid = resource_id.(gen)
    FUSION = ids_with(gen, :fusion)

    dfMinUtilRateRev = DataFrame(region = regions,
        Resource = inputs["RESOURCE_NAMES"],
        zone = zones,
        Cluster = clusters,
        R_ID = rid)
    G = inputs["G"]
    NumberOfMinURReqs = inputs["NumberOfMinURReqs"]
    weight = inputs["omega"]

    for i in 1:NumberOfMinURReqs
        minur_col = Symbol("Min_UtilRate_$i")
        price = dfMinUtilRate[i, :MinUtilRate_Price]
        derated_annual_net_generation = dfPower[1:G, :AnnualSum] .* min_utilrate.(gen, tag = i)
        derated_annual_net_generation[FUSION] .+= thermal_fusion_annual_parasitic_power(
            EP, inputs, setup) .* min_utilrate.(gen[FUSION], tag = i)
        revenue = derated_annual_net_generation * price
        dfMinUtilRateRev[!, minur_col] = revenue
    end
    dfMinUtilRateRev.Total = sum(eachcol(dfMinUtilRateRev[:, 6:(NumberOfMinURReqs + 5)]))
    CSV.write(joinpath(path, "MinUtilRate_Revenue.csv"), dfMinUtilRateRev)
    return dfMinUtilRateRev
end
