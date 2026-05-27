function write_reserve_margin_slack_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    NCRM = inputs["NCapacityReserve"]
    selected_hours = inputs["selected_capres_multihours"]
    scale = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    df = DataFrame()

    for res in 1:NCRM
        ts_list = selected_hours[res]
        slack_val = value(EP[:vCapResMultiSlack][res])
        penalty_val = value(EP[:eCCapResMultiSlack][res])

        push!(df, (
            Constraint = "CapResMulti_$res",
            Hours = ts_list,
            Slack = slack_val * scale,
            Penalty = penalty_val * scale^2
        ))
    end

    CSV.write(joinpath(path, "ReserveMargin_prices_and_penalties_multihours.csv"), df)
end