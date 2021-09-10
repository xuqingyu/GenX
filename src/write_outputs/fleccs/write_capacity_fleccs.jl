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
	write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the FLECCS technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	gen_ccs = inputs["dfGen_ccs"]
	FLECCS_ALL = inputs["FLECCS_ALL"]
	N_F = inputs["N_F"]
	# the number of rows for fleccs generator 
	n = length(gen_ccs[!,"Resource"])/length(N_F)

    # the number of subcompoents 
	N = length(N_F)

	capfleccs = zeros(size(gen_ccs[!,"Resource"]))

	for y in inputs["NEW_CAP_fleccs"]
		if setup["UCommit"] >= 1 
			for i in N_F
			    capfleccs[(y-1)*N + i] = value(EP[:vCAP_fleccs][y, i])* gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i]
			end
		else
			for i in N_F
			    capfleccs[(y-1)*N + i] = value(EP[:vCAP_fleccs][y, i])
			end
		end
	end

	retcapfleccs = zeros(size(gen_ccs[!,"Resource"]))


	for y in inputs["RET_CAP_fleccs"]
		if setup["UCommit"] >= 1 
			for i in N_F
			    retcapfleccs[(y-1)*N + i] = value(EP[:vRETCAP_fleccs][y, i])* gen_ccs[(gen_ccs[!,:R_ID].==y),:Cap_Size][i]
			end
		else
			for i in N_F
			    retcapfleccs[(y-1)*N + i] = value(EP[:vRETCAP_fleccs][y, i])
			end
		end
	end




	EndCapfleccs = zeros(size(gen_ccs[!,"Resource"]))
	for y in FLECCS_ALL
		for i in N_F
		    EndCapfleccs[(y-1)*N+i] = value.(EP[:eTotalCapFleccs])[y,i]
		end
	end







	dfCapFleccs = DataFrame(
		Resource = gen_ccs[!,"Resource"], Zone = gen_ccs[!,:Zone],
		StartCap = gen_ccs[!,:Existing_Cap_Unit],
		RetCap = retcapfleccs[:],
		NewCap = capfleccs[:],
		EndCap = EndCapfleccs,
	)
	if setup["ParameterScale"] ==1
		dfCapFleccs.StartCap = dfCap.StartCap * ModelScalingFactor
		dfCapFleccs.RetCap = dfCap.RetCap * ModelScalingFactor
		dfCapFleccs.NewCap = dfCap.NewCap * ModelScalingFactor
		dfCapFleccs.EndCap = dfCap.EndCap * ModelScalingFactor
	end

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = sum(dfCapFleccs[!,:StartCap]), RetCap = sum(dfCapFleccs[!,:RetCap]),
			NewCap = sum(dfCapFleccs[!,:NewCap]), EndCap = sum(dfCapFleccs[!,:EndCap]),
		)

	dfCapFleccs = vcat(dfCapFleccs, total)
	CSV.write(string(path,sep,"capacity_fleccs.csv"), dfCapFleccs)
	return dfCapFleccs
end
