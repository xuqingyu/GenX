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
	write_twentyfourseven(EP::Model, inputs::Dict, setup::Dict)
"""
function write_twentyfourseven(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    NumberofTFS = inputs["NumberofTFS"]
    dfGen = inputs["dfGen"]
    T = inputs["T"]
    G = inputs["G"]
    ALLGEN = collect(1:inputs["G"])
    STOR_ALL = inputs["STOR_ALL"]
    FLEX = inputs["FLEX"]

    dfCFE = DataFrame(Policy_ID = 1:NumberofTFS, AnnualSum = zeros(NumberofTFS))
    tempcfe = value.(EP[:eCFE])
    if setup["ParameterScale"] == 1
        tempcfe = tempcfe * ModelScalingFactor
    end
    dfCFE.AnnualSum .= tempcfe * inputs["omega"]
    dfCFE = hcat(dfCFE, DataFrame(tempcfe, [Symbol("t$t") for t in 1:T]))
    CSV.write(string(path, sep, "tfs_cfe.csv"), dftranspose(dfCFE, false), writeheader = false)


    dfEX = DataFrame(Policy_ID = 1:NumberofTFS, AnnualSum = zeros(NumberofTFS))
    tempex = value.(EP[:vEX])
    if setup["ParameterScale"] == 1
        tempex = tempex * ModelScalingFactor
    end
    dfEX.AnnualSum .= tempex * inputs["omega"]
    dfEX = hcat(dfEX, DataFrame(tempex, [Symbol("t$t") for t in 1:T]))
    CSV.write(string(path, sep, "tfs_ex.csv"), dftranspose(dfEX, false), writeheader = false)

    dfSF = DataFrame(Policy_ID = 1:NumberofTFS, AnnualSum = zeros(NumberofTFS))
    tempsf = value.(EP[:vSF])
    if setup["ParameterScale"] == 1
        tempsf = tempsf * ModelScalingFactor
    end
    dfSF.AnnualSum .= (tempsf .* transpose(inputs["TFS_SFDT"])) * inputs["omega"]
    dfSF = hcat(dfSF, DataFrame(tempsf, [Symbol("t$t") for t in 1:T]))
    CSV.write(string(path, sep, "tfs_sf.csv"), dftranspose(dfSF, false), writeheader = false)

    dfModifiedLoad = DataFrame(Policy_ID = 1:NumberofTFS, AnnualSum = zeros(NumberofTFS))
    tempmd = value.(EP[:eModifiedload])
    if setup["ParameterScale"] == 1
        tempmd = tempmd * ModelScalingFactor
    end
    dfModifiedLoad.AnnualSum .= tempmd * inputs["omega"]
    dfModifiedLoad = hcat(dfModifiedLoad, DataFrame(tempmd, [Symbol("t$t") for t in 1:T]))
    CSV.write(string(path, sep, "tfs_modifiedload.csv"), dftranspose(dfModifiedLoad, false), writeheader = false)

    if (NumberofTFS) > 1
        NumberofTFSPath = inputs["NumberofTFSPath"]
        dfTFSFlow = DataFrame(RPSH_PathID=1:NumberofTFSPath, AnnualSum=zeros(NumberofTFSPath))
        temptfsflow = value.(EP[:eTFSFlow])
        if setup["ParameterScale"] == 1
            temptfsflow = temptfsflow * ModelScalingFactor
        end
        dfTFSFlow.AnnualSum .= temptfsflow * inputs["omega"]
        dfTFSFlow = hcat(dfTFSFlow, DataFrame(temptfsflow, [Symbol("t$t") for t in 1:T]))
        CSV.write(string(path, sep, "tfs_tfsflow.csv"), dftranspose(dfTFSFlow, false), writeheader=false)
    
        dfTFSExport = DataFrame(Policy_ID=1:NumberofTFS, AnnualSum=zeros(NumberofTFS))
        temptfsexport = value.(EP[:eTFSNetExport])
        if setup["ParameterScale"] == 1
            temptfsexport = temptfsexport * ModelScalingFactor
        end
        dfTFSExport.AnnualSum .= temptfsexport * inputs["omega"]
        dfTFSExport = hcat(dfTFSExport, DataFrame(temptfsexport, [Symbol("t$t") for t in 1:T]))
        CSV.write(string(path, sep, "tfs_tfsexport.csv"), dftranspose(dfTFSExport, false), writeheader=false)
    
        dfTFSTransactionCost = DataFrame(RPSH_PathID=1:NumberofTFSPath, AnnualSum=zeros(NumberofTFSPath))
        temptfstranscationcost = value.(EP[:eTFSTranscationCost])
        if setup["ParameterScale"] == 1
            temptfstranscationcost = temptfstranscationcost * (ModelScalingFactor^2)
        end
        dfTFSTransactionCost.AnnualSum .= temptfstranscationcost * inputs["omega"]
        dfTFSTransactionCost = hcat(dfTFSTransactionCost, DataFrame(temptfstranscationcost, [Symbol("t$t") for t in 1:T]))
        CSV.write(string(path, sep, "tfs_tfstransactioncost.csv"), dftranspose(dfTFSTransactionCost, false), writeheader=false)
    end

    dfShorfalllimitprice = DataFrame(Policy_ID = 1:NumberofTFS, Price = vec(dual.(EP[:cRPSH_Shortfalllimit])))
    if setup["ParameterScale"] == 1
        dfShorfalllimitprice.Price = dfShorfalllimitprice.Price * ModelScalingFactor
    end
    CSV.write(string(path, sep, "tfs_shortfalllimitprice.csv"), dfShorfalllimitprice)

    dfExceedlimitprice = DataFrame(Policy_ID = 1:NumberofTFS, Price = vec(dual.(EP[:cRPSH_Exceedlimit])))
    if setup["ParameterScale"] == 1
        dfExceedlimitprice.Price = dfExceedlimitprice.Price * ModelScalingFactor
    end
    CSV.write(string(path, sep, "tfs_exceedlimitprice.csv"), dfExceedlimitprice)

    dfTFSPrice = DataFrame(Policy_ID = 1:NumberofTFS)
    temprice = transpose((dual.(EP[:cRPSH_HourlyMatching]) ./ inputs["omega"]))
    if setup["ParameterScale"] == 1
        temprice = temprice * ModelScalingFactor
    end
    dfTFSPrice = hcat(dfTFSPrice, DataFrame(temprice, [Symbol("t$t") for t in 1:T]))
    CSV.write(string(path, sep, "tfs_price.csv"), dftranspose(dfTFSPrice, false), writeheader = false)

    dfTFSGenRevenue = DataFrame(Resource = inputs["RESOURCES"], Zone = dfGen[!, :Zone], AnnualSum = zeros(G))
    tempinjection = zeros(G, T)
    tempinjection[setdiff(ALLGEN, union(STOR_ALL, FLEX)), :] = value.(EP[:vP])[setdiff(ALLGEN, union(STOR_ALL, FLEX)), :]
    if (!isempty(STOR_ALL))
        tempinjection[STOR_ALL, :] = value.(EP[:vP])[STOR_ALL, :] - (value.(EP[:vCHARGE][STOR_ALL, :])).data
    end
    if (!isempty(FLEX))
        tempinjection[FLEX, :] = (value.(EP[:vCHARGE_FLEX][FLEX, :])).data - value.(EP[:vP])[FLEX, :]
    end
    for rpsh in 1:NumberofTFS
        temprevenue = (tempinjection * (dual.(EP[:cRPSH_HourlyMatching][:, rpsh]))) .* dfGen[:, Symbol("RPSH_$rpsh")]
        if setup["ParameterScale"] == 1
            temprevenue = temprevenue * (ModelScalingFactor^2)
        end
        dfTFSGenRevenue.AnnualSum .= dfTFSGenRevenue.AnnualSum + vec(temprevenue)
        dfTFSGenRevenue = hcat(dfTFSGenRevenue, DataFrame([temprevenue], [Symbol("RPSH_$rpsh")]))
    end
    CSV.write(string(path, sep, "tfs_genrevenue.csv"), dfTFSGenRevenue)

    dfTFSLoadCost = DataFrame(Policy_ID = 1:NumberofTFS, AnnualSum = zeros(NumberofTFS))
    tempcost = vec(sum(transpose(inputs["TFS_Load"] .* dual.(EP[:cRPSH_HourlyMatching])), dims = 2))
    if setup["ParameterScale"] == 1
        tempcost = tempcost * (ModelScalingFactor^2)
    end
    dfTFSLoadCost.AnnualSum .= vec(sum(transpose(inputs["TFS_Load"] .* dual.(EP[:cRPSH_HourlyMatching])), dims = 2))
    CSV.write(string(path, sep, "tfs_loadcost.csv"), dfTFSLoadCost)

end