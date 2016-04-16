# Abstract methods

"Initialize the configuration."
function start(cfg::Configuration)
    debug(LOGGER, "Starting configuration $cfg")
    state!(cfg, LifeCycle.STARTING)

    configure(cfg)

    # start context-wide filters
    cfgflt = filter(cfg)
    !isnull(cfgflt) && start(get(cfgflt))

    #TODO: start loggers, it's needed for filters
    # for l in values(loggers(cfg))
    #     start(l)
    # end

    # Start all appenders
    for apnd in values(appenders(cfg))
        start(apnd)
    end

    # start(root) #TODO: start root it's needed for filters

    state!(cfg, LifeCycle.STARTED)
    debug(LOGGER, "Started configuration $cfg OK.")
end

"Shutdown the configuration."
function stop(cfg::Configuration)
    state!(cfg, LifeCycle.STOPPING)
    trace(LOGGER, "Stopping $(cfg)...")

    # stop appenders
    c = 0
    for apnd in values(appenders(cfg))
        if state(apnd) == LifeCycle.STARTED
            stop(apnd)
            c+=1
        end
    end
    trace(LOGGER, "Stopped $c appenders in $(cfg)")

    # stop context-wide filters
    cfgflt = filter(cfg)
    !isnull(cfgflt) && stop(get(cfgflt))

    #TODO: stop loggers' filters
    c = 0
    # for lc in values(loggers(cfg))
    #     stop(lc)
    #     c+=1
    # end
    trace(LOGGER, "Stopped $c loggers in $(cfg)")

    # stop(root) #TODO: stop root, it's needed for filters

    state!(cfg, LifeCycle.STOPPED)
    trace(LOGGER, "Stopped $(cfg)")
end


"""Locates the appropriate `LoggerConfig` for a specified name.

 This will remove tokens from the name as necessary or return the root `LoggerConfig` if no other matches were found.
"""
function logger(cfg::Configuration, lcname::AbstractString)
    lgrs = loggers(cfg)
    haskey(lgrs, lcname) && return lgrs[lcname]
    lcpname = lcname
    while (pos = rsearch(lcpname, '.') ) != 0
        lcpname = lcpname[1:pos-1]
        haskey(lgrs, lcpname) && return lgrs[lcpname]
    end
    return root(cfg)
end

"Add explicitly a `LoggerConfig` to the configuration."
function logger!(cfg::Configuration, lcname::AbstractString, lc::LoggerConfig)
    if isdefined(cfg, :loggers) && isa(cfg.loggers, LOGCONFIGS)
        cfg.loggers[lcname] = lc
        return lc
    else
        error(LOGGER, "Configuration does not have `loggers` field of type $LOGCONFIGS")
        return nothing
    end
end

function logger!(cfg::Configuration, lcname::AbstractString, lvl::Level.EventLevel = Level.ALL)
    lc = LoggerConfig(lcname, lvl)
    return logger!(cfg, lcname, lc)
end

"Add explicitly an appender to the configuration."
function appender!(cfg::Configuration, apndname::AbstractString, apnd::Appender)
    if isdefined(cfg, :appenders) && isa(cfg.appenders, APPENDERS)
        cfg.appenders[apndname] = apnd
        return apnd
    else
        error(LOGGER, "Configuration does not have `appenders` field of type $APPENDERS")
        return nothing
    end
end

"Add an appender to the configuration as a kw pair."
function appender!(cfg::Configuration; kwargs...)
    for (k,w) in kwargs
        if isa(w, Appender)
            appender!(cfg, string(k), w)
        else
            error(LOGGER, "Invalid appender: $k")
        end
    end
end

"Cross-reference a logger configuration with an appender in the configuration."
function reference!{T<:AbstractString}(cfg::Configuration, refcfg::Pair{T,T})
    logcfg = logger(cfg, refcfg[1])
    apnd = appender(cfg, refcfg[2])
    apnd === nothing && return nothing
    return reference!(logcfg, apnd)
end

"Set a default configuration (i.e. the root logger is set with the console appender)."
function default!(cfg::Configuration)
    appender!(cfg, Default = Appenders.Console(layout = Layouts.BasicLayout()))
    return reference!(cfg, ROOT_LOGGER_NAME => "Default")
end

"Build logger configuration hierarchy"
function parents!(cfg::Configuration)
    for (lcname,lc) in loggers(cfg)
        lname = name(lc)
        i = rsearch(lname, '.')
        if i > 0
            parent = logger(cfg, lname[1:i-1])
            parent!(lc, parent)
        else
            parent!(lc, root(cfg))
        end
    end
end

# Some configuration implementations
include("config/default.jl")
include("config/yaml.jl")

# helper hunctions

"Evaluate a configuration"
function evalConfiguration(config_eval)
    if isnull(config_eval)
        trace(LOGGER, "Configuration is empty. Using default configuration.")
        DefaultConfiguration()
    else
        try
            eval(Log4jl, get(config_eval)) # evaluate configuration in Log4jl module
        catch err
            error(LOGGER, "Configuration failed. Using default configuration. Error: $(err)")
            DefaultConfiguration()
        end
    end
end

"Search a configuration file in a specified directory and identify its parser"
function searchConfiguration(search_dir)
    parser_type = Nullable{Symbol}()
    config_file = ""
    # Search for default configuration file
    for (p,exts) in LOG4JL_CONFIG_EXTS
        for ext in exts
            cf = joinpath(search_dir, LOG4JL_CONFIG_DEFAULT_PREFIX*ext)
            if isfile(cf)
                config_file = cf
                parser_type = Nullable(p)
                break
            end
        end
        !isempty(config_file) && break
    end
    debug(LOGGER, "Found configuration file: $config_file. Parser: $(get(parser_type, :NA))")
    config_file, parser_type
end

"Detect a configuration parser from a configuration file"
function findConfigurationParser(config_file)
    parser_type = Nullable{Symbol}()
    !isfile(config_file) && return parser_type
    cfg_prefix, cfg_ext= splitext(config_file)
    for (p,exts) in LOG4JL_CONFIG_EXTS
        if cfg_ext in exts
            parser_type = Nullable(p)
            break
        end
    end
    debug(LOGGER, "Parser detected: $(get(parser_type, :NA))")
    return parser_type
end

"Locate configuration resource"
function locateconfig(cfgloc::AbstractString, loader=nothing)
    # get module location
    cmdir = isa(loader, Module) ? moduledir(loader) : pwd()

    config_file, parser_type = if isempty(cfgloc)
        # search the module directory for configurations
        searchConfiguration(cmdir)
    else
        (isabspath(cfgloc) ? cfgloc : joinpath(cmdir, cfgloc), nothing)
    end

    !isfile(config_file) && return ""

    return config_file
end

"Returns the `Configuration` from a module or loaded from a location."
function getconfig(cfgloc::AbstractString, cfgname::AbstractString, loader=nothing)

    # locate configuration
    config_file = locateconfig(cfgloc, loader)

    if !isempty(config_file)
        # find parser for provided configuration
        parser_type = findConfigurationParser(config_file)
        if !isnull(parser_type)
            cfgtype = LOG4JL_CONFIG_TYPES[get(parser_type, :DEFAULT)]
            try
                return isempty(cfgname) ? getconfig(cfgtype, config_file) :
                                          getconfig(cfgtype, config_file, cfgname)
            catch err
                error(LOGGER, "Configuration initialization error: $err.")
            end
        end
    end

    error(LOGGER, "No Log4jl configuration file found. Using default configuration: logging only errors to the console.")
    return DefaultConfiguration()
end
