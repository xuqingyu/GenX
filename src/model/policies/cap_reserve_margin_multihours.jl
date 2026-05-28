@doc raw"""
	cap_reserve_margin_multihours!(EP::Model, inputs::Dict, setup::Dict)
This module implements capacity reserve margin constraints only on user-specified selected hours/timesteps. It operates similarly to the peakload-only constraint,
but allows multiple critical timesteps to be defined for each zone and reserve requirement.

Constraints are only applied to the exogenously specified t indices, not all timesteps or a single peak hour.
"""
function cap_reserve_margin_multihours!(EP::Model, inputs::Dict, setup::Dict)
    # Capacity reserve margin constraints for EXOGENOUSLY SELECTED HOURS 
    NCRM = inputs["NCapacityReserveMargin"]
    selected_hours = inputs["selected_capres_multihours"]  
    println("Capacity Reserve Margin - Selected Critical Hours Module")

    if haskey(inputs, "dfCapRes_slack")
        @variable(EP, vCapResSlack[res=1:NCRM] >= 0)
        for res in 1:NCRM
            for t in selected_hours[res]
                add_to_expression!(EP[:eCapResMarBalanceMultihour][res, t], EP[:vCapResSlack][res])
            end
        end

        @expression(EP, eCapResSlack_Year[res=1:NCRM], EP[:vCapResSlack][res])
        @expression(EP, eCCapResSlack[res=1:NCRM],
            inputs["dfCapRes_slack"][res, :PriceCap] * EP[:eCapResSlack_Year][res])
        @expression(EP, eCTotalCapResSlack, sum(EP[:eCCapResSlack][res] for res in 1:NCRM))
        add_to_expression!(EP[:eObj], eCTotalCapResSlack)
    end

    @constraint(EP, cCapacityResMarginMultihour[res=1:NCRM, t in selected_hours[res]],
        EP[:eCapResMarBalanceMultihour][res, t]
        >= sum(
            inputs["pD"][t, z] * (1 + inputs["dfCapRes"][z, res])
            for z in findall(!iszero, inputs["dfCapRes"][:, res])
        )
    )
end