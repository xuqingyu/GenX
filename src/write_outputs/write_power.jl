"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_power(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the different values of power generated by the different technologies in operation.
"""
function write_power(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfGen = inputs["dfGen"]
    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)

    # Power injected by each resource in each time step
    dfPower = DataFrame(Resource = inputs["RESOURCES"], Zone = dfGen[!, :Zone], AnnualSum = Array{Union{Missing,Float64}}(undef, G))
    if setup["ParameterScale"] == 1
        dfPower.AnnualSum .= value.(EP[:vP]) * inputs["omega"] * ModelScalingFactor
        dfPower = hcat(dfPower, DataFrame((value.(EP[:vP])) * ModelScalingFactor, :auto))
    else
        dfPower.AnnualSum .= value.(EP[:vP]) * inputs["omega"] * ModelScalingFactor
        dfPower = hcat(dfPower, DataFrame(value.(EP[:vP]), :auto))
    end

    auxNew_Names = [Symbol("Resource"); Symbol("Zone"); Symbol("AnnualSum"); [Symbol("t$t") for t in 1:T]]
    rename!(dfPower, auxNew_Names)

    total = DataFrame(["Total" 0 sum(dfPower[!, :AnnualSum]) fill(0.0, (1, T))], :auto)
	if v"1.3" <= VERSION < v"1.4"
	    total[!, 4:T+3] .= sum(value.(EP[:vP]), dims = 1) # summing over the first dimension, g, so the result is a horizonalal array with dimension t
	elseif v"1.4" <= VERSION < v"1.7"
	    total[:, 4:T+3] .= sum(value.(EP[:vP]), dims = 1)
	end

    rename!(total, auxNew_Names)
    dfPower = vcat(dfPower, total)
    CSV.write(string(path, sep, "power.csv"), dftranspose(dfPower, false), writeheader = false)
    return dfPower
end
