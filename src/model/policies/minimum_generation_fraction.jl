@doc raw"""
	minimum_generation_fraction!(EP::Model, inputs::Dict, setup::Dict)
"""
function minimum_generation_fraction!(EP::Model, inputs::Dict, setup::Dict)
    println("Minimum Generation Fraction Policies Module")
    gen = inputs["RESOURCES"]
    # if input files are present, add energy share requirement slack variables
    if haskey(inputs, "MinGenFractionPriceCap")
        @variable(EP, vMinGenFraction_slack[min_gf = 1:inputs["NumberOfMinGenFraction"]]>=0)
        add_similar_to_expression!(EP[:eMinGenFracRes], vMinGenFraction_slack)

        @expression(EP,
            eCMinGenFractionSlack[min_gf = 1:inputs["NumberOfMinGenFraction"]],
            inputs["MinGenFractionPriceCap"][min_gf]*EP[:vMinGenFraction_slack][min_gf])
        @expression(EP,
            eCTotalMinGenFractionSlack,
            sum(EP[:eCMinGenFractionSlack][min_gf] for min_gf in 1:inputs["NumberOfMinGenFraction"]))
        add_to_expression!(EP[:eObj], eCTotalMinGenFractionSlack)
    end

    ## Minimum Capacity Factor Requirement constraint
    @constraint(EP, cMinGenFraction[min_gf = 1:inputs["NumberOfMinGenFraction"]], EP[:eMinGenFracRes][min_gf]>=0)
end