function write_virtual_discharge_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    STOR_ALL = inputs["STOR_ALL"]
    isempty(STOR_ALL) && return

    gen = inputs["RESOURCES"]
    selected_hours = inputs["selected_capres_multihours"]
    NCRM = inputs["NCapacityReserve"]
    scale = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    df = DataFrame(
        Resource=inputs["RESOURCE_NAMES"][STOR_ALL],
        Zone=zone_id.(gen)[STOR_ALL]
    )

    for res in 1:NCRM
        ts_list = selected_hours[res]
        virt = zeros(length(STOR_ALL))
        for y in STOR_ALL
            virt[y] = derating_factor(gen[y], tag=res) * value(EP[:eTotalCap][y]) * scale
        end
        df[!, Symbol("CapResMulti_$res")] = virt
    end

    CSV.write(joinpath(path, "virtual_discharge_multihours.csv"), df)
end