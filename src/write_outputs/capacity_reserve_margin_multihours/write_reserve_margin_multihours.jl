function write_reserve_margin_multihours(path::AbstractString, setup::Dict, inputs::Dict, EP::Model)
    NCRM = inputs["NCapacityReserveMargin"]
    selected_hours = inputs["selected_capres_multihours"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    df = DataFrame()

    for res in 1:NCRM
        ts_list = sort(unique(selected_hours[res]))
        isempty(ts_list) && continue  # 防空
        prices = zeros(length(ts_list))

        for (i, t) in enumerate(ts_list)
            # ✅ 安全读取稀疏约束（唯一不崩溃写法）
            if haskey(EP, :cCapacityResMarginMultihour) && haskey(EP[:cCapacityResMarginMultihour], (res, t))
                prices[i] = dual(EP[:cCapacityResMarginMultihour][res, t]) * scale_factor
            else
                prices[i] = 0.0
            end
        end

        temp = DataFrame(Hour=ts_list, Price=prices, Constraint=fill("CapResMulti_$res", length(ts_list)))
        append!(df, temp)
    end

    CSV.write(joinpath(path, "ReserveMargin_multihours.csv"), df)
end