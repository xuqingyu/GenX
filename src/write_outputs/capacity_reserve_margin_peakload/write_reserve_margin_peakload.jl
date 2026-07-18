function write_reserve_margin_peakload(path::AbstractString,setup::Dict,inputs::Dict, EP::Model)
    NCRM = inputs["NCapacityReserveMargin"]
    peak_hour_idx = inputs["peak_hour_idx"]
    res_margin_price = [try JuMP.dual(EP[:cCapacityResMargin][i]) catch _ nothing end
                        for i in 1:NCRM]
    if setup["ParameterScale"] == 1
        res_margin_price .*= ModelScalingFactor
    end
    dfResMar = DataFrame(
        CRM_Constraint = [Symbol("CapRes_$i") for i in 1:NCRM],
        Price = res_margin_price,
        PeakHour = peak_hour_idx
    )
    CSV.write(joinpath(path, "ReserveMargin_peakload.csv"), dfResMar)
    return nothing
end