# Abstract methods

function start(apnd::Appender)
    trace(LOGGER, "Starting $apnd.")
    state!(apnd, LifeCycle.STARTING)
    isnull(layout(apnd)) && error(LOGGER, "No layout set for the appender $apnd.")
    start(filter(apnd))
    state!(apnd, LifeCycle.STARTED)
    trace(LOGGER, "Started $apnd OK.")
end

function stop(apnd::Appender)
    trace(LOGGER, "Stopping $apnd")
    state!(apnd, LifeCycle.STOPPING)
    stop(filter(apnd))
    state!(apnd, LifeCycle.STOPPED)
    trace(LOGGER, "Stopped $apnd OK.")
end


module Appenders

    import ..Log4jl: Appender, layout, name,
                     Event, level,
                     Message, Level,
                     Filter, Filterable, FILTER, isfiltered,
                     Layout, LAYOUT, header, footer, format,
                     LifeCycle, start, stop, state, state!,
                     LOG4JL_LINE_SEPARATOR, LOGGER

    import Base: empty!, write, append!, string, show

    export name, layout, append!, start, stop

    "`Appender` control"
    type Control <: Filterable
        appender::Appender
        level::Level.EventLevel
        filter::FILTER
    end

    "`Appender` reference"
    type Reference
        appender::Appender
        level::Level.EventLevel
        filter::FILTER
    end
    show(io::IO, ref::Reference) = print(io, "Ref[$(name(ref.appender)):$(ref.level)]")

    "Logs event to the referenced appender"
    function append!(ref::Reference, evnt::Event)
        isfiltered(ref.filter, evnt) && return
        !isnull(evnt.level) && ref.level < get(evnt.level) && return

        #TODO: handle recursive calls

        # append event
        append!(ref.appender, evnt)
    end

    include("appenders/list.jl")
    include("appenders/console.jl")
    include("appenders/color_console.jl")
    include("appenders/file.jl")
    #include("appenders/socket.jl")

end
