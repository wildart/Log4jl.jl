"""
Console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
type Console <: Appender
    name::AbstractString
    layout::LAYOUT
    filter::FILTER
    state::LifeCycle.State

    io::IO
end
function Console(config::Dict{AbstractString,Any})
    nm = get(config,  "name", "STDERR")
    lyt= get(config,  "layout", nothing)
    io = get(config,  "target", :STDERR)
    flt = get(config, "filter", nothing)
    Console(nm, LAYOUT(lyt), FILTER(flt), LifeCycle.INITIALIZED, io == :STDOUT ? STDOUT : STDERR)
end
Console(;kwargs...) = map(e->(string(e[1]),e[2]), kwargs) |> Dict{AbstractString,Any} |> Console
show(io::IO, apnd::Console) = print(io, "Console($(apnd.name))")

name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.io, serialize(apnd.layout, evnt))
end
