@doc raw"""
    load_minimum_utilizationrate!(path::AbstractString, inputs::Dict, setup::Dict)

Read input parameters related to minimum utlization rate constraints (e.g. Renewable megabase in China)
"""
function load_minimum_utilizationrate!(path::AbstractString, inputs::Dict, setup::Dict)
    filename = "Minimum_utilization_rate.csv"
    df = load_dataframe(joinpath(path, filename))
    NumberOfMinURReqs = length(df[!, :MinUtilRateConstraint])
    inputs["NumberOfMinURReqs"] = NumberOfMinURReqs
    inputs["MinUtilRate"] = df[!, :Min_UtilRate]

    if "PriceCap" in names(df)
        inputs["MinURPriceCap"] = df[!, :PriceCap]
        if setup["ParameterScale"] == 1
            inputs["MinURPriceCap"] /= ModelScalingFactor # Convert to million $/GW
        end
    end
    println(filename * " Successfully Read!")
end
