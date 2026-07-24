
function cap_reserve_margin_peakload!(EP::Model, inputs::Dict, setup::Dict)
    # capacity reserve margin constraint with peakload only
    NCRM = inputs["NCapacityReserveMargin"]
    peak_idx = inputs["peak_hour_idx"]
    println("Capacity Reserve Margin Policies with peakload only Module")

    # if input files are present, add capacity reserve margin slack variables
    if haskey(inputs, "dfCapRes_slack")
        @variable(EP, vCapResSlack[res=1:NCRM] >= 0)
        for res in 1:NCRM
            add_to_expression!(EP[:eCapResMarBalancePeak][res], EP[:vCapResSlack][res])
        end 

        @expression(EP, 
        eCapResSlack_Year[res = 1:NCRM],
        EP[:vCapResSlack][res])

        @expression(EP,
            eCCapResSlack[res = 1:NCRM],
            inputs["dfCapRes_slack"][res, :PriceCap]*EP[:eCapResSlack_Year][res])

        @expression(EP, eCTotalCapResSlack,sum(EP[:eCCapResSlack][res] for res in 1:NCRM))
        add_to_expression!(EP[:eObj], eCTotalCapResSlack)
    end

        @constraint(EP,
                cCapacityResMargin[res = 1:NCRM],
                EP[:eCapResMarBalancePeak][res]
                >= sum(
                    inputs["pD"][peak_idx[res], z] * 
                    (1 + inputs["dfCapRes"][z, res])
                    for z in findall(!iszero, inputs["dfCapRes"][:, res])))
end

