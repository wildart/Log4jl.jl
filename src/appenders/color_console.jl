"""
Colored console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
type ColorConsole <: Appender
    name::AbstractString
    layout::LAYOUT
    filter::FILTER
    state::LifeCycle.State

    io::IO
end
function ColorConsole(config::Dict{AbstractString,Any})
    nm = get(config,  "name", "STDOUT")
    lyt= get(config,  "layout", nothing)
    io = get(config,  "target", :STDOUT)
    flt = get(config, "filter", nothing)
    ColorConsole(nm, LAYOUT(lyt), FILTER(flt), LifeCycle.INITIALIZED, io == :STDOUT ? STDOUT : STDERR)
end
ColorConsole(;kwargs...) = map(e->(string(e[1]),e[2]), kwargs) |> Dict{AbstractString,Any} |> ColorConsole
show(io::IO, apnd::ColorConsole) = print(io, "ColorConsole($(apnd.name))")

const ColorReset = UInt8[0x1b, 0x5b, 0x30, 0x6d]
const LevelColors = Dict(
    Level.ALL   => "\e[0m",
    Level.TRACE => "\e[33m",
    Level.DEBUG => "\e[32;1m",
    Level.INFO  => "\e[36;1m",
    Level.WARN  => "\e[33;1m",
    Level.ERROR => "\e[31;1m",
    Level.FATAL => "\e[31m",
    Level.OFF   => "\e[8m"
)
name(apnd::ColorConsole) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::ColorConsole) = apnd.layout

function append!(apnd::ColorConsole, evnt::Event)
    isnull(apnd.layout) && return
    col = get(LevelColors, level(evnt), "\e[39;1m")
    write(apnd.io, col)
    write(apnd.io, serialize(apnd.layout, evnt))
    write(apnd.io, ColorReset)
end
