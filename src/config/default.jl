"Null configuration"
type NullConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State
    root::LoggerConfig

    NullConfiguration() = new("Null", "", LifeCycle.INITIALIZED, LoggerConfig(Level.OFF))
end
appender(cfg::NullConfiguration, name::AbstractString) = nothing
appenders(cfg::NullConfiguration) = APPENDERS()
appender!(cfg::NullConfiguration, nm::AbstractString, apnd::Appender) = nothing
logger(cfg::NullConfiguration, name::AbstractString) = cfg.root
loggers(cfg::NullConfiguration) = LOGCONFIGS()
logger!(cfg::NullConfiguration, nm::AbstractString, lc::LoggerConfig) = nothing
state(cfg::NullConfiguration) = LifeCycle.STOPPED
setup(cfg::NullConfiguration) = nothing
configure(cfg::NullConfiguration) = nothing

# Register configuration type
LOG4JL_CONFIG_TYPES[:NULL] = NullConfiguration


"Default Log4jl configuration"
type DefaultConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State
    root::LoggerConfig

    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS

    DefaultConfiguration() =
        new("Default", "", LifeCycle.INITIALIZED, LoggerConfig(), PROPERTIES(), APPENDERS(), LOGCONFIGS())
end
appender(cfg::DefaultConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::DefaultConfiguration) = cfg.appenders
loggers(cfg::DefaultConfiguration) = cfg.loggers

function configure(cfg::DefaultConfiguration)
    # Add basic console appender
    appender!(cfg, Default = Appenders.Console(layout = Layouts.BasicLayout()))

    # Reference appender to root configuration
    reference!(cfg, ROOT_LOGGER_NAME => "Default")
end

# Register configuration type
LOG4JL_CONFIG_TYPES[:DEFAULT] = DefaultConfiguration
