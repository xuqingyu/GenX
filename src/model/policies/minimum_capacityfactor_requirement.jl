@doc raw"""
	minimum_capacity_factor_requirement!(EP::Model, inputs::Dict, setup::Dict)
"""
function minimum_capacity_factor_requirement!(EP::Model, inputs::Dict, setup::Dict)
    println("Minimum Capacity Factor Requirement Policies Module")
    gen = inputs["RESOURCES"]
    # if input files are present, add energy share requirement slack variables
    if haskey(inputs, "MinCFPriceCap")
        @variable(EP, vMinCF_slack[min_cf = 1:inputs["NumberOfMinCFReqs"]]>=0)
        add_similar_to_expression!(EP[:eMinCFRes], vMinCF_slack)

        @expression(EP,
            eCMinCFSlack[min_cf = 1:inputs["NumberOfMinCFReqs"]],
            inputs["MinCFPriceCap"][min_cf]*EP[:vMinCF_slack][min_cf])
        @expression(EP,
            eCTotalMinCFSlack,
            sum(EP[:eCMinCFSlack][min_cf] for min_cf in 1:inputs["NumberOfMinCFReqs"]))

        add_to_expression!(EP[:eObj], eCTotalMinCFSlack)
    end


    @expression(EP, eMinCFTarget[nmin_cf = 1:inputs["NumberOfMinCFReqs"]],
        -sum(inputs["MinCF"][nmin_cf] * EP[:eTotalCap][y] * sum(inputs["omega"])
        for y in ids_with_policy(gen, min_cf, tag = nmin_cf)))
    add_similar_to_expression!(EP[:eMinCFRes], eMinCFTarget)


    ## Minimum Capacity Factor Requirement constraint
    @constraint(EP, cMinCF[min_cf = 1:inputs["NumberOfMinCFReqs"]], EP[:eMinCFRes][min_cf]>=0)
end