"Null configuration"
type NullConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State

    root::LoggerConfig

    NullConfiguration(cfgloc::AbstractString="") = new("Null", cfgloc, LifeCycle.INITIALIZED, LoggerConfig(Level.OFF))
end
appender(cfg::NullConfiguration, name::AbstractString) = nothing
appenders(cfg::NullConfiguration) = APPENDERS()
logger(cfg::NullConfiguration, name::AbstractString) = root
loggers(cfg::NullConfiguration) = LOGCONFIGS()
state(cfg::NullConfiguration) = LifeCycle.STOPPED
setup(cfg::NullConfiguration) = nothing
configure(cfg::NullConfiguration) = nothing


"Default Log4jl configuration"
type DefaultConfiguration <: Configuration
    name::AbstractString
    source::AbstractString
    state::LifeCycle.State

    properties::PROPERTIES
    appenders::APPENDERS
    loggers::LOGCONFIGS
    root::LoggerConfig
    #customLevels

    DefaultConfiguration(cfgloc::AbstractString="") =
        new("Default", cfgloc, LifeCycle.INITIALIZED, PROPERTIES(), APPENDERS(), LOGCONFIGS(), LoggerConfig())
end
appender(cfg::DefaultConfiguration, name::AbstractString) = get(cfg.appenders, name, nothing)
appenders(cfg::DefaultConfiguration) = cfg.appenders
logger(cfg::DefaultConfiguration, name::AbstractString) = logger(cfg.loggers, name, cfg.root)
loggers(cfg::DefaultConfiguration) = cfg.loggers

function setup(cfg::DefaultConfiguration)
    cfg.appenders["STDOUT"] = Appenders.ColorConsole(
        Dict(
            :layout => Layouts.BasicLayout()
        )
    )
end

function configure(cfg::DefaultConfiguration)
    # Reference appender to root configuration
    reference(cfg.root, cfg.appenders["STDOUT"])
end
