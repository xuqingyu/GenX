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
	co2_cap(EP::Model, inputs::Dict, setup::Dict)

	hat the generator-side rate-based constraint can be used to represent a fee-rebate (``feebate'') system: the dirty generators that emit above the bar ($\epsilon_{z,p,gen}^{maxCO_2}$) have to buy emission allowances from the emission regulator in the region $z$ where they are located; in the same vein, the clean generators get rebates from the emission regulator at an emission allowance price being the dual variable of the emissions rate constraint.
"""
function co2_credit(EP::Model, inputs::Dict, setup::Dict)

	println("C02 Credit Module")

	dfGen = inputs["dfGen"]
	SEG = inputs["SEG"]  # Number of lines
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	if setup["FLECCS"] >= 1
	    gen_ccs = inputs["dfGen_ccs"]
	end

	### Expressions ###
	# CO2 emissions captured from power plants in "Generator_data.csv"
	@expression(EP, eEmissionsCaptureByPlant[y=1:G,t=1:T],
	if (setup["UCommit"] >= 1 & setup["PieceWiseHeatRate"] ==1)
		if y in inputs["COMMIT"]
			dfGen[!,:CO2_per_MMBTU][y]*EP[:vFuel][y,t]*(dfGen[!,:CO2_Capture_Rate][y]) + dfGen[!,:CO2_per_Start][y]*EP[:vSTART][y,t]
		else
			dfGen[!,:CO2_per_MWh][y]*EP[:vP][y,t]*(dfGen[!,:CO2_Capture_Rate][y])
		end
	else
		if y in inputs["COMMIT"]
			dfGen[!,:CO2_per_MWh][y]*EP[:vP][y,t]*(dfGen[!,:CO2_Capture_Rate][y]) + dfGen[!,:CO2_per_Start][y]*EP[:vSTART][y,t]
		else
			 dfGen[!,:CO2_per_MWh][y]*EP[:vP][y,t]*(dfGen[!,:CO2_Capture_Rate][y])
		end
	end)

	if setup["FLECCS"] >= 1
		# CO2 captured per zone = sum of CO2 captured from generators in the "generator_data.csv" and FLECCS
		@expression(EP, eEmissionsCaptureByZone[z=1:Z, t=1:T], sum(eEmissionsCaptureByPlant[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]) + sum(EP[:vCAPTURE][y,t] for y in unique(gen_ccs[(gen_ccs[!,:Zone].==z),:R_ID])))
	else
		@expression(EP, eEmissionsCaptureByZone[z=1:Z, t=1:T], sum(eEmissionsCaptureByPlant[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]) )
	end
	

    # determine the CO2 credit by mutiplying the capture co2 and co2 credit. This is a negative value.
	@expression(EP, eCCO2Credit[z=1:Z], -inputs["dfCO2Credit"][!,"CO2Credit"][z]*sum(inputs["omega"][t]*EP[:eEmissionsCaptureByZone][z,t] for t in 1:T))

    # sum cross the zones
	@expression(EP, eTotalCCO2Credit,sum(eCCO2Credit[z] for z in 1:Z))
    # add to objective function
	EP[:eObj] += eTotalCCO2Credit

	return EP

end
