"""
Console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
immutable Console <: Appender
    name::AbstractString
    layout::LAYOUT
    io::IO
    #TODO: colors
end
function Console(name::String, lyt::LAYOUT=LAYOUT(), io::Symbol=:STDOUT)
    Console(name, lyt, io == :STDOUT ? STDOUT : STDERR)
end
function Console(config::Dict)
    io = get(config, :io, :STDOUT)
    nm = get(config, :name, "STDOUT")
    lyt= get(config, :layout, nothing)
    Console(nm, LAYOUT(lyt), io)
end
Console() = Console("STDOUT")

name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.io, serialize(apnd.layout, evnt))
end
