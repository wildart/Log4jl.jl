module Log4jl

export Logger, Level,
       name, layout

module Level
    @enum EventLevel ALL=0 TRACE=100 DEBUG=200 INFO=300 WARN=400 ERROR=500 FATAL=600 OFF=1000
end

include("types.jl")
include("message.jl")
include("event.jl")
include("appender.jl")
include("logger.jl")

const root = Logger("", Level.DEBUG, STDERR)


end # module
