"""
Colored console appender

It appends log events to `STDOUT` or `STDERR` using a layout specified by the user.
"""
immutable ColorConsole <: Appender
    name::AbstractString
    layout::LAYOUT
    io::IO
end
function ColorConsole(name::String, lyt::LAYOUT=LAYOUT(), io::Symbol=:STDOUT)
    ColorConsole(name, lyt, io == :STDOUT ? STDOUT : STDERR)
end
function ColorConsole(config::Dict)
    io = get(config, :io, :STDOUT)
    nm = get(config, :name, "STDOUT")
    lyt= get(config, :layout, nothing)
    ColorConsole(nm, LAYOUT(lyt), io)
end
ColorConsole() = ColorConsole("STDOUT:Colored")

const LevelColors = Dict(
    Level.ALL   => :normal,
    Level.TRACE => :cyan,
    Level.DEBUG => :green,
    Level.INFO  => :blue,
    Level.WARN  => :yellow,
    Level.ERROR => :red,
    Level.FATAL => :magenta,
    Level.OFF   => :black
)

name(apnd::ColorConsole) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::ColorConsole) = apnd.layout

function append!(apnd::ColorConsole, evnt::Event)
    isnull(apnd.layout) && return
    lvl = level(evnt)
    col = isnull(lvl) ? :normal : get(LevelColors, get(lvl), :white)
    write(apnd.io, Base.text_colors[col])
    write(apnd.io, serialize(apnd.layout, evnt))
end
