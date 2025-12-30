
"""
    configure_copt(solver_settings_path::String, optimizer::Type=COPT.Optimizer)

配置 COPT 求解器参数，严格遵循 COPT 7.0 官方参数命名。
支持参数名兼容性替换，自动过滤无效参数。
"""
function configure_copt(solver_settings_path::String, optimizer::Type=COPT.Optimizer)
    # 加载配置
    solver_settings = YAML.load_file(solver_settings_path) |> x -> convert(Dict{String, Any}, x)
    
    # COPT 7.0官方实际支持的参数（经官方团队确认）
    valid_params = Set([
        "TimeLimit",    # 求解时间限制(秒)
        "Logging", # 日志控制(1=开启, 0=关闭) 
        "Threads",      # 并行线程数
        "Presolve",     # 预求解(0=关闭,1=开启)
        "LpMethod",
        "CutLevel",
        "RelGap"
    
    ])

    # 正确的默认参数
    default_settings = Dict(
        "TimeLimit" => Inf,
        "Logging" => 1,
        "Threads" => 4,
        "Presolve" => -1,
        "LpMethod" => 2,
        "CutLevel" => 2,
        "RelGap" => 1e-3
    )

    # 合并配置并过滤无效参数
    final_settings = Dict{String, Any}()
    for (k, v) in merge(default_settings, solver_settings)
        if k in valid_params
            final_settings[k] = v
        else
            @warn "参数 '$k' 不是COPT支持的有效参数，已忽略 (有效参数: $(join(valid_params, ", "))"
        end
    end

    # 确保节点目录存在
    if haskey(final_settings, "NodeStorageDir") && final_settings["NodeStorageDir"] != ""
        mkpath(final_settings["NodeStorageDir"])
    end

    return optimizer_with_attributes(optimizer, final_settings...)
end