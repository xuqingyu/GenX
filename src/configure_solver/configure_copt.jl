
"""
    configure_copt(solver_settings_path::String, optimizer::Type=COPT.Optimizer)

配置 COPT 求解器参数，严格遵循 COPT 7.0 官方参数命名。
支持参数名兼容性替换，自动过滤无效参数。
"""
function configure_copt(solver_settings_path::String, optimizer::Type=COPT.Optimizer)

    solver_settings = YAML.load_file(solver_settings_path) |> x -> convert(Dict{String, Any}, x)
    solver_settings = rename_keys(solver_settings,
        Dict("Pre_Solve" => "Presolve", "LPMethod" => "LpMethod"))

    valid_params = Set([
        "TimeLimit",   
        "Logging", 
        "Threads",      # 并行线程数
        "Presolve",    
        "LpMethod",
        "CutLevel",
        "RelGap",
        "Crossover"
    
    ])

 
    default_settings = Dict(
        "TimeLimit" => Inf,
        "Logging" => 1,
        "Threads" => 4,
        "Presolve" => -1,
        "LpMethod" => 2,
        "CutLevel" => 2,
        "RelGap" => 1e-3
    )


    final_settings = Dict{String, Any}()
    for (k, v) in merge(default_settings, solver_settings)
        if k in valid_params
            final_settings[k] = v
        else
            @warn "para '$k' is not effective in COPT (Effective: $(join(valid_params, ", "))"
        end
    end

    if haskey(final_settings, "NodeStorageDir") && final_settings["NodeStorageDir"] != ""
        mkpath(final_settings["NodeStorageDir"])
    end

    return optimizer_with_attributes(optimizer, final_settings...)
end
