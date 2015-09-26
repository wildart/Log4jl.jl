"""
Colored console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
type ColorConsole <: Appender
    name::AbstractString
    layout::LAYOUT
    state::LifeCycle.State

    io::IO
end
function ColorConsole(name::AbstractString, lyt::LAYOUT=LAYOUT(), io::AbstractString="STDOUT")
    ColorConsole(name, lyt, LifeCycle.INITIALIZED, io == "STDOUT" ? STDOUT : STDERR)
end
function ColorConsole(config::Dict)
    io = get(config, "io", "STDOUT")
    nm = get(config, "name", "STDOUT")
    lyt= get(config, :layout, nothing)
    ColorConsole(nm, LAYOUT(lyt), io)
end
ColorConsole() = ColorConsole("STDOUT:Colored")

const LevelColors = Dict(
    Level.ALL   => "\e[0m",
    Level.TRACE => "\e[36;1m",
    Level.DEBUG => "\e[32;1m",
    Level.INFO  => "\e[34;1m",
    Level.WARN  => "\e[93;1m",
    Level.ERROR => "\e[31;1m",
    Level.FATAL => "\e[41;1m",
    Level.OFF   => "\e[8m"
)

name(apnd::ColorConsole) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::ColorConsole) = apnd.layout

function append!(apnd::ColorConsole, evnt::Event)
    isnull(apnd.layout) && return
    col = get(LevelColors, level(evnt), "\e[39;1m")
    write(apnd.io, col)
    write(apnd.io, serialize(apnd.layout, evnt))
    write(apnd.io, "\e[0m")
end
