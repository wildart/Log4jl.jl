type LogEvent <: Event
    level::Level.EventLevel
    loggerName::String
    message::Message
    timestame::UInt64

    LogEvent(level::Level.EventLevel, loggerName::String, message::Message)=
        new(level, loggerName, message, time_ns())
end
