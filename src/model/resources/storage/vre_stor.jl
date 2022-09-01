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
	vre_stor!(EP::Model, inputs::Dict, setup::Dict)

"""
function vre_stor!(EP::Model, inputs::Dict, setup::Dict)

	println("VRE-Storage Module")

	dfGen_VRE_STOR = inputs["dfGen_VRE_STOR"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	VRE_STOR = inputs["VRE_STOR"] 	# Number of generators
    NEW_CAP_VRE_STOR = inputs["NEW_CAP_VRE_STOR"]
    RET_CAP_VRE_STOR = inputs["RET_CAP_VRE_STOR"]
    NEW_CAP_ENERGY_VRE_STOR = inputs["NEW_CAP_ENERGY_VRE_STOR"]
    RET_CAP_ENERGY_VRE_STOR = inputs["RET_CAP_ENERGY_VRE_STOR"]
    NEW_CAP_GRID = inputs["NEW_CAP_GRID"]
    RET_CAP_GRID = inputs["RET_CAP_GRID"]

    START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod
    
    dfGen_VRE_STOR = inputs["dfGen_VRE_STOR"]

    ### Variables ###

    # Retired capacity of resource VRE from existing capacity [MW]
    @variable(EP, vRETCAP_VRE[y=1:VRE_STOR] >= 0);
    
    # New installed capacity of resource VRE [MW]
    @variable(EP, vCAP_VRE[y=1:VRE_STOR] >= 0);

    # Retired grid capacity [MW]
    @variable(EP, vRETGRIDCAP[y=1:VRE_STOR] >= 0)

    # New installed grid capacity [AC MW]
    @variable(EP, vGRIDCAP[y=1:VRE_STOR] >= 0)

    # Energy storage reservoir capacity retired for VRE storage [MWh]
    @variable(EP, vRETCAPSTORAGE_VRE_STOR[y=1:VRE_STOR] >= 0)	

    # Energy storage reservoir capacity (MWh capacity) built for VRE storage [MWh]
    @variable(EP, vCAPSTORAGE_VRE_STOR[y=1:VRE_STOR] >= 0)

    # "Behind the inverter" generation [MW]
    @variable(EP, vP_DC[y=1:VRE_STOR, t=1:T] >= 0)

    # "Behind the inverter" charge from the VRE-component [MW]
    @variable(EP, vCHARGE_DC[y=1:VRE_STOR, t=1:T] >= 0)

    # "Behind the inverter" discharge [MW]
    @variable(EP, vDISCHARGE_DC[y=1:VRE_STOR, t=1:T] >= 0)

    # Energy injected into the grid by VRE_STOR at hour "t" [MW]
    @variable(EP, vP_VRE_STOR[y=1:VRE_STOR,t=1:T] >=0);

    # Energy withdrawn from grid by resource VRE_STOR at hour "t" [MW] 
    @variable(EP, vCHARGE_VRE_STOR[y=1:VRE_STOR,t=1:T] >= 0);

    # Storage level of resource "y" at hour "t" [MWh] on zone "z"
    @variable(EP, vS_VRE_STOR[y=1:VRE_STOR,t=1:T] >= 0);

	### Expressions ###

    # Total capacity expressions for VRE-component, storage-component, and grid-component.
	#@expression(EP, eTotalCap_VRE[y in 1:VRE_STOR], 
    #    if y in intersect(NEW_CAP_VRE_STOR, RET_CAP_VRE_STOR) # Resources eligible for new capacity and retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_MW][y] + EP[:vCAP_VRE][y] - EP[:vRETCAP_VRE][y]
    #    elseif y in setdiff(NEW_CAP_VRE_STOR, RET_CAP_VRE_STOR) # Resources eligible for only new capacity
    #        dfGen_VRE_STOR[!,:Existing_Cap_MW][y] + EP[:vCAP_VRE][y] 
    #    elseif y in setdiff(RET_CAP_VRE_STOR, NEW_CAP_VRE_STOR) # Resources eligible for only capacity retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_MW][y] - EP[:vRETCAP_VRE][y]
    #    else
    #        dfGen_VRE_STOR[!,:Existing_Cap_MW][y] + EP[:vZERO]
    #    end
    #)
    @expression(EP, eTotalCap_VRE[y in 1:VRE_STOR], dfGen_VRE_STOR[!,:Existing_Cap_MW][y] + EP[:vCAP_VRE][y] - EP[:vRETCAP_VRE][y])
    #@expression(EP, eTotalCap_STOR[y in 1:VRE_STOR], 
    #    if y in intersect(NEW_CAP_ENERGY_VRE_STOR, RET_CAP_ENERGY_VRE_STOR) # Resources eligible for new capacity and retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_MWh][y] + EP[:vCAPSTORAGE_VRE_STOR][y] - EP[:vRETCAPSTORAGE_VRE_STOR][y]
    #    elseif y in setdiff(NEW_CAP_ENERGY_VRE_STOR, RET_CAP_ENERGY_VRE_STOR) # Resources eligible for only new capacity
    #        dfGen_VRE_STOR[!,:Existing_Cap_MWh][y] + EP[:vCAPSTORAGE_VRE_STOR][y]
    #    elseif y in setdiff(RET_CAP_ENERGY_VRE_STOR, NEW_CAP_ENERGY_VRE_STOR) # Resources eligible for only capacity retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_MWh][y] - EP[:vRETCAPSTORAGE_VRE_STOR][y]
    #    else
    #        dfGen_VRE_STOR[!,:Existing_Cap_MWh][y] + EP[:vZERO]
    #    end
    #)
    @expression(EP, eTotalCap_STOR[y in 1:VRE_STOR], dfGen_VRE_STOR[!,:Existing_Cap_MWh][y] + EP[:vCAPSTORAGE_VRE_STOR][y] - EP[:vRETCAPSTORAGE_VRE_STOR][y])
    #@expression(EP, eTotalCap_GRID[y in 1:VRE_STOR], 
    #    if y in intersect(NEW_CAP_GRID, RET_CAP_GRID) # Resources eligible for new capacity and retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y] + EP[:vGRIDCAP][y] - EP[:vRETGRIDCAP][y]
    #    elseif y in setdiff(NEW_CAP_GRID, RET_CAP_GRID) # Resources eligible for only new capacity
    #        dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y] + EP[:vGRIDCAP][y]
    #    elseif y in setdiff(RET_CAP_GRID, NEW_CAP_GRID) # Resources eligible for only capacity retirements
    #        dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y] - EP[:vRETGRIDCAP][y]
    #    else
    #        dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y] + EP[:vZERO]
    #    end
    #)
    @expression(EP, eTotalCap_GRID[y in 1:VRE_STOR], dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y] + EP[:vGRIDCAP][y] - EP[:vRETGRIDCAP][y])
    
    # Energy losses related to technologies (increase in effective demand)
    @expression(EP, eELOSS_VRE_STOR[y=1:VRE_STOR], sum(inputs["omega"][t]*(vCHARGE_DC[y,t]/dfGen_VRE_STOR[!,:EtaInverter][y] - vDISCHARGE_DC[y,t]/dfGen_VRE_STOR[!,:EtaInverter][y]) for t in 1:T))
    @expression(EP, eStorageLossByZone_VRE_STOR[z=1:Z],
        sum(EP[:eELOSS_VRE_STOR][y] for y in intersect(collect(1:VRE_STOR), dfGen_VRE_STOR[dfGen_VRE_STOR[!,:Zone].==z,:R_ID]))
    )
    ### Objective Function Expressions ###

    # Investment costs for VRE-STOR resources
    @expression(EP, eCInv_VRE_STOR[y in 1:VRE_STOR], 
    dfGen_VRE_STOR[!,:Inv_Cost_VRE_per_MWyr][y]*vCAP_VRE[y] 
    + dfGen_VRE_STOR[!,:Inv_Cost_GRID_per_MWyr][y]*vGRIDCAP[y] 
    + dfGen_VRE_STOR[!,:Inv_Cost_per_MWhyr][y]*vCAPSTORAGE_VRE_STOR[y])

    # Fixed costs for VRE-STOR resources
    @expression(EP, eCFix_VRE_STOR[y in 1:VRE_STOR], 
    + dfGen_VRE_STOR[!,:Fixed_OM_VRE_Cost_per_MWyr][y]*eTotalCap_VRE[y]
    + dfGen_VRE_STOR[!,:Fixed_OM_GRID_Cost_per_MWyr][y]*eTotalCap_GRID[y]
    + dfGen_VRE_STOR[!,:Fixed_OM_Cost_per_MWhyr][y]*eTotalCap_STOR[y])

    # Variable costs of "generation" for VRE-STOR resource "y" during hour "t" = variable O&M plus fuel cost
    @expression(EP, eCVar_out_VRE_STOR[y in 1:VRE_STOR, t in 1:T], (inputs["omega"][t]*(dfGen_VRE_STOR[!,:Var_OM_Cost_per_MWh][y]+dfGen_VRE_STOR[!,:C_Fuel_per_MWh][y])*vP_DC[y,t]*dfGen_VRE_STOR[!,:EtaInverter][y]))
    @expression(EP, eCVar_temp_VRE_STOR[y in 1:VRE_STOR], sum(eCVar_out_VRE_STOR[y, t] for t in 1:T))

	# Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(EP, eTotalCInv_VRE_STOR, sum(eCInv_VRE_STOR[y] for y in 1:VRE_STOR))
	@expression(EP, eTotalCFix_VRE_STOR, sum(eCFix_VRE_STOR[y] for y in 1:VRE_STOR))
    @expression(EP, eTotalCVar_VRE_STOR, sum(eCVar_out_VRE_STOR[y, t] for y in 1:VRE_STOR, t in 1:T))
	EP[:eObj] += (eTotalCInv_VRE_STOR + eTotalCFix_VRE_STOR + eTotalCVar_VRE_STOR)

    # Separate grid costs
    @expression(EP, eCGrid_VRE_STOR[y in 1:VRE_STOR], 
    dfGen_VRE_STOR[!,:Inv_Cost_GRID_per_MWyr][y]*vGRIDCAP[y]
    + dfGen_VRE_STOR[!,:Fixed_OM_GRID_Cost_per_MWyr][y]*eTotalCap_GRID[y])
    @expression(EP, eTotalCGrid, sum(eCGrid_VRE_STOR[y] for y in 1:VRE_STOR))

    # Zonal Costs
    @expression(EP, eZonalCFOM_VRE_STOR[z=1:Z], EP[:vZERO] + sum(EP[:eCFix_VRE_STOR][y] for y in dfGen_VRE_STOR[(dfGen_VRE_STOR[!, :Zone].==z), :R_ID]))
    @expression(EP, eZonalCInv_VRE_STOR[z=1:Z], EP[:vZERO] + sum(EP[:eCInv_VRE_STOR][y] for y in dfGen_VRE_STOR[(dfGen_VRE_STOR[!, :Zone].==z), :R_ID]))
    @expression(EP, eZonalCVar_VRE_STOR[z=1:Z], EP[:vZERO] + sum(EP[:eCVar_temp_VRE_STOR][y] for y in dfGen_VRE_STOR[(dfGen_VRE_STOR[!, :Zone].==z), :R_ID]))
    @expression(EP, eZonalCGrid_VRE_STOR[z=1:Z], EP[:vZERO] + sum(EP[:eCGrid_VRE_STOR][y] for y in dfGen_VRE_STOR[(dfGen_VRE_STOR[!, :Zone].==z), :R_ID]))
	## Power Balance Expressions ##

	@expression(EP, ePowerBalance_VRE_STOR[t=1:T, z=1:Z],
	    sum(vP_VRE_STOR[y,t]-vCHARGE_VRE_STOR[y,t] for y=dfGen_VRE_STOR[(dfGen_VRE_STOR[!,:Zone].==z),:R_ID]))
    add_to_expression!.(EP[:ePowerBalance], EP[:ePowerBalance_VRE_STOR])
    ## Module Expressions ##

    # DC exports
    @expression(EP, eDCExports[y in 1:VRE_STOR, t in 1:T], vDISCHARGE_DC[y, t] + vP_DC[y, t])

    # Grid charging of battery
    @expression(EP, eGridCharging[y in 1:VRE_STOR, t in 1:T], vCHARGE_VRE_STOR[y, t]*dfGen_VRE_STOR[!,:EtaInverter][y])

    # VRE charging of battery
    @expression(EP, eVRECharging[y in 1:VRE_STOR, t in 1:T], vCHARGE_DC[y, t] - eGridCharging[y, t])

    
	### Constraints ###

    # Constraint 0: Cannot retire more capacity than existing capacity for VRE-STOR technologies
    @constraint(EP, cMaxRet_VRE[y=1:VRE_STOR], vRETCAP_VRE[y] <= dfGen_VRE_STOR[!,:Existing_Cap_MW][y])
    @constraint(EP, cMaxRet_GRID[y=1:VRE_STOR], vRETGRIDCAP[y] <= dfGen_VRE_STOR[!,:Existing_Cap_Grid_MW][y])
    @constraint(EP, cMaxRet_STOR[y=1:VRE_STOR], vRETCAPSTORAGE_VRE_STOR[y] <= dfGen_VRE_STOR[!,:Existing_Cap_MWh][y])

    # Constraint 1: Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	# DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
	@constraint(EP, cMaxCap_VRE[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Max_Cap_VRE_MW.>=0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_VRE[y] <= dfGen_VRE_STOR[!,:Max_Cap_VRE_MW][y])
    @constraint(EP, cMaxCap_STOR[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Max_Cap_Stor_MWh.>=0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_STOR[y] <= dfGen_VRE_STOR[!,:Max_Cap_Stor_MWh][y])
    @constraint(EP, cMaxCap_GRID[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Max_Cap_Grid_MW.>=0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_GRID[y] <= dfGen_VRE_STOR[!,:Max_Cap_Grid_MW][y])
    
    # Constraint 2: Minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
    @constraint(EP, cMinCap_VRE[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Min_Cap_VRE_MW.>0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_VRE[y] >= dfGen_VRE_STOR[!,:Min_Cap_VRE_MW][y])
    @constraint(EP, cMinCap_STOR[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Min_Cap_Stor_MWh.>0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_STOR[y] >= dfGen_VRE_STOR[!,:Min_Cap_Stor_MWh][y])
    @constraint(EP, cMinCap_GRID[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Min_Cap_Grid_MW.>0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_GRID[y] >= dfGen_VRE_STOR[!,:Min_Cap_Grid_MW][y])

    # Constraint 3: Inverter Ratio between capacity and grid
    @constraint(EP, cInverterRatio[y in intersect(dfGen_VRE_STOR[dfGen_VRE_STOR.Inverter_Ratio.>0,:R_ID], 1:VRE_STOR)], 
    eTotalCap_VRE[y] == dfGen_VRE_STOR[!,:Inverter_Ratio][y] * eTotalCap_GRID[y])

    # Constraint 4: VRE Generation Maximum Constraint
    @constraint(EP, cVREGenMax[y in 1:VRE_STOR, t in 1:T],
    vP_DC[y,t] <= inputs["pP_Max_VRE_STOR"][y,t]*eTotalCap_VRE[y])

    # Constraint 5: Charging + Discharging Maximum 
    @constraint(EP, cChargeDischargeMax[y in 1:VRE_STOR, t in 1:T],
    vDISCHARGE_DC[y,t] + vCHARGE_DC[y,t] <= dfGen_VRE_STOR[!,:Power_To_Energy_Ratio][y]*eTotalCap_STOR[y])

    # Constraint 6: SOC Maximum
    @constraint(EP, cSOCMax[y in 1:VRE_STOR, t in 1:T],
    vS_VRE_STOR[y,t] <= eTotalCap_STOR[y])

    # Constraint 7: State of Charge (energy stored for the next hour)
    @constraint(EP, cSoCBalInterior_VRE_STOR[t in INTERIOR_SUBPERIODS,y in 1:VRE_STOR], 
    vS_VRE_STOR[y,t] == vS_VRE_STOR[y,t-1] -
                        (1/dfGen_VRE_STOR[!,:Eff_Down][y]*vDISCHARGE_DC[y,t]) +
                        (dfGen_VRE_STOR[!,:Eff_Up][y]*vCHARGE_DC[y,t]) -
                        (dfGen_VRE_STOR[!,:Self_Disch][y]*vS_VRE_STOR[y,t-1]))
    @constraint(EP, cSoCBalStart_VRE_STOR[t in START_SUBPERIODS, y in 1:VRE_STOR],
    vS_VRE_STOR[y,t] == vS_VRE_STOR[y,t+hours_per_subperiod-1] - 
                        (1/dfGen_VRE_STOR[!,:Eff_Down][y]*vDISCHARGE_DC[y,t]) +
                        (dfGen_VRE_STOR[!,:Eff_Up][y]*vCHARGE_DC[y,t]) -
                        (dfGen_VRE_STOR[!,:Self_Disch][y]*vS_VRE_STOR[y,t+hours_per_subperiod-1]))

    # Constraint 8: Energy Balance Constraint
    @constraint(EP, cEnergyBalance[y in 1:VRE_STOR, t in 1:T],
    vDISCHARGE_DC[y, t] + vP_DC[y, t] - vCHARGE_DC[y, t] == vP_VRE_STOR[y, t]/dfGen_VRE_STOR[!,:EtaInverter][y] - eGridCharging[y, t])
    
    # Constraint 9: Grid Export/Import Maximum
    @constraint(EP, cGridExport[y in 1:VRE_STOR, t in 1:T],
    vP_VRE_STOR[y,t] + vCHARGE_VRE_STOR[y,t] <= eTotalCap_GRID[y])	

	return EP
end