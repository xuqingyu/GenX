function write_capacity_value_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    gen = inputs["RESOURCES"]
    G = inputs["G"]
    zones = zone_id.(gen)
    selected_hours = inputs["selected_capres_multihours"]
    NCRM = inputs["NCapacityReserve"]

    THERM_ALL = inputs["THERM_ALL"]
    VRE = inputs["VRE"]
    HYDRO_RES = inputs["HYDRO_RES"]
    STOR_ALL = inputs["STOR_ALL"]
    MUST_RUN = inputs["MUST_RUN"]

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    eTotalCap = value.(EP[:eTotalCap])

    df = DataFrame()

    for res in 1:NCRM
        ts_list = sort(unique(selected_hours[res]))
        capvalue = zeros(G, length(ts_list))

        for (i, t) in enumerate(ts_list)
            for y in THERM_ALL
                capvalue[y,i] = thermal_plant_effective_capacity_multihours(EP, inputs, y, res, t)
            end
            for y in VRE
                capvalue[y,i] = derating_factor(gen[y], tag=res) * eTotalCap[y]
            end
            for y in HYDRO_RES
                capvalue[y,i] = derating_factor(gen[y], tag=res) * eTotalCap[y]
            end
            for y in STOR_ALL
                capvalue[y,i] = derating_factor(gen[y], tag=res) * eTotalCap[y]
            end
            for y in MUST_RUN
                capvalue[y,i] = derating_factor(gen[y], tag=res) * eTotalCap[y]
            end
        end

        temp_df = DataFrame(capvalue, :auto)
        rename!(temp_df, [Symbol("t$t") for t in ts_list])
        temp_df = hcat(
            DataFrame(Resource=inputs["RESOURCE_NAMES"], Zone=zones, Reserve=fill("CapResMulti_$res", G)),
            temp_df
        )
        append!(df, temp_df)
    end

    write_simple_csv(joinpath(path, "CapacityValue_multihours.csv"), df)
end