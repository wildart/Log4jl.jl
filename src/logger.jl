"Logger wrapper for `LoggerConfig`"
type Logger
    name::AbstractString
    message::FACTORY
    config::LoggerConfig
end

typealias LOGGERS Dict{AbstractString, Logger}

"Returns a function that generates messages"
msgen(lgr::Logger) = get(lgr.message, LOG4JL_DEFAULT_MESSAGE)

"Logs a message"
log(lgr::Logger, fqmn, level, marker, msg::Message) =
    log(lgr.config, lgr.name, fqmn, level, marker, msg)

function log(lgr::Logger, fqmn, level, marker, msg, params...)
    if isenabled(lgr.config, level, marker, msg, params...)
        log(lgr, fqmn, level, marker, call(msgen(lgr), msg, params...))
    end
    return
end

function show(io::IO, lgr::Logger)
    print(io, lgr.name, ":", level(lgr.config))
end

