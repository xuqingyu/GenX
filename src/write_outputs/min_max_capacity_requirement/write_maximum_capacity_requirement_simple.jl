function write_maximum_capacity_requirement_simple(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        EP::Model)
    NumberOfMaxCapReqs = inputs["NumberOfSimpleMaxCapReqs"]
    dfMaxCapSpPrice = DataFrame(
        Constraint = [Symbol("MaxCapReqSp_$maxcap")
                      for maxcap in 1:NumberOfMaxCapReqs],
        ConstraintDescription = inputs["SimpleMaxCapReqNames"],
        Price = -dual.(EP[:cZoneMaxCapReqSp]))

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    dfMaxCapSpPrice.Price *= scale_factor

    if haskey(inputs, "MaxCapSpPriceCap")
        dfMaxCapSpPrice[!, :Slack] = convert(Array{Float64}, value.(EP[:vMaxCapSp_slack]))
        dfMaxCapSpPrice[!, :Penalty] = convert(Array{Float64}, value.(EP[:eCMaxCapSp_slack]))
        dfMaxCapSpPrice.Slack *= scale_factor # Convert GW to MW
        dfMaxCapSpPrice.Penalty *= scale_factor^2 # Convert Million $ to $
    end
    CSV.write(joinpath(path, "MaxCapReq_Simple_prices_and_penalties.csv"), dfMaxCapSpPrice)
end
