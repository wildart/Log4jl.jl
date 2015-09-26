"""
File Appender.
"""
type File <: Appender
    name::AbstractString
    layout::LAYOUT
    state::LifeCycle.State

    filename::AbstractString
    append::Bool
    flush::Bool
    locking::Bool

    target::IO

    File(nm::AbstractString, lyt::LAYOUT) = new(nm, lyt, LifeCycle.INITIALIZED)
end

function File(config::Dict)
    nm = get(config, "name", "FileAppender")
    fn = config["filename"]
    lyt= get(config, :layout, nothing)
    doappend = get(config, "append", true)
    doflush  = get(config,  "flush", true)
    dolock  = get(config,  "locking", false)

    file = File(nm, LAYOUT(lyt))
    file.filename = fn
    file.append = doappend
    file.flush = doflush
    file.locking = dolock

    return file
end

show(io::IO, apnd::File) = print(io, "FileAppender($(apnd.filename), $(apnd.state))")

name(apnd::File) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::File) = apnd.layout

function start(apnd::File)
    invoke(start, Tuple{Appender}, apnd)
    apnd.target = open(apnd.filename, apnd.append ? "a" : "w")
end

function stop(apnd::File)
    invoke(stop, Tuple{Appender}, apnd)
    close(apnd.target)
end

function append!(apnd::File, evnt::Event)
    if !isnull(apnd.layout)
        if apnd.locking
            lock(apnd.target)
            try
                write!(apnd, evnt)
            finally
                unlock(apnd.target)
            end
        else
            write!(apnd, evnt)
        end
    end
end

function write!(apnd::File, evnt::Event)
    write(apnd.target, serialize(apnd.layout, evnt))
    apnd.flush && flush(apnd.target)
end