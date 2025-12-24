@doc raw"""
	minimum_utilizationrate!(EP::Model, inputs::Dict, setup::Dict)
"""
function minimum_utilizationrate!(EP::Model, inputs::Dict, setup::Dict)
    println("Minimum Utilization Rate Requirement Policies Module")
    gen = inputs["RESOURCES"]
    T = inputs["T"]
    # if input files are present, add energy share requirement slack variables
    if haskey(inputs, "MinURPriceCap")
        @variable(EP, vMinUR_slack[min_ur = 1:inputs["NumberOfMinURReqs"]]>=0)
        add_similar_to_expression!(EP[:eMinUtilRateRes], vMinUR_slack)

        @expression(EP,
            eCMinURSlack[min_ur = 1:inputs["NumberOfMinURReqs"]],
            inputs["MinURPriceCap"][min_ur]*EP[:vMinUR_slack][min_ur])
        @expression(EP,
            eCTotalMinURSlack,
            sum(EP[:eCMinURSlack][min_ur] for min_ur in 1:inputs["NumberOfMinURReqs"]))
        add_to_expression!(EP[:eObj], eCTotalMinURSlack)
    end


    @expression(EP, eMinURTarget[nmin_ur = 1:inputs["NumberOfMinURReqs"]],
        -sum(inputs["MinUtilRate"][nmin_ur] * EP[:eTotalCap][y] * inputs["pP_Max"][y, t] * inputs["omega"][t]
        for y in ids_with_policy(gen, min_utilrate, tag = nmin_ur), t in 1:T))
    add_similar_to_expression!(EP[:eMinUtilRateRes], eMinURTarget)


    ## Minimum Capacity Factor Requirement constraint
    @constraint(EP, cMinUR[min_ur = 1:inputs["NumberOfMinURReqs"]], EP[:eMinUtilRateRes][min_ur]>=0)
end