"""Console appender
"""
immutable Console <: Appender
    name::AbstractString
    layout::LAYOUT
    io::IO
end
Console() = Console("", LAYOUT(), STDERR)
Console(name::String) = Console(name, LAYOUT(), STDERR)
function Console(config::Dict{Symbol,Any})
    io = get(config, :io, STDERR)
    nm = get(config, :name, "")
    lyt= get(config, :layout, nothing)
    Console(nm, LAYOUT(lyt), io)
end
name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = apnd.layout

function append!(apnd::Console, evnt::Event)
    !isnull(apnd.layout) && write(apnd.io, serialize(apnd.layout, evnt))
end
