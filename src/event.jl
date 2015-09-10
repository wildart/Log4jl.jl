type Log4jlEvent <: Event
    logger::AbstractString
    fqmn::AbstractString
    marker::MARKER
    level::LEVEL
    message::Message
    timestamp::Float64
end


function Log4jlEvent(logger::AbstractString, fqmn::AbstractString, marker::Symbol, level::Level.EventLevel, msg::Message)
    return Log4jlEvent(logger, fqmn, MARKER(marker), LEVEL(level), msg, time())
end
function Log4jlEvent(logger::AbstractString, fqmn::AbstractString, marker::MARKER, level::Level.EventLevel, msg::Message)
    return Log4jlEvent(logger, fqmn, marker, LEVEL(level), msg, time())
end
function Log4jlEvent(logger::AbstractString, fqmn::AbstractString, marker::MARKER, level::LEVEL, msg::Message)
    return Log4jlEvent(logger, fqmn, marker, level, msg, time())
end
Log4jlEvent(timestamp::Float64) = Log4jlEvent("", "", MARKER(), LEVEL(), SimpeMessage(""), timestamp)
Log4jlEvent() = Log4jlEvent(time())

function show(io::IO, evnt::Log4jlEvent)
    print(io, "Log4jlEvent(Logger=", isempty(evnt.logger) ? "root" : evnt.logger)
    !isnull(evnt.level) && print(io, ", Level=", get(evnt.level))
    !isnull(evnt.message) && print(io, ", Message=", formatted(get(evnt.message)))
    print(io, ")")
end
