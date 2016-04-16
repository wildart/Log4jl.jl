"""
Console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
type Console <: Appender
    name::AbstractString
    layout::LAYOUT
    filter::FILTER
    state::LifeCycle.State

    target::IO
end
function Console(config::Dict{Symbol,Any})
    nm = get(config, :name, "STDERR")
    lyt= get(config, :layout, nothing)
    io = get(config, :target, :STDERR)
    flt = get(config, :filter, nothing)
    Console(nm, LAYOUT(lyt), FILTER(flt), LifeCycle.INITIALIZED, io == :STDOUT ? STDOUT : STDERR)
end
Console(;kwargs...) = Console(Dict{Symbol,Any}(kwargs))
show(io::IO, apnd::Console) = print(io, "Console($(apnd.name))")

name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.target, serialize(apnd.layout, evnt))
end
