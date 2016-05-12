"Logger configuration"
type LoggerConfig <: Filterable
    name::AbstractString
    level::LEVEL
    additive::Bool

    appenders::AppenderReferences
    parent::Nullable{LoggerConfig}
    event::FACTORY

    # Filterable
    filter::FILTER
    state::LifeCycle.State

    #TODO: properties::Dict{Property, Bool}
end

typealias LOGCONFIGS Dict{AbstractString, LoggerConfig}

# Constructors
function LoggerConfig(name::AbstractString;
                      level::LEVEL = LEVEL(),
                      filter::FILTER=FILTER(),
                      additive::Bool = false)
    return LoggerConfig(name, level, additive,
                        AppenderReferences(),
                        Nullable{LoggerConfig}(),
                        FACTORY(LOG4JL_LOG_EVENT),
                        filter, LifeCycle.INITIALIZED)
end
LoggerConfig(lvl::Level.EventLevel) = LoggerConfig(ROOT_LOGGER_NAME, level=LEVEL(lvl))
LoggerConfig() = LoggerConfig(LOG4JL_DEFAULT_STATUS_LEVEL)

"Start the logging configuration."
function start(lc::LoggerConfig)
    trace(LOGGER, "Starting $lc.")
    state!(lc, LifeCycle.STARTING)
    start(filter(lc))
    state!(lc, LifeCycle.STARTED)
    trace(LOGGER, "Started $lc OK.")
end

"Disable the logging configuration."
function stop(lc::LoggerConfig)
    trace(LOGGER, "Stopping $lc.")
    # change state
    state!(lc, LifeCycle.STOPPING)
    # stop and remove appenders
    for (apnm, ref) in appenders
        delete!(appenderRefs, apnm)
        stop(ref)
    end
    # stop filter
    stop(filter(lc))
    # change state
    state!(lc, LifeCycle.STOPPED)
    trace(LOGGER, "Stoped $lc OK.")
end

"Returns the logger name"
name(lc::LoggerConfig) = lc.name

"Returns the logging level"
level(lc::Nullable{LoggerConfig}) = isnull(lc) ? LOG4JL_DEFAULT_STATUS_LEVEL : level(get(lc))
level(lc::LoggerConfig) = get(lc.level, level(lc.parent))
level!(lc::LoggerConfig, lvl::Level.EventLevel) = (lc.level = lvl)

"Returns the value of the additive flag"
isadditive(lc::LoggerConfig) = lc.additive

"Logs an event"
function log(lc::LoggerConfig, evnt::Event)
    isfiltered(lc.filter, evnt) && return # Logger filters are execuded
    for ref in values(lc.appenders)
        append!(ref, evnt)
    end
    lc.additive && !isnull(lc.parent) && log(get(lc.parent), evnt)
end
function log(lc::LoggerConfig, logger, fqmn, level, marker, msg)
    log(lc, LOG4JL_LOG_EVENT(logger, fqmn, marker, level, msg)) #TODO: properties
end

show(io::IO, lc::LoggerConfig) = print(io, "LoggerConfig(", isempty(lc.name) ? "root" : lc.name, ":", level(lc) , ")")

"Returns all appender references"
references(lc::LoggerConfig) = values(lc.appenders)

"Adds an appender reference to configuration"
function reference!(lc::LoggerConfig, apndr::Appender, lvl::LEVEL=LEVEL(), flt::FILTER=FILTER())
    apn = name(apndr)
    lvl = get(lvl, Level.ALL)
    apndref = Appenders.Reference(apndr, level=lvl, filter=flt)
    lc.appenders[apn] = apndref
    return apndref
end

"Return parent logger configuration"
parent(lc::LoggerConfig) = lc.parent

"Set parent logger configuration"
parent!(lc::LoggerConfig, parent::Nullable{LoggerConfig}) = (lc.parent = parent)
parent!(lc::LoggerConfig, parent::LoggerConfig) = parent!(lc, Nullable(parent))
