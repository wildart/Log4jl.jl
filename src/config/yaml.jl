using YAML

"YAML configuration"
type YamlConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS
    root::LoggerConfig
    #customLevels
end
appender(cfg::YamlConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::YamlConfiguration) = cfg.appenders
logger(cfg::YamlConfiguration, name::AbstractString) = logger(cfg.loggers, name, cfg.root)
loggers(cfg::YamlConfiguration) = cfg.loggers

function YamlConfiguration()
    properties = PROPERTIES()
    appenders = APPENDERS(
        "STDOUT" => Appenders.ColorConsole(Dict(
            :layout => Layouts.BasicLayout() #TODO: PatternLayout
        ))
    )

    # Reference appender to root configuration
    root =  LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL)
    reference(root, appenders["STDOUT"])

    return new("Default", "", properties, appenders, LOGCONFIGS(), root)
end

function parse_yaml_config(filename)
    conf = YAML.load(open(filename))["configuration"]
    csource = filename
    cname = get(conf, "name", "YAML")
    status = LEVEL(haskey(conf, "status") ? evaltype((conf["status"] |> uppercase), "Level") : nothing)

    # parse properties
    properties = PROPERTIES()
    haskey(conf, "properties") && for p in values(conf["properties"])
        properties[p["name"]] = p["value"]
    end

    # parse appenders
    appenders = APPENDERS()
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
        appenders[aconf["name"]] = apndType(aconf)
    end

    # parse loggers
    loggers = LOGCONFIGS()
    root = LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL)

    if haskey(conf, "loggers")
        lconf = conf["loggers"]

        # there is a root logger configuration
        if haskey(lconf, "root")
            rconf = lconf["root"]
            root.level = configlevel(rconf)
            if haskey(rconf, "appenderref")
                rconf_aref = rconf["appenderref"]
                if isa(rconf_aref, Dict)
                    reference(root, appenders[rconf_aref["ref"]], configlevel(rconf_aref))
                else
                    for rconf_aref in rconf["appenderref"]
                        reference(root, appenders[rconf_aref["ref"]], configlevel(rconf_aref))
                    end
                end
            end
        end

        # there are other logger configuration
        if haskey(lconf, "logger")
            for lcconf in lconf["logger"]
                lcname = lcconf["name"]
                lcadd = get(lcconf, "additivity", true)
                lclvl = configlevel(lcconf)

                lc = LoggerConfig(lcname, lclvl, lcadd)
                lcconf_aref = lcconf["appenderref"]
                if isa(lcconf_aref, Dict)
                    reference(lc, appenders[lcconf_aref["ref"]], configlevel(lcconf_aref))
                else
                    for lcconf_aref in lcconf["appenderref"]
                        reference(lc, appenders[lcconf_aref["ref"]], configlevel(lcconf_aref))
                    end
                end

                loggers[lcname] = lc
            end
        end
    end

    return YamlConfiguration(cname, csource, properties, appenders, loggers, root)
end