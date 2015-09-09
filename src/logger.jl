type Logger
    name::String
    level::Level.EventLevel
    appenders::Vector{Appender}

    Logger(
        name::String=string(current_module()),
        level::Level.EventLevel=Level.DEBUG,
        appenders = [Appenders.Console(name)]
    ) = new(name, level, appenders)

end

typealias LOGGERS Dict{AbstractString, Logger}

function Base.show(io::IO, logger::Logger)
    print(io, "Logger(", join([logger.name, ", level=", string(logger.level)], ""), ")")
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


