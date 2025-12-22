@doc raw"""
    load_minimum_capacityfactor_requirement!(path::AbstractString, inputs::Dict, setup::Dict)

Read input parameters related to minimum capacity factor constraints (e.g. Renewable megabase in China)
"""
function load_minimum_capacityfactor_requirement!(path::AbstractString, inputs::Dict, setup::Dict)
    filename = "Minimum_capacity_factor.csv"
    df = load_dataframe(joinpath(path, filename))
    NumberOfMinCFReqs = length(df[!, :MinCFConstraint])
    inputs["NumberOfMinCFReqs"] = NumberOfMinCFReqs
    inputs["MinCF"] = df[!, :Min_CF]

    if "PriceCap" in names(df)
        inputs["MinCFPriceCap"] = df[!, :PriceCap]
        if setup["ParameterScale"] == 1
            inputs["MinCFPriceCap"] /= ModelScalingFactor # Convert to million $/GW
        end
    end
    println(filename * " Successfully Read!")
end
