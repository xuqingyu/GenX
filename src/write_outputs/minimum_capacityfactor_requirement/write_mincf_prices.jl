function write_mincf_prices(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfMinCF = DataFrame(MinCF_Price = convert(Array{Float64}, dual.(EP[:cMinCF])))
    if setup["ParameterScale"] == 1
        dfMinCF[!, :MinCF_Price] = dfMinCF[!, :MinCF_Price] * ModelScalingFactor # Converting MillionUS$/GWh to US$/MWh
    end

    if haskey(inputs, "MinCFPriceCap")
        dfMinCF[!, :MinCF_AnnualSlack] = convert(Array{Float64}, value.(EP[:vMinCF_slack]))
        dfMinCF[!, :MinCF_AnnualPenalty] = convert(Array{Float64}, value.(EP[:eCMinCFSlack]))
        if setup["ParameterScale"] == 1
            dfMinCF[!, :MinCF_AnnualSlack] *= ModelScalingFactor # Converting GWh to MWh
            dfMinCF[!, :MinCF_AnnualPenalty] *= (ModelScalingFactor^2) # Converting MillionUSD to USD
        end
    end
    CSV.write(joinpath(path, "MinCF_prices_and_penalties.csv"), dfMinCF)
    return dfMinCF
end
