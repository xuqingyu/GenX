@doc raw"""
	capacity_payment!(EP::Model, inputs::Dict, setup::Dict)

Capacity payment Policy Module
This module adds exogenous capacity payment revenue to the objective function (as negative cost).
payment = (Existing Capacity + New Built Capacity) x payment Price
Objective: minimize total cost - total payment revenue
"""
function capacity_payment!(EP::Model, inputs::Dict, setup::Dict)
    println("Capacity payment Module")

    G = inputs["G"]
    cap_sub_price = inputs["cap_sub_price"]
    eTotalCap = EP[:eTotalCap]

    for y in 1:G
        EP[:eCapPayment][y] = cap_sub_price[y] * eTotalCap[y]
    end

    @expression(EP, eTotalCapPayment, sum(EP[:eCapPayment][y] for y in 1:G))
    add_to_expression!(EP[:eObj], -1.0, eTotalCapPayment)
end