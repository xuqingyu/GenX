function write_reserve_margin_revenue_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    gen = inputs["RESOURCES"]
    G = inputs["G"]
    selected_hours = inputs["selected_capres_multihours"]
    NCRM = inputs["NCapacityReserve"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    eTotalCap = value.(EP[:eTotalCap])
    df = DataFrame(
        Region=region.(gen),
        Resource=inputs["RESOURCE_NAMES"],
        Zone=zone_id.(gen),
        Cluster=cluster.(gen)
    )
    annual_total = zeros(G)

    for res in 1:NCRM
        ts_list = selected_hours[res]
        revenue = zeros(G)

        for t in ts_list
            price = dual(EP[:cCapacityResMarginMulti][res, t]) * scale_factor
            for y in inputs["THERM_ALL"]
                revenue[y] += thermal_plant_effective_capacity_multihours(EP, inputs, y, res, t) * price
            end
            for y in union(inputs["VRE"], inputs["HYDRO_RES"], inputs["STOR_ALL"], inputs["MUST_RUN"])
                revenue[y] += derating_factor(gen[y], tag=res) * eTotalCap[y] * price
            end
        end

        df[!, Symbol("CapResMulti_$res")] = revenue
        annual_total .+= revenue
    end

    df[!, :AnnualTotal] = annual_total
    CSV.write(joinpath(path, "ReserveMarginRevenue_multihours.csv"), df)
    return df
end