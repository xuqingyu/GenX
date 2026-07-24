function write_reserve_margin_slack_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    NCRM = inputs["NCapacityReserveMargin"]
    selected_hours = inputs["selected_capres_multihours"]
    scale = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    df = DataFrame(Constraint = String[], Hour = Int[], Slack = Float64[], Penalty = Float64[])

    for res in 1:NCRM
        penalty_val = value(EP[:eCCapResSlack][res])

        for t in selected_hours[res]
            slack_val = value(EP[:vCapResSlack][res,t])

            push!(df, (
                Constraint = "CapResMulti_$res",
                Hour = t,
                Slack = slack_val * scale,
                Penalty = penalty_val * scale^2
            ))
        end
    end

    CSV.write(joinpath(path, "ReserveMargin_prices_and_penalties_multihours.csv"), df)
end