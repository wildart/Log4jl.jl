"YAML configuration"
type YamlConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State

    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS
    root::LoggerConfig
    #customLevels

    data::Dict # Configuration data
end

# Register configuration type
LOG4JL_CONFIG_TYPES[:YAML] = YamlConfiguration
LOG4JL_CONFIG_EXTS[:YAML]  = [".yaml", ".yml"]


function YamlConfiguration(cfgloc::AbstractString, cfgname::AbstractString="YAML")
    eval(:(import YAML)) # Package lazy eval
    conf = YAML.load(open(cfgloc))

    # Set status logger parameters
    if haskey(conf, "configuration")
        stat = conf["configuration"]
        cfgname = get(stat, "name", cfgname)
        haskey(stat, "status") && level!(LOGGER, evaltype((stat["status"] |> uppercase), "Level"))
    else
        error(LOGGER, "Malformed configuration: `configuration` node does not exist.")
    end

    YamlConfiguration(cfgname, cfgloc, LifeCycle.INITIALIZED,
                      PROPERTIES(), APPENDERS(), LOGCONFIGS(), LoggerConfig(),
                      conf)
end
getconfig(::Type{YamlConfiguration}, cfgloc::AbstractString, cfgname::AbstractString="YAML") = YamlConfiguration(cfgloc, cfgname)

appender(cfg::YamlConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::YamlConfiguration) = cfg.appenders
logger(cfg::YamlConfiguration, name::AbstractString) = logger(cfg.loggers, name, cfg.root)
loggers(cfg::YamlConfiguration) = cfg.loggers

function setup(cfg::YamlConfiguration)
    # if configuration is malformed
    if !haskey(cfg.data, "configuration")
        warn(LOGGER, "Malformed configuration: creating default ERROR-level Root logger with Console appender")
        default!(cfg)
        return
    end
    conf = cfg.data["configuration"]

    # parse properties
    haskey(conf, "properties") && for p in values(conf["properties"])
        cfg.properties[p["name"]] = p["value"]
    end
    # update appenders and loggers with pattern values
    for (k,v) in cfg.properties
        haskey(conf, "appenders") && subst_value(conf["appenders"], k, v)
        haskey(conf, "loggers")   && subst_value(conf["loggers"], k, v)
    end

    # parse appenders
    haskey(conf, "appenders") && for (atype, aconf) in conf["appenders"]
        # get appender type
        apndType = contains(atype, ".") ?
                   evaltype(atype, "") :
                   evaltype(atype, "Appenders")
        apndType === Void && continue

        # find first layout description and create layout object
        akeys = collect(keys(aconf))
        lidxs = find(s->contains(s,"layout"), map(lowercase, akeys))
        if length(lidxs) > 0 # take first layout description
            strLType = akeys[lidxs[1]]
            # get type from internal
            lytType = contains(strLType, ".") ?
                      evaltype(strLType, "") :
                      evaltype(strLType, "Layouts")
            if lytType !== Void
                aconf[:layout] = lytType(aconf[strLType])
            end
        end

        # create appender object
        cfg.appenders[aconf["name"]] = apndType(aconf)
    end
end

function configure(cfg::YamlConfiguration)
    conf = cfg.data["configuration"]

    refs = Dict[]

    # add loggers
    if haskey(conf, "loggers")
        lconf = conf["loggers"]

        # if there is a root logger configuration
        if haskey(lconf, "root")
            rconf = lconf["root"]
            cfg.root.level = configlevel(rconf)

            if haskey(rconf, "appenderref")
                push!(refs, Dict("name"=>"root", "appenderref" => rconf["appenderref"]))
            end
        else
            LOGGER.warn("No Root logger was configured, creating default ERROR-level Root logger with Console appender")
            default!(cfg)
        end

        # if there are other logger configuration
        if haskey(lconf, "logger")
            for lcconf in lconf["logger"]
                lcname = lcconf["name"]
                lcadd = get(lcconf, "additivity", true)
                lclvl = configlevel(lcconf)
                cfg.loggers[lcname] = LoggerConfig(lcname, lclvl, lcadd)
            end
            append!(refs, lconf["logger"])
        end
    else
        warn(LOGGER, "No Loggers were configured, using default. Is the Loggers element missing?")
        default!(cfg)
    end

    # configure references
    for lcconf in refs
        lcname = lcconf["name"]
        lc = lcname == "root" ? cfg.root : cfg.loggers[lcname]
        lcconf_arefs = lcconf["appenderref"]
        lcconf_arefs = isa(lcconf_arefs, Dict) ? [lcconf_arefs] : lcconf_arefs
        for lcconf_aref in lcconf_arefs
            if haskey(lcconf_aref, "ref")
                aref = lcconf_aref["ref"]
                if haskey(cfg.appenders, aref)
                    apnd = cfg.appenders[aref]
                    reference!(lc, apnd, configlevel(lcconf_aref))
                else
                    error(LOGGER, "Unable to locate appender '$aref' for logger '$lcname'")
                end
            else
                error(LOGGER, "No reference provided for logger '$lcname'")
            end
        end
    end

    # setup parents
    parents!(cfg)
end

function subst_value(conf::Dict, k::AbstractString, v::AbstractString)
    for (dk,dv) in conf
        if isa(dv, AbstractString)
            pat = "\${$k}"
            if contains(dv, pat)
                conf[dk] = replace(dv, pat, v)
            end
        elseif isa(dv, Dict)
            subst_value(dv, k, v)
        end
    end
    return conf
end
