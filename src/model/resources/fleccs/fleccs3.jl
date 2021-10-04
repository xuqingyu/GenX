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
	fleccs3(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

The fleccs3 module creates decision variables, expressions, and constraints related to NGCC-CCS coupled with thermal systems. In this module, we will write up all the constraints formulations associated with the power plant.

This module uses the following 'helper' functions in separate files: fleccs2_commit() for FLECCS subcompoents subject to unit commitment decisions and constraints (if any) and fleccs2_no_commit() for FLECCS subcompoents not subject to unit commitment (if any).
"""

function fleccs3(EP::Model, inputs::Dict,  FLECCS::Int, UCommit::Int, Reserves::Int)

	println("Fleccs3, NGCC coupled with thermal storage Module")

	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    G_F = inputs["G_F"] # Number of fleccs generator
	FLECCS_ALL = inputs["FLECCS_ALL"] # set of Fleccs generator
	gen_ccs = inputs["dfGen_ccs"] # fleccs general data
	FLECCS_parameters = inputs["FLECCS_parameters"] # fleccs specific parameters
	# get number of flexible subcompoents
	N_F = inputs["N_F"]
 

	#NEW_CAP_ccs = inputs["NEW_CAP_fleccs"] #allow for new capcity build
	#RET_CAP_ccs = inputs["RET_CAP_fleccs"] #allow for retirement

	START_SUBPERIODS = inputs["START_SUBPERIODS"] #start
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] #interiors

    hours_per_subperiod = inputs["hours_per_subperiod"]

	fuel_type = collect(skipmissing(gen_ccs[!,:Fuel]))

	fuel_CO2 = inputs["fuel_CO2"]
	fuel_costs = inputs["fuel_costs"]



	STARTS = 1:inputs["H"]:T
    # Then we record all time periods that do not begin a sub period
    # (these will be subject to normal time couping constraints, looking back one period)
    INTERIORS = setdiff(1:T,STARTS)

	# capacity decision variables


	# variales related to power generation/consumption
    @variables(EP, begin
        # Continuous decision variables
        vP_gt[y in FLECCS_ALL, 1:T]  >= 0 # generation from combustion TURBINE (gas TURBINE)
        #vP_ccs_net[y in FLECCS_ALL, 1:T]  >= 0 # net generation from NGCC-CCS coupled with THERMAL storage
    end)

	# variales related to CO2 and thermal storage
	@variables(EP, begin
        vCAPTURE[y in FLECCS_ALL,1:T] >= 0 # captured co2 at time t, tonne/h
        vSTORE_hot[y in FLECCS_ALL,1:T] >= 0 # energy stored in hot tank storage, MMBTU
        vSTORE_cold[y in FLECCS_ALL,1:T] >= 0 # energy stored in cold tank storage, MMBTU
		vSTEAM_in[y in FLECCS_ALL,1:T] >= 0 # the energy content of steam that fed into the hot storage tank
        vSTEAM_out[y in FLECCS_ALL,1:T] >= 0 # the energy content of steam that pump out of the hot storage tank
		vCOLD_in[y in FLECCS_ALL,1:T] >= 0 # the energy content of cold thermal energy that fed into the hot storage tank
        vCOLD_out[y in FLECCS_ALL,1:T] >= 0 # the energy content of cold thermal energy that pump out of the hot storage tank

	end)



	# the order of those variables must follow the order of subcomponents in the "Fleccs_data3.csv"
	# 1. gas turbine
	# 2. steam turbine 
	# 3. PCC
	# 4. Compressor
	# 5. Hot storage tank
	# 6. Cold storage tank
	# 7. Heat pump
	# 8. BOP

	# get the ID of each subcompoents 
	# gas turbine 
	NGCT_id = gen_ccs[(gen_ccs[!,:TURBINE].==1),:FLECCS_NO][1]
	# steam turbine
	NGST_id = gen_ccs[(gen_ccs[!,:TURBINE].==2),:FLECCS_NO][1]
	# PCC
	PCC_id = gen_ccs[(gen_ccs[!,:PCC].==1),:FLECCS_NO][1]
	# compressor
	Comp_id = gen_ccs[(gen_ccs[!,:COMPRESSOR].==1),:FLECCS_NO][1]
	#Rich tank
	Hot_id = gen_ccs[(gen_ccs[!,:STORAGE].==1),:FLECCS_NO][1]
	#lean tank
	Cold_id = gen_ccs[(gen_ccs[!,:STORAGE].==2),:FLECCS_NO][1]
	# heat pump
	HeatPump_id = gen_ccs[(gen_ccs[!,:HEATPUMP].==1),:FLECCS_NO][1]
	#BOP 
	BOP_id = gen_ccs[(gen_ccs[!,:BOP].==1),:FLECCS_NO][1]

	# Specific constraints for FLECCS system
    # Thermal Energy input of combustion TURBINE (or oxyfuel power cycle) at hour "t" [MMBTU], eqn 1
    @expression(EP, eFuel[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pHeatRate_gt][y] * vP_gt[y,t])

	# additional power output from gas turbine when cold energy is feed into gas turbine, eqn 16
	@expression(EP, ePower_gt_add[y in FLECCS_ALL,t=1:T], vCOLD_out[y,t]/FLECCS_parameters[!,:pColdUseRate][y] )

	# additional fuel comsumption, eqn 15
	@expression(EP, eFuel_add[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pHeatRate_gt_add][y] * ePower_gt_add[y,t])
	

	# Thermal Energy output of steam generated by HRSG at hour "t" [MWh], high pressure steam, eqn 2a
	@expression(EP, eSteam_high[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_high][y] * eFuel[y,t])
	# mid pressure steam, some of steam is extracted from mid pressure steam turbine, eqn 2d
	@expression(EP, eSteam_mid[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_mid][y] * eSteam_high[y,t] - vSTEAM_in[y,t] )
	# low pressure steam, eqn 2c
	@expression(EP, eSteam_low[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_low][y] * eSteam_mid[y,t])

    # additional steam generation when addtional power output is generated in the gas turbine 
	# Additional high pressure steam, eqn 2e
	@expression(EP, eSteam_high_add[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_high_add][y] * eFuel_add[y,t])
	# Additional mid pressure steam, some of steam is extracted from mid pressure steam turbine, eqn 2f
	@expression(EP, eSteam_mid_add[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_mid_add][y] * eSteam_high_add[y,t])
	# Additional low pressure steam, eqn 2g
	@expression(EP, eSteam_low_add[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamRate_low_add][y] * eSteam_mid_add[y,t])





    # CO2 generated by combustion TURBINE (or oxyfuel power cycle) at hour "t" [tonne/h], eqn 3a
    @expression(EP, eCO2_flue[y in FLECCS_ALL,t=1:T], gen_ccs[!,:CO2_per_MMBTU][NGCT_id] * (eFuel[y,t]+eFuel_add[y,t]))
	#CO2 vented at time "t" [tonne/h], eqn 3b
    @expression(EP, eCO2_vent[y in FLECCS_ALL,t=1:T], eCO2_flue[y,t] - vCAPTURE[y,t])

    #steam used by post-combustion carbon capture (PCC) unit [MMBTU], eqn 4b
    @expression(EP, eSteam_use_pcc[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pSteamUseRate][y] * vCAPTURE[y,t] - vSTEAM_out[y,t])
    
	#power used by post-combustion carbon capture (PCC) unit [MWh], eqn 5
    @expression(EP, ePower_use_pcc[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pPowerUseRate][y]  * vCAPTURE[y,t])
    
    #power used by compressor unit [MWh], eqn 7
    @expression(EP, ePower_use_comp[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pCO2CompressRate][y] * vCAPTURE[y,t])
	#power used by auxiliary [MWh], eqn 8 
	@expression(EP, ePower_use_other[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pPowerUseRate_Other][y] * eFuel[y,t])

    #power used by heat pump for cold energy, eqn 11
	@expression(EP, ePower_use_ts[y in FLECCS_ALL,t=1:T], FLECCS_parameters[!,:pPowerUseRate_ts][y] * vCOLD_in[y,t])

	# energy balance for thermal storage tank
	# dynamic of hot tank storage system, normal [MMBTU thermal energy], eqn 12a
	@constraint(EP, cStore_hot[y in FLECCS_ALL, t in INTERIOR_SUBPERIODS],vSTORE_hot[y, t] == vSTORE_hot[y, t-1] + vSTEAM_in[y,t] - vSTEAM_out[y,t])
	# dynamic of rhot tank storage system, wrapping [MMBTU thermal energy], eqn 12b
	@constraint(EP, cStore_hotwrap[y in FLECCS_ALL, t in START_SUBPERIODS],vSTORE_hot[y, t] == vSTORE_hot[y,t+hours_per_subperiod-1] + vSTEAM_in[y,t] - vSTEAM_out[y,t])
	# dynamic of cold tank storage system, normal [MMBTU thermal energy], eqn 13a
	@constraint(EP, cStore_cold[y in FLECCS_ALL, t in INTERIOR_SUBPERIODS],vSTORE_cold[y, t] == vSTORE_cold[y, t-1] + vCOLD_in[y,t] - vCOLD_out[y,t])
	# dynamic of cold tank storage system, wrapping [MMBTU thermal energy], eqn 13b
	@constraint(EP, cStore_coldwrap[y in FLECCS_ALL, t in START_SUBPERIODS],vSTORE_cold[y, t] == vSTORE_cold[y,t+hours_per_subperiod-1]  + vCOLD_in[y,t] - vCOLD_out[y,t])



	#Power generated by steam turbine [MWh], 8e,8f,8g add up
	@expression(EP, ePower_st[y in FLECCS_ALL,t=1:T], (eSteam_high[y,t]+eSteam_high_add[y,t])/FLECCS_parameters[!,:pHeatRate_st_high][y] +
	(eSteam_mid[y,t] + eSteam_mid_add[y,t])/FLECCS_parameters[!,:pHeatRate_st_mid][y]+ (eSteam_low[y,t] + eSteam_low_add[y,t]   - eSteam_use_pcc[y,t])/FLECCS_parameters[!,:pHeatRate_st_low][y])


	@expression(EP, ePower_gt[y in FLECCS_ALL,t=1:T], vP_gt[y,t] +ePower_gt_add[y,t] )

	@expression(EP, ePower_aux[y in FLECCS_ALL,t=1:T], ePower_use_comp[y,t] + ePower_use_pcc[y,t] + ePower_use_other[y,t] )

	# NGCC-CCS net power output = vP_gt + ePower_st - ePower_use_comp - ePower_use_pcc, 9b
	@expression(EP, eCCS_net[y in FLECCS_ALL,t=1:T], ePower_gt[y,t] + ePower_st[y,t] -ePower_aux[y,t] -ePower_use_ts[y,t])


	# Power balance
	@expression(EP, ePowerBalanceFleccs[t=1:T, z=1:Z], sum(eCCS_net[y,t] for y in unique(gen_ccs[(gen_ccs[!,:Zone].==z),:R_ID])))

	# constraints:
	# captured CO2 should be less than the eCO2_flue * maximum co2 capture rate
	@constraint(EP, cMaxCapture_rate[y in FLECCS_ALL,t=1:T], vCAPTURE[y,t] <= (eCO2_flue[y,t])*FLECCS_parameters[!,:pCO2CapRate][y])
    # the additional power output from gas turbine should have a limit 
	@constraint(EP, cMaxAddPower[y in FLECCS_ALL,t=1:T], ePower_gt_add[y,t] <= FLECCS_parameters[!,:pCapPercent][y]*EP[:eTotalCapFleccs][y,NGCT_id])


    # steam >0 
	@constraint(EP, cSteam_mid[y in FLECCS_ALL,t=1:T], eSteam_mid[y,t] >= 0)





	#min power constraints 
    #Maximum capacity constraints
	# Min power generated for combustion TURBINE at hour "t"
	@constraint(EP, cMinGeneration_gt[y in FLECCS_ALL,t=1:T], vP_gt[y,t] >= gen_ccs[(gen_ccs[!,:R_ID].==y),:Min_power][NGCT_id] *EP[:eTotalCapFleccs][y,NGCT_id])
    # Min power generated for steam TURBINE at hour "t"
    @constraint(EP, cMinGeneration_st[y in FLECCS_ALL,t=1:T], ePower_st[y,t] >=   gen_ccs[(gen_ccs[!,:R_ID].==y),:Min_power][NGST_id]* EP[:eTotalCapFleccs][y,NGST_id])
    # Min Power used for compressing CO2 
    @constraint(EP, cMin_comp[y in FLECCS_ALL,t=1:T], ePower_use_comp[y,t] >=   gen_ccs[(gen_ccs[!,:R_ID].==y),:Min_power][Comp_id]  *EP[:eTotalCapFleccs][y,Comp_id])
    
	# Min captured CO2  from adsorber at time t should be less than the capacity of capture unit [tonne CO2]
	@constraint(EP, cMinCapture[y in FLECCS_ALL,t=1:T], vCAPTURE[y,t] >=  gen_ccs[(gen_ccs[!,:R_ID].==y),:Min_power][PCC_id] * EP[:eTotalCapFleccs][y,PCC_id] )





    #Maximum capacity constraints
	# Maximum power generated for combustion TURBINE at hour "t"
	@constraint(EP, cMaxGeneration_gt[y in FLECCS_ALL,t=1:T], vP_gt[y,t] <= EP[:eTotalCapFleccs][y,NGCT_id])
    # Maximum power generated for steam TURBINE at hour "t"
    @constraint(EP, cMaxGeneration_st[y in FLECCS_ALL,t=1:T], ePower_st[y,t] <=  EP[:eTotalCapFleccs][y,NGST_id])
    # Maximum Power used for compressing CO2
    @constraint(EP, cMax_comp[y in FLECCS_ALL,t=1:T], ePower_use_comp[y,t] <=  EP[:eTotalCapFleccs][y,Comp_id])
    # Maximum captured CO2  from adsorber at time t should be less than the capacity of capture unit [tonne CO2]
    @constraint(EP, cMaxCapture[y in FLECCS_ALL,t=1:T], vCAPTURE[y,t] <= EP[:eTotalCapFleccs][y,PCC_id] )
 

	# hot thermal energy at any time must be non-negative and less than the capacity [MMBTU]
    @constraint(EP, cMaxStored_hot[y in FLECCS_ALL,t=1:T], vSTORE_hot[y,t] <=  EP[:eTotalCapFleccs][y,Hot_id])
	# cold thermal energy at any time must be non-negative and less than the capacity [MMBTU]
    @constraint(EP, cMaxStored_cold[y in FLECCS_ALL,t=1:T], vSTORE_cold[y,t] <= EP[:eTotalCapFleccs][y,Cold_id])
	# power consumed by heat pump at any time must be non-negative and less than the capacity [MMBTU]
    @constraint(EP, cMax_heat_pump[y in FLECCS_ALL,t=1:T], ePower_use_ts[y,t] <= EP[:eTotalCapFleccs][y,HeatPump_id])






	# BOP capacity = gas turbine + steam turbine 
	@constraint(EP, cBOP_NEW[y in FLECCS_ALL], EP[:eTotalCapFleccs][y, BOP_id] == EP[:eTotalCapFleccs][y, NGCT_id]+ EP[:eTotalCapFleccs][y,NGST_id] )

	#@constraint(EP, cBOP_RET[y in FLECCS_ALL] ,EP[:vRETCAP_fleccs][y, BOP_id] ==  EP[:vRETCAP_fleccs][y, NGCT_id]+ EP[:vRETCAP_fleccs][y,NGST_id] )
	## Power Balance##
	EP[:ePowerBalance] += ePowerBalanceFleccs





	###########variable cost
	#fuel
	@expression(EP, eCVar_fuel[y in FLECCS_ALL, t = 1:T],(inputs["omega"][t]*fuel_costs[fuel_type[1]][t]*(eFuel[y,t]+eFuel_add[y,t])))
	# CO2 price applied to vented CO2
	@expression(EP, eCVar_CO2[y in FLECCS_ALL, t = 1:T],(inputs["omega"][t]*eCO2_vent[y,t]*inputs["CostCO2"]))
	
	# CO2 sequestration cost applied to sequestrated CO2
	@expression(EP, eCVar_CO2_sequestration[y in FLECCS_ALL, t = 1:T],(inputs["omega"][t]*vCAPTURE[y,t]*FLECCS_parameters[!,:pCO2_sequestration][y]))


	# start variable O&M
	# variable O&M for all the teams: combustion turbine (or oxfuel power cycle)
	@expression(EP,eCVar_gt[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].==NGCT_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*vP_gt[y,t])
	# variable O&M for NGCC-based teams: VOM of steam turbine and co2 compressor
	# variable O&M for steam turbine
	@expression(EP,eCVar_st[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].==NGST_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*ePower_st[y,t])
	 # variable O&M for compressor
	@expression(EP,eCVar_comp[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].== Comp_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*(eCO2_flue[y,t] - eCO2_vent[y,t]))


	# specfic variable O&M formulations for each team
	# variable O&M for heat pump
	@expression(EP,eCVar_heatpump[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].== HeatPump_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*(ePower_use_ts[y,t]))
	# variable O&M for hot storage
	@expression(EP,eCVar_rich[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].== Hot_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*(vSTORE_hot[y,t]))
	# variable O&M for cold storage
	@expression(EP,eCVar_lean[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].== Cold_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*(vSTORE_cold[y,t]))
	# variable O&M for PCC
	@expression(EP,eCVar_PCC[y in FLECCS_ALL, t = 1:T], inputs["omega"][t]*(gen_ccs[(gen_ccs[!,:FLECCS_NO].== PCC_id) .& (gen_ccs[!,:R_ID].==y),:Var_OM_Cost_per_Unit][1])*(vCAPTURE[y,t]))


	#adding up variable cost

	@expression(EP,eVar_fleccs[t = 1:T], sum(eCVar_fuel[y,t] + eCVar_CO2[y,t] + eCVar_CO2_sequestration[y,t] + eCVar_gt[y,t] + eCVar_st[y,t] + eCVar_comp[y,t] + eCVar_PCC[y,t] +eCVar_heatpump[y,t]  for y in FLECCS_ALL))

	@expression(EP,eTotalCVar_fleccs, sum(eVar_fleccs[t] for t in 1:T))


	EP[:eObj] += eTotalCVar_fleccs


	#if UCommit >= 1
	#	EP = fleccs2_commit(EP::Model, inputs::Dict, Reserves::Int)
	#end

	#if UCommit == 0
	#	EP = fleccs2_no_commit(EP::Model, inputs::Dict, Reserves::Int)
	#end

	return EP
end
