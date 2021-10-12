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
	FLECCS_fix(EP::Model, inputs::Dict)

This function defines the expressions and constraints keeping track of total available power generation capacity associated with FLECCS subcomponents as well as constraints on capacity retirements.

The total capacity of each resource is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity (Eq. \ref{eq:totalpowercap}). Note for storage resources, additional energy and charge power capacity decisions and constraints are defined in the storage module.

"""

function fleccs_fix(EP::Model, inputs::Dict,  FLECCS::Int, UCommit::Int, Reserves::Int)

	println(" FLECCS investment and fix cost Module")

	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    G_F = inputs["G_F"] # Number of FLECCS generator

	gen_ccs = inputs["dfGen_ccs"] # FLECCS data files
	NEW_CAP_ccs = inputs["NEW_CAP_FLECCS"] # subcomponents that has can be built
	RET_CAP_ccs = inputs["RET_CAP_FLECCS"] # subcomponents that has can be retired
	COMMIT_ccs = inputs["COMMIT_CCS"] # subcomponents subjected to UC commitment
	FLECCS_ALL = inputs["FLECCS_ALL"] # Number of FLECCS generator (element Array)

	# get number of flexible subcomponents 
	N_F = inputs["N_F"]
 
	# create capacity decision variables for FLECCS subcompoents. y represent the FLECCS plant, i represent the specfic subcomponents
	@variable(EP, vCAP_FLECCS[y in FLECCS_ALL, i in N_F] >= 0)
	@variable(EP, vRETCAP_FLECCS[y in FLECCS_ALL, i in N_F] >= 0)

	### Expressions ###
	# Cap_Size is set to 1 for all variables when unit UCommit == 0
	# When UCommit >= 1, Cap_Size stays the same for all the subcompoents.

	@expression(EP, eTotalCapFLECCS[y in FLECCS_ALL, i in N_F],
	    if y in intersect(NEW_CAP_ccs, RET_CAP_ccs) # Resources eligible for new capacity and retirements
		    if i in COMMIT_ccs
			    gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i] + gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i] * (EP[:vCAP_FLECCS][y,i] - EP[:vRETCAP_FLECCS][y,i])
		    else
	    		gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i]  + EP[:vCAP_FLECCS][y,i] - EP[:vRETCAP_FLECCS][y,i]
		    end
     	elseif y in setdiff(NEW_CAP_ccs, RET_CAP_ccs) # Resources eligible for only new capacity
	    	if i in COMMIT_ccs
		    	gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i]  + gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i]*EP[:vCAP_FLECCS][y,i]
	    	else
		    	gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i] + EP[:vCAP_FLECCS][y,i]
		    end
    	elseif y in setdiff(RET_CAP_ccs, NEW_CAP_ccs) # Resources eligible for only capacity retirements
	    	if i in COMMIT_ccs
    			gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i]  - gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i]*EP[:vRETCAP_FLECCS][y,i]
	    	else
		    	gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i]  - EP[:vRETCAP_FLECCS][y,i]
    		end
	    else # Resources not eligible for new capacity or retirements
		    gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i] +  EP[:vZERO]
    	end
	)
	
	## Objective Function Expressions ##

	# Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
	# If resource is not eligible for new capacity, fixed costs are only O&M costs

	@expression(EP, eCFixFLECCS[y in FLECCS_ALL,i in N_F],
	    if y in NEW_CAP_ccs # Resources eligible for new capacity
		    if i in COMMIT_ccs
		    	gen_ccs[(gen_ccs[!,:R_ID].==y),:Inv_Cost_per_Unityr][i] * gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i] *vCAP_FLECCS[y,i] + gen_ccs[(gen_ccs[!,:R_ID].==y),:Fixed_OM_Cost_per_Unityr][i] *eTotalCapFLECCS[y,i]
	    	else
	    		gen_ccs[(gen_ccs[!,:R_ID].==y),:Inv_Cost_per_Unityr][i] * vCAP_FLECCS[y,i] + gen_ccs[(gen_ccs[!,:R_ID].==y),:Fixed_OM_Cost_per_Unityr][i] *eTotalCapFLECCS[y,i]
	    	end
	    else
		    gen_ccs[(gen_ccs[!,:R_ID].==y),:Fixed_OM_Cost_per_Unityr][i] * eTotalCapFLECCS[y,i]
	    end
    )


	@expression(EP, eTotalCFixFLECCS, sum(eCFixFLECCS))


	EP[:eObj] += eTotalCFixFLECCS

	### Constratints ###

	## Constraints on retirements and capacity additions
	# Cannot retire more capacity than existing capacity
	@constraint(EP, cMaxRetNoCommitFLECCS[y in setdiff(RET_CAP_ccs,COMMIT_ccs),i in N_F], vRETCAP_FLECCS[y,i] <= gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i])
	@constraint(EP, cMaxRetCommitFLECCS[y in intersect(RET_CAP_ccs,COMMIT_ccs),i in N_F], gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i]*vRETCAP_FLECCS[y,i] <= gen_ccs[(gen_ccs[!,:R_ID].==y),:Existing_Cap_Unit][i])

	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cMaxCapFLECCS[y in intersect(gen_ccs[gen_ccs.Max_Cap_MW.>0,:R_ID]), i in N_F], eTotalCapFLECCS[y,i] <=gen_ccs[(gen_ccs[!,:R_ID].==y),:Max_Cap_MW][i])

	###
	if UCommit == 1 # Integer UC constraints
        #FLECCS subcompoents
		for y in FLECCS_ALL
			for i in COMMIT_ccs
				if y in inputs["NEW_CAP_FLECCS"]
					set_integer(vCAP_FLECCS[y,i])
				end
				if y in inputs["RET_CAP_FLECCS"]
					set_integer(vRETCAP_FLECCS[y,i])
				end
			end
		end
	end #END unit commitment configuration
	
	return EP
end
