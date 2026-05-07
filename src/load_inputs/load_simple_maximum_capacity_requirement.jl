@doc raw"""
    load_simple_maximum_capacity_requirement!(path::AbstractString, inputs::Dict, setup::Dict)

Read input parameters related to simple maximum capacity requirement constraints (e.g. technology specific deployment mandates)
"""
function load_simple_maximum_capacity_requirement!(path::AbstractString, inputs::Dict, setup::Dict)
    filename = "Maximum_capacity_requirement_simple.csv"
    df = load_dataframe(joinpath(path, filename))
    inputs["NumberOfSimpleMaxCapReqs"] = nrow(df)
    inputs["SimpleMaxCapReqNames"] = df[!,:ConstraintDescription]
    inputs["MaxCapReqSp"] = df[!, :Max_MW]

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    inputs["MaxCapReqSp"] /= scale_factor
    if "PriceCap" in names(df)
        inputs["MaxCapSpPriceCap"] = df[!, :PriceCap] / scale_factor
    end
    println(filename * " Successfully Read!")
end
