@doc raw"""
    write_mincf_revenue(path::AbstractString, inputs::Dict, setup::Dict, dfPower::DataFrame, dfMinCF::DataFrame, EP::Model)
"""
function write_mincf_revenue(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        dfPower::DataFrame,
        dfMinCF::DataFrame,
        EP::Model)
    gen = inputs["RESOURCES"]
    regions = region.(gen)
    clusters = cluster.(gen)
    zones = zone_id.(gen)
    rid = resource_id.(gen)
    FUSION = ids_with(gen, :fusion)
    
    dfMinCFRev = DataFrame(region = regions,
        Resource = inputs["RESOURCE_NAMES"],
        zone = zones,
        Cluster = clusters,
        R_ID = rid)
    G = inputs["G"]
    NumberOfMinCFReqs = inputs["NumberOfMinCFReqs"]
    weight = inputs["omega"]

    for i in 1:NumberOfMinCFReqs
        mincf_col = Symbol("Min_CF_$i")
        price = dfMinCF[i, :MinCF_Price]
        derated_annual_net_generation = dfPower[1:G, :AnnualSum] .* min_cf.(gen, tag = i)
        derated_annual_net_generation[FUSION] .+= thermal_fusion_annual_parasitic_power(
            EP, inputs, setup) .* min_cf.(gen[FUSION], tag = i)
        revenue = derated_annual_net_generation * price
        dfMinCFRev[!, mincf_col] = revenue
    end
    dfMinCFRev.Total = sum(eachcol(dfMinCFRev[:, 6:(NumberOfMinCFReqs + 5)]))
    CSV.write(joinpath(path, "MinCF_Revenue.csv"), dfMinCFRev)
    return dfMinCFRev
end
