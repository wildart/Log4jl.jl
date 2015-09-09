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
log(lgr::Logger, fqmn, level, marker, msg::MESSAGE) =
    log(lgr.config, lgr.name, fqmn, level, marker, get(msg, Messages.SimpleMessage("")))

function log(lgr::Logger, fqmn, level, marker, msg, params...)
    if isenabled(lgr.config, level, marker, msg, params...)
        log(lgr, fqmn, level, marker, call(msgen(lgr), msg, params...) |> MESSAGE)
    end
end

function show(io::IO, lgr::Logger)
    print(io, lgr.name, ":", level(lgr.config))
end


# function Info(msg...)
#     mod = current_module()
#     log = isconst(m, :logger) && isa(eval(:($m.logger)), Logger) ? eval(:($m.logger)) : ROOT
#     Info(log, msg...)
# end


# for (fn,lvl,clr) in ((:Debug,    DEBUG,    :cyan),
#                      (:Info,     INFO,     :blue),
#                      (:Warn,     WARNING,  :magenta),
#                      (:Error,      ERROR,    :red),
#                      (:Critical, CRITICAL, :red))
# end


