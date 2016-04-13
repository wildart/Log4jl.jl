"""
Console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
type Console <: Appender
    name::AbstractString
    layout::LAYOUT
    state::LifeCycle.State

    target::IO
end
function Console(config::Dict{Symbol,Any})
    io = get(config, :target, :STDERR) 
    nm = get(config, :name, "STDERR")
    lyt= get(config, :layout, LAYOUT())
    Console(nm, lyt, LifeCycle.INITIALIZED, io == :STDOUT ? STDOUT : STDERR)
end
Console(;kwargs...) = Console(Dict{Symbol,Any}(kwargs))
show(io::IO, apnd::Console) = print(io, "Console($(apnd.name))")

name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.target, serialize(apnd.layout, evnt))
end
