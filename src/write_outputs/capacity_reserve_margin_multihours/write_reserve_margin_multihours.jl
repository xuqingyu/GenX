function write_reserve_margin_multihours(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)
    NCRM = inputs["NCapacityReserve"]
    selected_hours = inputs["selected_capres_multihours"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    df = DataFrame()

    for res in 1:NCRM
        ts_list = sort(unique(selected_hours[res]))
        prices = zeros(length(ts_list))

        for (i, t) in enumerate(ts_list)
            prices[i] = dual(EP[:cCapacityResMarginMulti][res, t]) * scale_factor
        end

        temp = DataFrame(Hour=ts_list, Price=prices, Constraint=fill("CapResMulti_$res", length(ts_list)))
        append!(df, temp)
    end

    CSV.write(joinpath(path, "ReserveMargin_multihours.csv"), df)
end