function write_reserve_margin_revenue_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    gen = inputs["RESOURCES"]
    G = inputs["G"]
    selected_hours = inputs["selected_capres_multihours"]
    NCRM = inputs["NCapacityReserveMargin"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    eTotalCap = value.(EP[:eTotalCap])
    df = DataFrame(
        Region=region.(gen),
        Resource=inputs["RESOURCE_NAMES"],
        Zone=zone_id.(gen),
        Cluster=cluster.(gen)
    )
    annual_sum = zeros(G)

    for res in 1:NCRM
        ts_list = selected_hours[res]
        isempty(ts_list) && continue
        revenue = zeros(G)

        for t in ts_list
            price = 0.0
            if haskey(EP, :cCapacityResMarginMultihour) && haskey(EP[:cCapacityResMarginMultihour], (res, t))
                price = dual(EP[:cCapacityResMarginMultihour][res, t]) * scale_factor
            end
            for y in 1:G
                if y in inputs["THERM_ALL"]
                    cap = thermal_plant_effective_capacity_multihours(EP, inputs, y, res, t)
                elseif y in union(inputs["VRE"], inputs["HYDRO_RES"], inputs["STOR_ALL"], inputs["MUST_RUN"])
                    cap = derating_factor(gen[y], tag=res) * eTotalCap[y]
                else
                    cap = 0.0
                end
                revenue[y] += cap * price
            end
        end

        df[!, Symbol("CapResMulti_$res")] = revenue
        annual_sum .+= revenue
    end

    df[!, :AnnualSum] = annual_sum
    CSV.write(joinpath(path, "ReserveMarginRevenue_multihours.csv"), df)
    return df
end