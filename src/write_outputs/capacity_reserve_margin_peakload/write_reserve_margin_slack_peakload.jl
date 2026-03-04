function write_reserve_margin_slack_peakload(path::AbstractString,
        inputs::Dict,
        setup::Dict,
        EP::Model)

    NCRM = inputs["NCapacityReserveMargin"]
    peak_hour = inputs["peak_hour_idx"]   


    slack = value.(EP[:vCapResSlack])     # Vector of length NCRM
    penalty = value.(EP[:eCCapResSlack])  # Vector of length NCRM 

    if setup["ParameterScale"] == 1
        slack .*= ModelScalingFactor    # GW → MW
        penalty .*= ModelScalingFactor^2
    end

    df = DataFrame(
        CRM_Constraint = [Symbol("CapRes_$i") for i in 1:NCRM],
        Slack = slack,
        Penalty = penalty,
        PeakHour = peak_hour
    )

    CSV.write(joinpath(path, "ReserveMargin_prices_and_penalties_peakload.csv"), df)
    return nothing
end
