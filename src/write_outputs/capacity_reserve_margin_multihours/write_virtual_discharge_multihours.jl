function write_virtual_discharge_multihours(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    STOR_ALL = inputs["STOR_ALL"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    NCRM = inputs["NCapacityReserveMargin"]
    resources = inputs["RESOURCE_NAMES"][STOR_ALL]
    zones = inputs["R_ZONES"][STOR_ALL]
    gen = inputs["RESOURCES"]

    df = DataFrame(Resource = resources, Zone = zones)

    for res in 1:NCRM
        virt = [
            derating_factor(gen[y], tag=res) * value(EP[:eTotalCap][y]) * scale_factor
            for y in STOR_ALL
        ]

        df[!, Symbol("CapResMulti_$res")] = virt
    end

    CSV.write(joinpath(path, "virtual_discharge_multihours.csv"), df)
    return nothing
end