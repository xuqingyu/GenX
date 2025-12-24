@doc raw"""
    write_genfrac_revenue_cost(path::AbstractString, inputs::Dict, setup::Dict, dfPower::DataFrame, dfMinCF::DataFrame, EP::Model)
"""
function write_genfrac_revenue_cost(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        dfPower::DataFrame,
        dfMinGenFrac::DataFrame,
        EP::Model)
    gen = inputs["RESOURCES"]
    regions = region.(gen)
    clusters = cluster.(gen)
    zones = zone_id.(gen)
    rid = resource_id.(gen)
    FUSION = ids_with(gen, :fusion)
    
    dfMinGenFracRev = DataFrame(region = regions,
        Resource = inputs["RESOURCE_NAMES"],
        zone = zones,
        Cluster = clusters,
        R_ID = rid)
    G = inputs["G"]
    NumberOfMinGenFraction = inputs["NumberOfMinGenFraction"]
    weight = inputs["omega"]

    for i in 1:NumberOfMinGenFraction
        mingf_col = Symbol("Min_GenFraction_$i")
        price = dfMinGenFrac[i, :MinGenFraction_Price]
        derated_annual_net_generation = dfPower[1:G, :AnnualSum] .* (
            min_genfrac_num.(gen, tag = i)-min_genfrac_den.(gen, tag = i)*inputs["MinGenFraction"][i])
        derated_annual_net_generation[FUSION] .+= thermal_fusion_annual_parasitic_power(EP, inputs, setup) .* (
                min_genfrac_num.(gen[FUSION], tag = i)-min_genfrac_den.(gen[FUSION], tag = i)*inputs["MinGenFraction"][i])
        revenue = derated_annual_net_generation * price
        dfMinGenFracRev[!, mingf_col] = revenue
    end
    dfMinGenFracRev.Total = sum(eachcol(dfMinGenFracRev[:, 6:(NumberOfMinGenFraction + 5)]))
    CSV.write(joinpath(path, "MinGenFraction_Revenue_Cost.csv"), dfMinGenFracRev)
    return dfMinGenFracRev
end
