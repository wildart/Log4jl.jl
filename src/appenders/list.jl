""" List appender: holds events, messages & data in memory

    This appender is primarily used for testing. Use in a real environment
    is discouraged as the it could eventually grow out of memory.
"""
immutable List <: Appender
    name::AbstractString
    layout::LAYOUT

    events::Vector{Event}
    messages::Vector{Message}
    data::Vector{UInt8}

    raw::Bool
    newLine::Bool

    List(name::AbstractString) = new(name, LAYOUT(), Event[], Message[], UInt8[], false, false)
    function List(name::AbstractString, layout::LAYOUT; raw=false, newline=false)
        apndr = new(name, layout, Event[], Message[], UInt8[], raw, newline)
        if !isnull(apndr.layout)
            hdr = header(layout)
            if length(hdr) > 0
                write(apndr, hdr)
            end
        end
        apndr
    end
end
function List(config::Dict)
    nm = get(config, "name", "List")
    lyt= get(config, :layout, nothing)
    raw= get(config, "raw", false)
    nl = get(config, "newline", false)
    List(nm, LAYOUT(lyt), raw=raw, newline=nl)
end

name(apnd::List) = isempty(apnd.name) ? string(typeof(apnd)) : apnd.name
layout(apnd::List) = apnd.layout

function append!(apnd::List, evnt::Event)
    if isnull(apnd.layout)
        push!(apnd.events, evnt)
    else
        write(serialize(apnd.layout, evnt))
    end
end

function write(apnd::List, data::Vector{UInt8})
    if apnd.raw
        push!(apnd.data, data)
    else
        msg = bytestring(data)
        if apnd.newline
            for part in split(msg,['\n','\r'],keep=false)
                push!(apnd.messages, part)
            end
        else
            push!(apnd.messages, msg)
        end
    end
end

function empty!(apnd::List)
    empty!(apnd.events)
    empty!(apnd.messages)
    empty!(apnd.data)
end