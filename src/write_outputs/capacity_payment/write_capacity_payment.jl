function write_capacity_payment(EP::Model, inputs::Dict, path::AbstractString, setup::Dict)
    println("Writing Capacity Payment Outputs")
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1

    gen = inputs["RESOURCES"]
    G = inputs["G"]
    zones = inputs["R_ZONES"]

    cap_payment_per_unit = DataFrame(
        Resource = [resource_name(gen[y]) for y in 1:G],
        Zone = [zones[y] for y in 1:G],
        CapacityPaymentTotal = value.(EP[:eCapPayment][1:G]) .* scale_factor
    )
    CSV.write(joinpath(path, "capacity_payment_per_unit.csv"), cap_payment_per_unit)

    total_payment = DataFrame(
        TotalCapacityPayment = [value(EP[:eTotalCapPayment]) * scale_factor]
    )
    CSV.write(joinpath(path, "capacity_payment_total.csv"), total_payment)
end