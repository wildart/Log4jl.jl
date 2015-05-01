abstract Message
format(message::Message)     = throw(AssertionError("Method 'format' is not implemented"))
message(message::Message)    = throw(AssertionError("Method 'message' is not implemented"))
parameters(message::Message) = throw(AssertionError("Method 'parameters' is not implemented"))

abstract Event

abstract Layout

""" Abstract appender class

It provides basic appender properties:
* name - appender name for reference
* layout - layout object for output modification
"""
abstract Appender
name(apnd::Appender)     = throw(AssertionError("Method 'name' is not implemented"))
layout(apnd::Appender)    = throw(AssertionError("Method 'message' is not implemented"))
