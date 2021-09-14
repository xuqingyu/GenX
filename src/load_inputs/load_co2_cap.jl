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
	load_co2_cap(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2::Dict)

Function for reading input parameters related to CO$_2$ emissions cap constraints
"""
function load_co2_cap(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2::Dict)
	# Definition of Cap requirements by zone (as Max Mtons)
	#inputs_co2["dfCO2Cap"] = CSV.read(string(path,sep,"CO2_cap.csv"), header=true)
	inputs_co2["dfCO2Cap"] = DataFrame(CSV.File(string(path, sep,"CO2_cap.csv"), header=true), copycols=true)
	cap = count(s -> startswith(String(s), "CO_2_Cap_Zone"), names(inputs_co2["dfCO2Cap"]))
	first_col = findall(s -> s == "CO_2_Cap_Zone_1", names(inputs_co2["dfCO2Cap"]))[1]
	last_col = findall(s -> s == "CO_2_Cap_Zone_$cap", names(inputs_co2["dfCO2Cap"]))[1]

	inputs_co2["dfCO2CapZones"] = Matrix{Float64}(inputs_co2["dfCO2Cap"][:,first_col:last_col])
	inputs_co2["NCO2Cap"] = cap




	# Emission limits
	if setup["CO2Cap"]==1
		#  CO2 emissions cap in mass
		first_col = findall(s -> s == "CO_2_Max_Mtons_1", names(inputs_co2["dfCO2Cap"]))[1]
		last_col = findall(s -> s == "CO_2_Max_Mtons_$cap", names(inputs_co2["dfCO2Cap"]))[1]
		# note the default inputs is in million tons
		if setup["ParameterScale"] ==1
			inputs_co2["dfMaxCO2"] = Matrix{Float64}(inputs_co2["dfCO2Cap"][:,first_col:last_col])*(1e6)/ModelScalingFactor
			# when scaled, the constraint unit is kton
		else
			inputs_co2["dfMaxCO2"] = Matrix{Float64}(inputs_co2["dfCO2Cap"][:,first_col:last_col])*(1e6)
			# when not scaled, the constraint unit is ton
		end

	elseif (setup["CO2Cap"]==2 || setup["CO2Cap"]==3)
		#  CO2 emissions rate applied per MWh
		first_col = findall(s -> s == "CO_2_Max_tons_MWh_1", names(inputs_co2["dfCO2Cap"]))[1]
		last_col = findall(s -> s == "CO_2_Max_tons_MWh_$cap", names(inputs_co2["dfCO2Cap"]))[1]
		if setup["ParameterScale"] ==1
			inputs_co2["dfMaxCO2Rate"] = Matrix{Float64}(inputs_co2["dfCO2Cap"][:,first_col:last_col])
			# when scaled, the constraint unit is kton, thus the emission rate should be in kton/GWh = ton/MWh
		else
			inputs_co2["dfMaxCO2Rate"] = Matrix{Float64}(inputs_co2["dfCO2Cap"][:,first_col:last_col])
			# when not scaled, the constraint unit is ton/MWh
		end

	end
	println("CO2_cap.csv Successfully Read!")
	return inputs_co2
end
