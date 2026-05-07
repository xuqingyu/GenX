function write_minimum_capacity_requirement_simple(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        EP::Model)
    NumberOfMinCapReqs = inputs["NumberOfSimpleMinCapReqs"]
    dfMaxCapSpPrice = DataFrame(
        Constraint = [Symbol("MinCapReqSp_$mincap")
                      for mincap in 1:NumberOfMinCapReqs],
        ConstraintDescription = inputs["SimpleMinCapReqNames"],
        Price = -dual.(EP[:cZoneMinCapReqSp]))

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    dfMinCapSpPrice.Price *= scale_factor

    if haskey(inputs, "MinCapSpPriceCap")
        dfMinCapSpPrice[!, :Slack] = convert(Array{Float64}, value.(EP[:vMinCapSp_slack]))
        dfMinCapSpPrice[!, :Penalty] = convert(Array{Float64}, value.(EP[:eCMinCapSp_slack]))
        dfMinCapSpPrice.Slack *= scale_factor # Convert GW to MW
        dfMinCapSpPrice.Penalty *= scale_factor^2 # Convert Million $ to $
    end
    CSV.write(joinpath(path, "MinCapReq_Simple_prices_and_penalties.csv"), dfMinCapSpPrice)
end
