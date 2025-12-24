@doc raw"""
    load_minimum_generation_fraction!(setup::Dict, path::AbstractString, inputs::Dict)

Read input parameters related to minimum generation fraction requirement constraints
"""
function load_minimum_generation_fraction!(path::AbstractString, inputs::Dict, setup::Dict)
    filename = "Minimum_generation_fraction.csv"
    df = load_dataframe(joinpath(path, filename))
    NumberOfMinGenFraction = length(df[!, :MinGenFractionConstraint])
    inputs["NumberOfMinGenFraction"] = NumberOfMinGenFraction
    inputs["MinGenFraction"] = df[!, :MinGenFraction]

    if "PriceCap" in names(df)
        inputs["MinGenFractionPriceCap"] = df[!, :PriceCap]
        if setup["ParameterScale"] == 1
            inputs["MinGenFractionPriceCap"] /= ModelScalingFactor # Convert to million $/GW
        end
    end
    println(filename * " Successfully Read!")
end
