@doc raw"""
    thermal_plant_effective_capacity_multihours(EP::Model, inputs::Dict, y::Int, capres_zone::Int, t::Int)

Effective capacity for multihours CRM (same logic as peakload).
"""
function thermal_plant_effective_capacity_multihours(
    EP::Model, inputs::Dict, y::Int, capres_zone::Int, t::Int
)
    return _thermal_effective_capacity_multihours(EP, inputs, y, capres_zone, t)
end

function _thermal_effective_capacity_multihours(
    EP::Model, inputs::Dict, y::Int, capres_zone::Int, t::Int
)
    gen = inputs["RESOURCES"]
    capresfactor = derating_factor(gen[y], tag=capres_zone)
    eTotalCap = value(EP[:eTotalCap][y])

    effective_capacity = capresfactor * eTotalCap

    if has_maintenance(inputs) && y in ids_with_maintenance(gen)
        effective_capacity += value(
            thermal_maintenance_capacity_reserve_margin_multihours_adjustment(
                EP, inputs, y, capres_zone, t
            )
        )
    end

    return effective_capacity
end