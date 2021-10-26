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
	investment_discharge(EP::Model, inputs::Dict)

This function defines the expressions and constraints keeping track of total available power generation/discharge capacity across all resources as well as constraints on capacity retirements.

The total capacity of each resource is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity. Note for storage resources, additional energy and charge power capacity decisions and constraints are defined in the storage module.

```math
\begin{aligned}
& \Delta^{total}_{y,z} =(\overline{\Delta_{y,z}}+\Omega_{y,z}-\Delta_{y,z}) \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```

One cannot retire more capacity than existing capacity.
```math
\begin{aligned}
&\Delta_{y,z} \leq \overline{\Delta_{y,z}}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```

For resources where $\overline{\Omega_{y,z}}$ and $\underline{\Omega_{y,z}}$ is defined, then we impose constraints on minimum and maximum power capacity.
```math
\begin{aligned}
& \Delta^{total}_{y,z} \leq \overline{\Omega}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z} \\
& \Delta^{total}_{y,z}  \geq \underline{\Omega}_{y,z}
	\hspace{4 cm}  \forall y \in \mathcal{G}, z \in \mathcal{Z}
\end{aligned}
```

In addition, this function adds investment and fixed O\&M related costs related to discharge/generation capacity to the objective function:
```math
\begin{aligned}
& 	\sum_{y \in \mathcal{G} } \sum_{z \in \mathcal{Z}}
	\left( (\pi^{INVEST}_{y,z} \times \overline{\Omega}^{size}_{y,z} \times  \Omega_{y,z})
	+ (\pi^{FOM}_{y,z} \times \overline{\Omega}^{size}_{y,z} \times  \Delta^{total}_{y,z})\right)
\end{aligned}
```
"""
function investment_discharge(EP::Model, inputs::Dict, MinCapReq::Int)

	println("Investment Discharge Module")

	dfGen = inputs["dfGen"]

	G = inputs["G"] # Number of resources (generators, storage, DR, and DERs)

	NEW_CAP = inputs["NEW_CAP"] # Set of all resources eligible for new capacity
	RET_CAP = inputs["RET_CAP"] # Set of all resources eligible for capacity retirements
	COMMIT = inputs["COMMIT"] # Set of all resources eligible for unit commitment

	### Variables ###

	# Retired capacity of resource "y" from existing capacity
	@variable(EP, vRETCAP[y in RET_CAP] >= 0);

    # New installed capacity of resource "y"
	@variable(EP, vCAP[y in NEW_CAP] >= 0);

	### Expressions ###

	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
	@expression(EP, eTotalCap[y in 1:G],
		if y in intersect(NEW_CAP, RET_CAP) # Resources eligible for new capacity and retirements
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] + dfGen[!,:Cap_Size][y]*(EP[:vCAP][y] - EP[:vRETCAP][y])
			else
				dfGen[!,:Existing_Cap_MW][y] + EP[:vCAP][y] - EP[:vRETCAP][y]
			end
		elseif y in setdiff(NEW_CAP, RET_CAP) # Resources eligible for only new capacity
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] + dfGen[!,:Cap_Size][y]*EP[:vCAP][y]
			else
				dfGen[!,:Existing_Cap_MW][y] + EP[:vCAP][y]
			end
		elseif y in setdiff(RET_CAP, NEW_CAP) # Resources eligible for only capacity retirements
			if y in COMMIT
				dfGen[!,:Existing_Cap_MW][y] - dfGen[!,:Cap_Size][y]*EP[:vRETCAP][y]
			else
				dfGen[!,:Existing_Cap_MW][y] - EP[:vRETCAP][y]
			end
		else # Resources not eligible for new capacity or retirements
			dfGen[!,:Existing_Cap_MW][y] + EP[:vZERO]
		end
	)

	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new capacity, fixed costs are only O&M costs
	@expression(EP, eCFix[y in 1:G],
		if y in NEW_CAP # Resources eligible for new capacity
			if y in COMMIT
				dfGen[!,:Inv_Cost_per_MWyr][y]*dfGen[!,:Cap_Size][y]*vCAP[y] + dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
			else
				dfGen[!,:Inv_Cost_per_MWyr][y]*vCAP[y] + dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
			end
		else
			dfGen[!,:Fixed_OM_Cost_per_MWyr][y]*eTotalCap[y]
		end
	)

	# Sum individual resource contributions to fixed costs to get total fixed costs
	@expression(EP, eTotalCFix, sum(EP[:eCFix][y] for y in 1:G))

	# Add term to objective function expression
	EP[:eObj] += eTotalCFix

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cMaxRetNoCommit[y in setdiff(RET_CAP,COMMIT)], vRETCAP[y] <= dfGen[!,:Existing_Cap_MW][y])
	@constraint(EP, cMaxRetCommit[y in intersect(RET_CAP,COMMIT)], dfGen[!,:Cap_Size][y]*vRETCAP[y] <= dfGen[!,:Existing_Cap_MW][y])

	## Constraints on new built capacity
	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cMaxCap[y in intersect(dfGen[dfGen.Max_Cap_MW.>0,:R_ID], 1:G)], eTotalCap[y] <= dfGen[!,:Max_Cap_MW][y])

	# Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
	@constraint(EP, cMinCap[y in intersect(dfGen[dfGen.Min_Cap_MW.>0,:R_ID], 1:G)], eTotalCap[y] >= dfGen[!,:Min_Cap_MW][y])

	if (MinCapReq == 1)
		@expression(EP, eMinCapResInvest[mincap = 1:inputs["NumberOfMinCapReqs"]], sum(EP[:eTotalCap][y] for y in dfGen[(dfGen[!,Symbol("MinCapTag_$mincap")].== 1) ,:][!,:R_ID]))
		EP[:eMinCapRes] += eMinCapResInvest
	end
	
	return EP
end
