"""Console appender
"""
immutable Console <: Appender
    name::String
    layout::Nullable{Layout}
    io::IO
end
Console() = Console("", Nullable{Layout}(), STDERR)
Console(name::String) = Console(name, Nullable{Layout}(), STDERR)
function Console(config::Dict{Symbol,Any})
    io = get(config, :io, STDERR)
    nm = get(config, :name, "")
    lyt = get(config, :layout, Nullable{Layout}())
    Console(nm, lyt, io)
end
name(apnd::Console) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::Console) = isnull(apnd.layout) ? string(typeof(apnd)) : get(apnd.layout)
