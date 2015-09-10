module Appenders

    import ..Log4jl: Appender, layout, name,
                             Event, Message, Level,
                             Filter, FILTER,
                             Layout, LAYOUT, header, footer, format

    import Base: empty!, write, append!

    export name, layout, append!

    "An `Appender` reference"
    type Reference
        appender::Appender
        level::Level.EventLevel
        filter::FILTER
    end

    "Logs event to the referenced appender"
    function append!(ref::Reference, evnt::Event)
        if !isnull(ref.filter)
            #TODO: filter event
        end

        !isnull(evnt.level) && get(evnt.level) < ref.level && return

        # handle recursive calls

        # append event
        append!(ref.appender, evnt)

    end

    include("appenders/list.jl")
    include("appenders/console.jl")
    #include("appenders/file.jl")
    #include("appenders/socket.jl")

end
