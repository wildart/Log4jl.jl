# Abstract methods

function start(cfg::Configuration)
    debug(LOGGER, "Starting configuration $cfg")
    state!(cfg, LifeCycle.STARTING)

    setup(cfg)
    configure(cfg)

    # for l in values(loggers(cfg))
    #     start(l)
    # end

    # Start all appenders
    for a in values(appenders(cfg))
        start(a)
    end

    # start(root)

    state!(cfg, LifeCycle.STARTED)
    debug(LOGGER, "Started configuration $cfg OK.")
end

function stop(cfg::Configuration)
    state!(cfg, LifeCycle.STOPPING)
    trace(LOGGER, "Stopping $(cfg)...")
    #TODO: stop loggers

    # stop appenders
    c = 0
    for a in values(appenders(cfg))
        if state(a) == LifeCycle.STARTED
            stop(a)
            c+=1
        end
    end
    trace(LOGGER, "Stopped $c appenders in $(cfg)")

    state!(cfg, LifeCycle.STOPPED)
    trace(LOGGER, "Stopped $(cfg)")
end


"""Locates the appropriate `LoggerConfig` for a `Logger` name.

 This will remove tokens from the name as necessary or return the root `LoggerConfig` if no other matches were found.
"""
function logger(loggers::LOGCONFIGS, name::AbstractString, root::LoggerConfig)
    name in keys(loggers) && return loggers[name]
    pname = name
    while (pos = rsearch(pname, '.') ) != 0
        pname = pname[1:pos-1]
        pname in keys(loggers) && return loggers[pname]
    end
    return root
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

"Form evaluation script for a configuration parser"
function formConfiguration(config_file, parser_type)
    # Check if parser exists and form configuration evaluator
    if !isnull(parser_type)
        pts = get(parser_type) |> string |> lowercase
        parser_call = replace(LOG4JL_CONFIG_PARSER_CALL, "<type>", pts)
        ptscript = joinpath(dirname(@__FILE__), "config", "$(pts).jl")
        Nullable(parse("include(\"$ptscript\"); $(parser_call)(\"$(config_file)\")"))
    else
        Nullable{Expr}() # or return empty
    end
end
