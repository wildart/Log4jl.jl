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
typealias LOGCONFIG   Nullable{LoggerConfig}

function LoggerConfig(name::AbstractString, level::Level.EventLevel,
                                    additive::Bool = true, appenders::APPENDERS=APPENDERS())
    return LoggerConfig(name, LEVEL(level), additive, appenders,
                                      LOGCONFIG(), FACTORY(Log4jlEvent))
end
LoggerConfig(level::Level.EventLevel) = LoggerConfig("", level)
LoggerConfig() = LoggerConfig(Level.ERROR)

"Returns the logging level"
level(lc::LoggerConfig) = get(lc.level, level(lc.parent))

"Returns the value of the additive flag"
isadditive(lc::LoggerConfig) = lc.additive

"Logs an event"
log(lc::LoggerConfig, evnt::Event) = map(apnd_ref->apnd_ref(evnt), values(lc.appenders))
log(lc::LoggerConfig, logger, fqmn, marker, level, msg) =
    log(lc, call(LOG4JL_LOG_EVENT, logger, fqmn, marker, level, msg)) #TODO: properties

show(io::IO, lc::LoggerConfig) = print(io, "LoggerConfig(", isempty(lc.name) ? "root" : lc.name , ")")


"Null configuration"
type NullConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    root::LoggerConfig

    NullConfiguration() = new("Null", "", LoggerConfig(Level.OFF))
end
appender(cfg::NullConfiguration, name::AbstractString) = nothing
appenders(cfg::NullConfiguration) = APPENDERS()
logger(cfg::NullConfiguration, name::AbstractString) = nothing
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
logger(cfg::DefaultConfiguration, name::AbstractString) = get(cfg.loggers, name, nothing)
loggers(cfg::DefaultConfiguration) = cfg.loggers
