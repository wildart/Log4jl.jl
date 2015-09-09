"Logger configuration"
type LoggerConfig
    name::AbstractString
    level::Level.EventLevel
    additive::Bool
    parent::Nullable{LoggerConfig}
    appenders::Dict{AbstractString, AppenderRef}
    event::FACTORY
    #properties::Dict{Property, Bool}
end

typealias LOGCONFIGS Dict{AbstractString, LoggerConfig}
typealias LOGCONFIG   Nullable{LoggerConfig}

function LoggerConfig(name::AbstractString, level::Level.EventLevel, additive::Bool)
    LoggerConfig(name, level, additive,
        LOGCONFIG(), APPENDERS(), FACTORY(Log4jlEvent))
end
LoggerConfig(level::Level.EventLevel) = LoggerConfig("", level, true)
LoggerConfig() = LoggerConfig(Level.ERROR)

#call(Log4jl.LOG4JL_LOG_EVENT, UInt64(0))


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
