function write_utilrate_prices(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfMinUtilRate = DataFrame(MinUtilRate_Price = convert(Array{Float64}, dual.(EP[:cMinUR])))
    if setup["ParameterScale"] == 1
        # Converting MillionUS$/GWh to US$/MWh
        dfMinUtilRate[!, :MinUtilRate_Price] = dfMinUtilRate[!, :MinUtilRate_Price] * ModelScalingFactor 
    end

    if haskey(inputs, "MinURPriceCap")
        dfMinUtilRate[!, :MinUtilRate_AnnualSlack] = convert(Array{Float64}, value.(EP[:vMinUR_slack]))
        dfMinUtilRate[!, :MinUtilRate_AnnualPenalty] = convert(Array{Float64}, value.(EP[:eCMinURSlack]))
        if setup["ParameterScale"] == 1
            dfMinUtilRate[!, :MinUtilRate_AnnualSlack] *= ModelScalingFactor # Converting GWh to MWh
            dfMinUtilRate[!, :MinUtilRate_AnnualPenalty] *= (ModelScalingFactor^2) # Converting MillionUSD to USD
        end
    end
    CSV.write(joinpath(path, "MinUtilRate_prices_and_penalties.csv"), dfMinUtilRate)
    return dfMinUtilRate
end
