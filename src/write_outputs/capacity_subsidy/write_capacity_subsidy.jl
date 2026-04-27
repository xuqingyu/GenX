function write_capacity_subsidy(EP::Model, inputs::Dict, path::AbstractString, setup::Dict)
    println("Writing Capacity Subsidy Outputs")

    gen = inputs["RESOURCES"]
    G = inputs["G"]
    zones = inputs["R_ZONES"]

    # 1. subsidy for every unit
    cap_subsidy_per_unit = DataFrame(
        Resource = [resource_name(gen[y]) for y in 1:G],
        Zone = [zones[y] for y in 1:G],
        CapacitySubsidyTotal = value.(EP[:eCapSubsidy][1:G])
    )
    CSV.write(joinpath(path, "capacity_subsidy_per_unit.csv"), cap_subsidy_per_unit)

    # 2. total subsidy
    total_subsidy = DataFrame(
        TotalCapacitySubsidy = [value(EP[:eTotalCapSubsidy])]
    )
    CSV.write(joinpath(path, "capacity_subsidy_total.csv"), total_subsidy)
end