function write_capacity_subsidy(EP::Model, inputs::Dict, path::AbstractString, setup::Dict)
    println("Writing Capacity Subsidy Outputs")
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    gen = inputs["RESOURCES"]
    G = inputs["G"]
    zones = inputs["R_ZONES"]

    cap_subsidy_per_unit = DataFrame(
        Resource = [resource_name(gen[y]) for y in 1:G],
        Zone = [zones[y] for y in 1:G],
        CapacitySubsidyTotal = value.(EP[:eCapSubsidy][1:G]) .* scale_factor
    )
    CSV.write(joinpath(path, "capacity_subsidy_per_unit.csv"), cap_subsidy_per_unit)

    total_subsidy = DataFrame(
        TotalCapacitySubsidy = [value(EP[:eTotalCapSubsidy]) * scale_factor]
    )
    CSV.write(joinpath(path, "capacity_subsidy_total.csv"), total_subsidy)
end