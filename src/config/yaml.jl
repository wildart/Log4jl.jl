"YAML configuration"
type YamlConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State
    root::LoggerConfig

    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS
    filter::FILTER

    data::Dict # Configuration data
end

# Register configuration type
LOG4JL_CONFIG_TYPES[:YAML] = YamlConfiguration
LOG4JL_CONFIG_EXTS[:YAML]  = [".yaml", ".yml"]


function YamlConfiguration(cfgloc::AbstractString, cfgname::AbstractString="YAML")
    eval(:(import YAML)) # Package lazy eval
    conf = YAML.load(open(cfgloc))
    fltr = FILTER()

    # Set status logger parameters
    if haskey(conf, "configuration")
        stat = conf["configuration"]
        cfgname = get(stat, "name", cfgname)
        # custom levels
        haskey(conf["configuration"], "customlevels") && for (l,v) in conf["configuration"]["customlevels"]
            Level.add(symbol(l), Int32(v))
        end
        # status
        haskey(stat, "status") && level!(LOGGER, evaltype((stat["status"] |> uppercase), "Level"))
        # filters
        fltrs = filterconfig(stat, "filter")
        if length(fltrs) > 0
            fltr = parsefilters(fltrs)
        end
    else
        error(LOGGER, "Malformed configuration: `configuration` node does not exist.")
    end
    YamlConfiguration(cfgname, cfgloc, LifeCycle.INITIALIZED, LoggerConfig(),
                      PROPERTIES(), APPENDERS(), LOGCONFIGS(), fltr, conf)
end
getconfig(::Type{YamlConfiguration}, cfgloc::AbstractString, cfgname::AbstractString="YAML") = YamlConfiguration(cfgloc, cfgname)

appender(cfg::YamlConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::YamlConfiguration) = cfg.appenders
loggers(cfg::YamlConfiguration) = cfg.loggers

function configure(cfg::YamlConfiguration)
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
        apndCfg = Dict{AbstractString,Any}(aconf)

        # find first layout description and create layout object
        lyts = filterconfig(aconf, "layout")
        if length(lyts) > 0 # take first layout description
            strLType = first(keys(lyts))
            # get type from internal
            lytType = contains(strLType, ".") ?
                      evaltype(strLType, "") :
                      evaltype(strLType, "Layouts")
            if lytType !== Void
                apndCfg["layout"] = lytType(aconf[strLType])
            end
            delete!(apndCfg, strLType)
        end

        # check filters
        fltrs = filterconfig(apndCfg, "filter")
        if length(fltrs) > 0
            fltr = parsefilters(fltrs)
            apndCfg["filter"] = fltr
            for strFType in keys(fltrs)
                delete!(apndCfg, strFType)
            end
        end

        # create appender object
        cfg.appenders[aconf["name"]] = apndType(apndCfg)
    end

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
            warn(LOGGER, "No Root logger was configured, creating default ERROR-level Root logger with Console appender")
            default!(cfg)
        end

        # if there are other logger configuration
        if haskey(lconf, "logger")
            for lcconf in lconf["logger"]
                lcname = lcconf["name"]
                lcadd = get(lcconf, "additivity", false)
                lclvl = configlevel(lcconf)
                #TODO: add filters
                logger!(cfg, lcname, LoggerConfig(lcname, level=lclvl, additive=lcadd))
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
                    #TODO: add filters
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

function filterconfig(conf::Dict, stype::AbstractString)
    ckeys = collect(keys(conf))
    lidxs = find(s->contains(s,stype), map(lowercase, ckeys))
    return if length(lidxs) > 0
        filter((k,v)->k in ckeys[lidxs], conf)
    else
        Dict()
    end
end

function parsefilters(conf::Dict)
    fltrs = Filter[]
    for (fltrstrtype, fltrcfg) in conf
        fltrtype = evaltype(fltrstrtype, "")
        fltr = (fltrcfg === nothing) ? fltrtype() : fltrtype(Dict{AbstractString,Any}(fltrcfg))
        fltr !== nothing && push!(fltrs, fltr)
    end
    fltrcount = length(fltrs)
    return if fltrcount == 0
        FILTER()
    elseif fltrcount == 1
        FILTER(fltrs[1])
    else
        FILTER(CompositeFilter(fltrs))
    end
end