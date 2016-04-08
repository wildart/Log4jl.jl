"Main logging function"
function log(lgr::AbstractLogger, fqmn, level, marker, msg, params...)
    if isenabled(lgr, level, marker, msg, params...)
        log(lgr, fqmn, level, marker, call(message(lgr), msg, params...))
    end
    return
end


"Logger wrapper for `LoggerConfig`"
type Logger <: AbstractLogger
    name::AbstractString
    message::DataType
    config::LoggerConfig
end
show(io::IO, lgr::Logger) = print(io, name(lgr), ":", level(lgr))
name(lgr::Logger) = lgr.name
message(lgr::Logger) = lgr.message
level(lgr::Logger) = level(lgr.config)
level!(lgr::Logger, lvl::Level.EventLevel) = level!(lgr.config, lvl)

"Logs a message"
log(lgr::Logger, fqmn, level, marker, msg::Message) =
    log(lgr.config, name(lgr), fqmn, level, marker, msg)

"Check if message is valid for logging"
isenabled(lgr::Logger, lvl, mkr, msg, params...) = isenabled(lgr.config, lvl, mkr, msg, params...)


"Simple IO logger"
type SimpleLogger <: AbstractLogger
    name::AbstractString
    message::DataType
    level::Level.EventLevel

    showdatetime::Bool
    showname::Bool
    dateformat::Dates.DateFormat
    io::IO

    function SimpleLogger(nm::AbstractString, msg::DataType, lvl::Level.EventLevel)
        return new(nm, msg, lvl, true, true, Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sss"), STDERR)
    end
end
show(io::IO, lgr::SimpleLogger) = print(io, name(lgr), ":", lgr |> level |> string)
name(lgr::SimpleLogger) = lgr.name
message(lgr::SimpleLogger) = lgr.message
level(lgr::SimpleLogger) = lgr.level
level!(lgr::SimpleLogger, lvl::Level.EventLevel) = lgr.level = lvl

isenabled(lgr::SimpleLogger, lvl, mkr, msg, params...) = level(lgr) <= lvl

function log(lgr::SimpleLogger, fqmn, lvl, mkr, msg::Message)
    lgr.showdatetime && print(lgr.io, Dates.format(Dates.unix2datetime(time()), lgr.dateformat), " ")
    print(lgr.io, string(lvl), " ")
    lgr.showname && print(lgr.io, name(lgr), " ")
    !isnull(mkr) && print(lgr.io, "[", get(mkr), "] ")
    println(lgr.io, msg |> formatted, " ")
end
