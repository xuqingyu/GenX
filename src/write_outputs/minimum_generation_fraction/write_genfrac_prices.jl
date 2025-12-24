function write_genfrac_prices(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfMinGenFrac = DataFrame(MinGenFraction_Price = convert(Array{Float64}, dual.(EP[:cMinGenFraction])))
    if setup["ParameterScale"] == 1
        # Converting MillionUS$/GWh to US$/MWh
        dfMinGenFrac[!, :MinGenFraction_Price] = dfMinGenFrac[!, :MinGenFraction_Price] * ModelScalingFactor 
    end

    if haskey(inputs, "MinGenFractionPriceCap")
        dfMinGenFrac[!, :MinGenFrac_AnnualSlack] = convert(Array{Float64}, value.(EP[:vMinGenFraction_slack]))
        dfMinGenFrac[!, :MinGenFrac_AnnualPenalty] = convert(Array{Float64}, value.(EP[:eCMinGenFractionSlack]))
        if setup["ParameterScale"] == 1
            dfMinGenFrac[!, :MinGenFrac_AnnualSlack] *= ModelScalingFactor # Converting GWh to MWh
            dfMinGenFrac[!, :MinGenFrac_AnnualPenalty] *= (ModelScalingFactor^2) # Converting MillionUSD to USD
        end
    end
    CSV.write(joinpath(path, "MinGenFraction_prices_and_penalties.csv"), dfMinGenFrac)
    return dfMinGenFrac
end
