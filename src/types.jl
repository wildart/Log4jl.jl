import Base: append!, serialize

module Level
    @enum EventLevel ALL=0 TRACE=100 DEBUG=200 INFO=300 WARN=400 ERROR=500 FATAL=600 OFF=1000
    #@addlevel(lvl, val) # add custom level
end


""" Abstract log message

Message implementations that can be logged. Messages can act as wrappers
around objects so that user can have control over converting objects to strings
when necessary without requiring complicated formatters and as a way to manipulate
the message based on information available at runtime such as the locale of the system.
"""
abstract Message

""" Returns message format as string. """
format(msg::Message)     = throw(AssertionError("Function 'format' is not implemented"))

""" Returns message formated as string. """
formatted(msg::Message)  = throw(AssertionError("Function 'formatted' is not implemented"))

""" Returns message parameters, if any. """
parameters(msg::Message) = throw(AssertionError("Function 'parameters' is not implemented"))


""" Log event

Provides contextual information about a logged message.
"""
abstract Event

""" Returns the fully qualified module name of the caller of the logging API """
fqmn(evnt::Event) = isdefined(evnt, :fqmn) ? evnt.fqmn : throw(AssertionError("Define field 'fqmn' in type $(typeof(evnt))"))

""" Gets the level. """
level(evnt::Event) = isdefined(evnt, :level) ? evnt.level : throw(AssertionError("Define field 'level' in type $(typeof(evnt))"))

""" Gets the logger name. """
logger(evnt::Event) = isdefined(evnt, :logger) ? evnt.logger : throw(AssertionError("Define field 'logger' in type $(typeof(evnt))"))

""" Gets the Marker associated with the event. """
marker(evnt::Event) = isdefined(evnt, :marker) ? evnt.marker : throw(AssertionError("Define field 'marker' in type $(typeof(evnt))"))

""" Gets the message associated with the event. """
message(evnt::Event) = isdefined(evnt, :message) ? evnt.message : throw(AssertionError("Define field 'message' in type $(typeof(evnt))"))

""" Gets event time in nanoseconds. """
timestamp(evnt::Event) = isdefined(evnt, :timestamp) ? evnt.timestamp : throw(AssertionError("Define field 'timestamp' in type $(typeof(evnt))"))


""" Abstract layout

Lays out a `Event` in different formats.
"""
abstract Layout

""" Returns the header as byte array for the layout format. """
header(lyt::Layout) = throw(AssertionError("Function 'header' is not implemented for type $(typeof(lyt))"))

""" Returns the footer as byte array for the layout format. """
footer(lyt::Layout) = throw(AssertionError("Function 'footer' is not implemented for type $(typeof(lyt))"))

""" Formats the event suitable for display into byte array """
format(lyt::Layout, evnt::Event) = throw(AssertionError("Function 'format' is not implemented for type $(typeof(lyt))"))

""" Formats the event as an Object that can be serialized. """
serialize(lyt::Layout, evnt::Event) = throw(AssertionError("Function 'serialize' is not implemented for type $(typeof(lyt))"))

""" Returns the content type output by this layout """
contenttype(lyt::Layout) = throw(
    AssertionError("""\n
        Every layout should provide a content type.
        Implement function `contenttype` for type $(typeof(lyt))
        that returns a proper content type (e.g. "text/plain")
    """))


""" Abstract type for layouts that result in a String """
abstract StringLayout
contenttype(lyt::StringLayout) = "text/plain"
format(lyt::StringLayout, evnt::Event) = serialize(lyt, event)


""" Abstract appender

Any appender must have two basic fields:
* name::String - appender name for reference
* layout::Nullable{Layout} - layout object for output modification

In addition to basic fields, every appender should have
a method `append!`:
* append!(apnd::Appender, evnt::Event) - appends event
"""
abstract Appender

""" Returns name of the appender """
name(apnd::Appender) = isdefined(apnd, :name) ? apnd.name : throw(AssertionError("Define field 'name' in type $(typeof(apnd))"))

""" Returns layout of the appender """
layout(apnd::Appender) = isdefined(apnd, :layout) ? apnd.layout : throw(AssertionError("Define field 'layout' in type $(typeof(apnd))"))

""" Adds event to the appender """
append!(apnd::Appender, evnt::Event) = throw(AssertionError("Function 'append!' is not implemented for type $(typeof(apnd))"))


type AppenderRef
    ref::AbstractString
    level::Level.EventLevel
    #TODO: filter::Filter
end


# Aliases
typealias MARKER Nullable{Symbol}
typealias MESSAGE Nullable{Message}
typealias LEVEL Nullable{Level.EventLevel}
typealias MSGFACTORY Nullable{Function}
typealias PROPERTIES Dict{AbstractString, AbstractString}
typealias APPENDERS Dict{AbstractString, Appender}
