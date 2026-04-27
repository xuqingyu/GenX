@doc raw"""
	capacity_subsidy!(EP::Model, inputs::Dict, setup::Dict)

Capacity Subsidy Policy Module
This module adds exogenous capacity subsidy revenue to the objective function (as negative cost).
Subsidy = (Existing Capacity + New Built Capacity) x Subsidy Price
Objective: minimize total cost - total subsidy revenue
"""
function capacity_subsidy!(EP::Model, inputs::Dict, setup::Dict)
    println("Capacity Subsidy Module")

    G = inputs["G"]
    cap_sub_price = inputs["cap_sub_price"]
    eTotalCap = EP[:eTotalCap]

    for y in 1:G
        EP[:eCapSubsidy][y] = cap_sub_price[y] * eTotalCap[y]
    end

    @expression(EP, eTotalCapSubsidy, sum(EP[:eCapSubsidy][y] for y in 1:G))
    add_to_expression!(EP[:eObj], -1.0, eTotalCapSubsidy)
end