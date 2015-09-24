"""
Console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
immutable Console <: Appender
    name::AbstractString
    layout::LAYOUT
    target::IO
end
function Console(name::AbstractString, lyt::LAYOUT=LAYOUT(), target::AbstractString="STDERR")
    Console(name, lyt, target == "STDOUT" ? STDOUT : STDERR)
end
function Console(config::Dict)
    io = get(config, "target", "STDERR")
    nm = get(config, "name", "STDOUT")
    lyt= get(config, :layout, nothing)
    Console(nm, LAYOUT(lyt), io)
end
Console() = Console("STDOUT")

name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.target, serialize(apnd.layout, evnt))
end
