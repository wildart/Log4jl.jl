type Log4jlEvent <: Event
    logger::AbstractString
    fqmn::AbstractString
    marker::MARKER
    level::LEVEL
    message::MESSAGE
    timestamp::UInt64
end

function Log4jlEvent(logger::AbstractString, fqmn::AbstractString, marker::Symbol, level::Level.EventLevel, msg::Message)
    return Log4jlEvent(logger, fqmn, MARKER(marker), LEVEL(level), MESSAGE(msg), time_ns())
end
function Log4jlEvent(logger::AbstractString, fqmn::AbstractString, marker::MARKER, level::LEVEL, msg::MESSAGE)
    return Log4jlEvent(logger, fqmn, marker, level, msg, time_ns())
end
Log4jlEvent(timestamp::UInt64) = Log4jlEvent("",MARKER(),"", LEVEL(), MESSAGE(), timestamp)
Log4jlEvent() = Log4jlEvent(time_ns())

function show(io::IO, evnt::Log4jlEvent)
    print(io, "Log4jlEvent(Logger=", isempty(evnt.logger) ? "root" : evnt.logger)
    !isnull(evnt.level) && print(io, ", Level=", get(evnt.level))
    !isnull(evnt.message) && print(io, ", Message=", formatted(get(evnt.message)))
    print(io, ")")
end
