function write_reserve_margin_w_peakload(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    NCRM = inputs["NCapacityReserveMargin"]
    peak_hour_idx = inputs["peak_hour_idx"]

    w = [dual(EP[:cCapacityResMargin][i]) for i in 1:NCRM]

    if setup["ParameterScale"] == 1
        w .*= ModelScalingFactor   # MillionUS$/GWh -> US$/MWh
    end

    df = DataFrame(
        CRM_Constraint = [Symbol("CapRes_$i") for i in 1:NCRM],
        Price = w,
        PeakHour = peak_hour_idx
    )

    CSV.write(joinpath(path, "ReserveMargin_w_peakload.csv"), df)
end
