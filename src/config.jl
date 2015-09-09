"Logger configuration"
type LoggerConfig
    name::AbstractString
    level::LEVEL
    additive::Bool
    appenders::Dict{AbstractString, AppenderRef}
    parent::Nullable{LoggerConfig}
    event::FACTORY
    #TODO: properties::Dict{Property, Bool}
    #TODO: filter::Filter
end

typealias LOGCONFIGS Dict{AbstractString, LoggerConfig}

# Constructors
function LoggerConfig(name::AbstractString, level::Level.EventLevel,
                                    additive::Bool = true, appenders::APPENDERS=APPENDERS())
    return LoggerConfig(name, LEVEL(level), additive, appenders,
                                      Nullable{LoggerConfig}(), FACTORY(Log4jlEvent))
end
LoggerConfig(level::Level.EventLevel) = LoggerConfig("", level)
LoggerConfig() = LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL)

"Returns the logging level"
level(lc::Nullable{LoggerConfig})   = isnull(lc) ? LOG4JL_DEFAULT_STATUS_LEVEL : level(get(lc))
level(lc::LoggerConfig) = get(lc.level, level(lc.parent))

"Returns the value of the additive flag"
isadditive(lc::LoggerConfig) = lc.additive

"Logs an event"
function log(lc::LoggerConfig, evnt::Event)
    println(evnt)
    map(ref->log(ref, evnt), values(lc.appenders))
    lc.additive && !isnull(lc.parent) && log(get(lc.parent), evnt)
end
function log(lc::LoggerConfig, logger, fqmn, level, marker, msg)
    log(lc, call(LOG4JL_LOG_EVENT, logger, fqmn, marker, level, msg)) #TODO: properties
end

show(io::IO, lc::LoggerConfig) = print(io, "LoggerConfig(", isempty(lc.name) ? "root" : lc.name, ":", level(lc) , ")")

"Check if message could be filtered based on its parametrs"
function isenabled(lc::LoggerConfig, lvl, marker, msg, params...)
    level(lc) > lvl && return false
    #TODO: add filters by marker and message content
    return true
end


"Null configuration"
type NullConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    root::LoggerConfig

    NullConfiguration() = new("Null", "", LoggerConfig(Level.OFF))
end
appender(cfg::NullConfiguration, name::AbstractString) = nothing
appenders(cfg::NullConfiguration) = APPENDERS()
logger(cfg::NullConfiguration, name::AbstractString) = root
loggers(cfg::NullConfiguration) = LOGCONFIGS()


"Default Log4jl configuration"
type DefaultConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS
    root::LoggerConfig
    #customLevels

    function DefaultConfiguration()
        properties = PROPERTIES()
        appenders = APPENDERS(
            "STDOUT" => Appenders.Console(Dict(
                :name  => "STDOUT",
                :layout => Layouts.BasicLayout(), #TODO: PatternLayout
                :io        => STDOUT
            ))
        )
        return new("Default", "", properties, appenders, LOGCONFIGS(), LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL))
    end
end
appender(cfg::DefaultConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::DefaultConfiguration) = cfg.appenders
logger(cfg::DefaultConfiguration, name::AbstractString) = logger(cfg.loggers, name, cfg.root)
loggers(cfg::DefaultConfiguration) = cfg.loggers

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