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
	discharge(EP::Model, inputs::Dict)

This module defines the power decision variable $\Theta_{y,t} \forall y \in \mathcal{G}, t \in \mathcal{T}$, representing energy injected into the grid by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources $y \in \mathcal{G}$ over all time periods $t \in \mathcal{T}$:

```math
\begin{aligned}
	Obj_{Var\_gen} =
	\sum_{y \in \mathcal{G} } \sum_{t \in \mathcal{T}}\omega_{t}\times(\pi^{VOM}_{y} + \pi^{FUEL}_{y})\times \Theta_{y,t}
\end{aligned}
```

"""
function discharge(EP::Model, inputs::Dict, PieceWiseHeatRate::Int, EnergyShareRequirement::Int)

	println("Discharge Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps

	### Variables ###

	# Energy injected into the grid by resource "y" at hour "t"
	@variable(EP, vP[y=1:G,t=1:T] >=0);

	### Expressions ###

	## Objective Function Expressions ##
	# if piecewiseheatrate option and ucommit commitment option are active, skip the fuel consumption
	if (PieceWiseHeatRate == 1)&(!isempty(inputs["THERM_COMMIT"]))
		inputs["C_Fuel_per_MWh"][inputs["THERM_COMMIT"],:] .=0
	end

	# Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
	@expression(EP, eCVar_out[y=1:G,t=1:T], (inputs["omega"][t]*(dfGen[!,:Var_OM_Cost_per_MWh][y]+inputs["C_Fuel_per_MWh"][y,t])*vP[y,t]))

	# Sum individual resource contributions to variable discharging costs to get total variable discharging costs
	@expression(EP, eTotalCVarOutT[t=1:T], sum(eCVar_out[y,t] for y in 1:G))
	@expression(EP, eTotalCVarOut, sum(eTotalCVarOutT[t] for t in 1:T))

	#@expression(EP, eTotalCVarOut, eTotalCVarOutG + eTotalCCO2)

	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] = EP[:eObj] + eTotalCVarOut 

	# ESR Policy
	if EnergyShareRequirement >= 1

		@expression(EP, eESRDischarge[ESR=1:inputs["nESR"]], sum(inputs["omega"][t]*dfGen[!,Symbol("ESR_$ESR")][y]*EP[:vP][y,t] for y=dfGen[findall(x->x>0,dfGen[!,Symbol("ESR_$ESR")]),:R_ID], t=1:T) - 
		    sum(inputs["dfESR"][:,ESR][z]*inputs["omega"][t]*inputs["pD"][t,z] for t=1:T, z=findall(x->x>0,inputs["dfESR"][:,ESR])))
	
		EP[:eESR] += eESRDischarge
	end


	
	return EP

end
