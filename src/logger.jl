"Logger wrapper for `LoggerConfig`"
type Logger
    name::AbstractString
    message::FACTORY
    config::LoggerConfig
end

typealias LOGGERS Dict{AbstractString, Logger}

msgen(lgr::Logger) = get(lgr.message, LOG4JL_DEFAULT_MESSAGE)

log(lgr::Logger, fqmn, level, marker, msg::MESSAGE) =
    log(lgr.config, lgr.name, fqmn, level, marker, get(msg, SimpleMessage("")))

log(lgr::Logger, fqmn, level, marker, msg) =
    log(lgr, fqmn, level, marker, call(msgen(lgr), msg) |> MESSAGE)



function show(io::IO, logger::Logger)
    print(io, "(", logger.name, ")")
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


