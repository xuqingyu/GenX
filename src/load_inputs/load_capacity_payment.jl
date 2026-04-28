@doc raw"""
    load_capacity_payment!(setup::Dict, inputs::Dict)

Read input parameters related to exogenous capacity payment policy from resources CSV.
"""
function load_capacity_payment!(setup::Dict, path::AbstractString, inputs::Dict)
    gen = inputs["RESOURCES"]
    G = inputs["G"]
    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    inputs["cap_sub_price"] = [capacity_payment(gen[g]) for g in 1:G]
    inputs["cap_sub_price"] ./= scale_factor

    println("Capacity payment Successfully Read from resources CSV!")
end