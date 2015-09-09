""" List appender: holds events, messages & data in memory

    This appender is primarily used for testing. Use in a real environment
    is discouraged as the it could eventually grow out of memory.
"""
immutable List <: Appender
    name::String
    layout::Nullable{Layout}

    events::Array{Event,1}
    messages::Array{String,1}
    data::Array{Array{UInt8,1},1}

    raw::Bool
    newLine::Bool

    List(name::String) = new(name, Nullable{Layout}(), Event[], Message[], UInt8[], false, false)
    function List(name::String, layout::Layout; raw=false, newLine=false)
        apndr = new(name, layout, Event[], Message[], UInt8[], raw, newLine)
        if !isnull(apndr.layout)
            hdr = header(layout)
            if length(hdr) > 0
                write(apndr, hdr)
            end
        end
        apndr
    end
end

function append!(apnd::List, evnt::Event)
    if isnull(apnd.layout)
        push!(apnd.events, evnt)
    else
        write(format(apnd.layout, evnt))
    end
end

function write(apnd::List, data::Array{UInt8,1})
    if apnd.raw
        push!(apnd.data, data)
    else
        msg = bytestring(data)
        if apnd.newLine
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
    empty!(apnd.messages)
end