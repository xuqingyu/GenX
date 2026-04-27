@doc raw"""
    load_capacity_subsidy!(setup::Dict, inputs::Dict)

Read input parameters related to exogenous capacity subsidy policy from resources CSV.
"""
function load_capacity_subsidy!(setup::Dict, path::AbstractString, inputs::Dict)
    gen = inputs["RESOURCES"]
    G = inputs["G"]

    inputs["cap_sub_price"] = [capacity_subsidy(gen[g]) for g in 1:G]

    scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
    inputs["cap_sub_price"] ./= scale_factor

    println("Capacity Subsidy Successfully Read from resources CSV!")
end