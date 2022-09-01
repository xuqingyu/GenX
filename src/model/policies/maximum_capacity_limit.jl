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
	maximum_capacity_limit(EP::Model, inputs::Dict)
    The maximum capacity limit constraint allows for modeling maximum deployment of a certain technology or set of eligible technologies across the eligible model zones. 
    This is just the opposite of minimum capacity requirement constraint.
"""
function maximum_capacity_limit!(EP::Model, inputs::Dict, setup::Dict)

    println("Maxmimum Capacity limit Module")
    NumberOfMaxCapReqs = inputs["NumberOfMaxCapReqs"]
    G = inputs["G"]
    dfGen = inputs["dfGen"]
    ### Variable ###
    @variable(EP, vMaxCap_slack[maxcap = 1:NumberOfMaxCapReqs] >=0)

    ### Expressions ###
    @expression(EP, eCMaxCap_slack[maxcap = 1:NumberOfMaxCapReqs], inputs["MaxCapPriceCap"][maxcap] * EP[:vMaxCap_slack][maxcap])
    @expression(EP, eTotalCMaxCap_slack, sum(EP[:eCMaxCap_slack][maxcap] for maxcap = 1:NumberOfMaxCapReqs))
    add_to_expression!(EP[:eObj], EP[:eTotalCMaxCap_slack])

    @expression(EP, eMaxCapRes[maxcap = 1:NumberOfMaxCapReqs], 1*EP[:vZERO])

    @expression(EP, eMaxCapResInvest[maxcap = 1:NumberOfMaxCapReqs], sum(dfGen[y,Symbol("MaxCapTag_$maxcap")] * EP[:eTotalCap][y] for y in 1:G))
    add_to_expression!.(EP[:eMaxCapRes], EP[:eMaxCapResInvest])
	
    # VRE-STOR 
	# Assuming the VRE is the main component of the facility
	if (setup["VreStor"] == 1)
		VRE_STOR = inputs["VRE_STOR"]
		dfGen_VRE_STOR = inputs["dfGen_VRE_STOR"]
		@expression(EP, eMaxCapResVREStor[maxcap = 1:NumberOfMaxCapReqs], 
			sum(dfGen_VRE_STOR[y, Symbol("MaxCapTag_$maxcap")] * EP[:eTotalCap_VRE][y] for y in 1:VRE_STOR))
		add_to_expression!.(EP[:eMaxCapRes], EP[:eMaxCapResVREStor])
	end
    ### Constraint ###
    @constraint(EP, cZoneMaxCapReq[maxcap = 1:NumberOfMaxCapReqs], EP[:eMaxCapRes][maxcap] <= inputs["MaxCapReq"][maxcap] + EP[:vMaxCap_slack][maxcap])

end