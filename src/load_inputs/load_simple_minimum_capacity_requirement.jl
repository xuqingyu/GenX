@doc raw"""
    load_simple_minimum_capacity_requirement!(path::AbstractString, inputs::Dict, setup::Dict)

Read input parameters related to simple minimum capacity requirement constraints (e.g. technology specific deployment mandates)
"""
function load_simple_minimum_capacity_requirement!(path::AbstractString, inputs::Dict, setup::Dict)
    filename = "Minimum_capacity_requirement_simple.csv"
    df = load_dataframe(joinpath(path, filename))
    inputs["NumberOfSimpleMinCapReqs"] = nrow(df)
    inputs["SimpleMinCapReqNames"] = df[!,:ConstraintDescription]
    inputs["MinCapReqSp"] = df[!, :Min_MW]

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    inputs["MinCapReqSp"] /= scale_factor
    if "PriceCap" in names(df)
        inputs["MinCapSpPriceCap"] = df[!, :PriceCap] / scale_factor
    end
    println(filename * " Successfully Read!")
end
