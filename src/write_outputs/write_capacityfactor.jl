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
	write_capacityfactor(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the capacity factor of different resources.
"""
function write_capacityfactor(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfGen = inputs["dfGen"]
    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)
    THERM_ALL = inputs["THERM_ALL"]
    VRE = inputs["VRE"]
    HYDRO_RES = inputs["HYDRO_RES"]
    MUST_RUN = inputs["MUST_RUN"]

    dfCapacityfactor = DataFrame(Resource=inputs["RESOURCES"], Zone=dfGen[!, :Zone], AnnualSum=zeros(G), Capacity=zeros(G), CapacityFactor=zeros(G))
    if setup["ParameterScale"] == 1
        dfCapacityfactor.AnnualSum .= value.(EP[:vP]) * inputs["omega"] * ModelScalingFactor
        dfCapacityfactor.Capacity .= value.(EP[:eTotalCap]) * ModelScalingFactor
    else
        dfCapacityfactor.AnnualSum .= value.(EP[:vP]) * inputs["omega"]
        dfCapacityfactor.Capacity .= value.(EP[:eTotalCap])
    end
    # We only calculate the resulted capacity factor with total capacity > 1MW and total generation > 1MWh
    EXISTING = intersect(findall(x -> x >= 1, dfCapacityfactor.AnnualSum), findall(x -> x >= 1, dfCapacityfactor.Capacity))
    # We calculate capacity factor for thermal, vre, hydro and must run. Not for storage and flexible demand
    CF_GEN = intersect(union(THERM_ALL, VRE, HYDRO_RES, MUST_RUN), EXISTING)
    dfCapacityfactor.CapacityFactor[CF_GEN] .= (dfCapacityfactor.AnnualSum[CF_GEN] ./ dfCapacityfactor.Capacity[CF_GEN]) / sum(inputs["omega"][t] for t in 1:T)

    # VRE-Storage Module
    if setup["VreStor"] == 1
        dfGen_VRE_STOR = inputs["dfGen_VRE_STOR"]
		VRE_STOR = inputs["VRE_STOR"]
        dfCapacityfactorVRESTOR = DataFrame(Resource=inputs["RESOURCES_VRE"], Zone=dfGen_VRE_STOR[!, :Zone], AnnualSum=zeros(VRE_STOR), Capacity=zeros(VRE_STOR), CapacityFactor=zeros(VRE_STOR))
        if setup["ParameterScale"] == 1
            dfCapacityfactorVRESTOR.AnnualSum .= value.(EP[:vP_DC]) * dfGen_VRE_STOR[!,:EtaInverter] * inputs["omega"] * ModelScalingFactor
            dfCapacityfactorVRESTOR.Capacity .= value.(EP[:eTotalCap_VRE]) * ModelScalingFactor
        else
            dfCapacityfactorVRESTOR.AnnualSum .= value.(EP[:vP_DC]) * dfGen_VRE_STOR[!,:EtaInverter] * inputs["omega"]
            dfCapacityfactorVRESTOR.Capacity .= value.(EP[:eTotalCap_VRE])
        end
        # We only calculate the resulted capacity factor with total capacity > 1MW and total generation > 1MWh
        EXISTING_VRESTOR = intersect(findall(x -> x >= 1, dfCapacityfactorVRESTOR.AnnualSum), findall(x -> x >= 1, dfCapacityfactorVRESTOR.Capacity))
        dfCapacityfactorVRESTOR.CapacityFactor[EXISTING_VRESTOR] .= (dfCapacityfactorVRESTOR.AnnualSum[EXISTING_VRESTOR] ./ dfCapacityfactorVRESTOR.Capacity[EXISTING_VRESTOR]) / sum(inputs["omega"][t] for t in 1:T)
        dfCapacityfactor = vcat(dfCapacityfactor, dfCapacityfactorVRESTOR)
        CSV.write(joinpath(path, "vrestor_capacityfactor.csv"), dfCapacityfactorVRESTOR)
    end

    CSV.write(joinpath(path, "capacityfactor.csv"), dfCapacityfactor)
    return dfCapacityfactor
end
