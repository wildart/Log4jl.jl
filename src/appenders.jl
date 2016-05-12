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
                     Filter, FILTER, filter,
                     Filterable, isfiltered,
                     Layout, LAYOUT, header, footer, format,
                     LifeCycle, start, stop, state, state!,
                     LOG4JL_LINE_SEPARATOR, LOGGER

    import Base: empty!, write, append!, string, show

    export name, layout, append!, start, stop

    type LoggingException <: Exception
        msg::AbstractString
    end

    """`Appender` reference

        Wraps an `Appender` with details an appender implementation shouldn't need to know about.
    """
    type Reference <: Filterable #TODO: Should be either Filterable or LifeCycle.Object
        appender::Appender
        level::Level.EventLevel
        filter::FILTER
        state::LifeCycle.State
        function Reference(apnd::Appender;
                           level::Level.EventLevel=Level.ALL,
                           filter::FILTER=FILTER())
            apndref = new(apnd, level, filter, LifeCycle.INITIALIZED)
            start(apndref)
            return apndref
        end
    end
    show(io::IO, ref::Reference) = print(io, "Ref[$(name(ref.appender)):$(ref.level)]")

    function start(ref::Reference)
        state!(ref, LifeCycle.STARTING)
        start(filter(ref))
        state!(ref, LifeCycle.STARTED)
    end

    function stop(ref::Reference)
        state!(ref, LifeCycle.STOPPING)
        stop(filter(ref))
        ref.filter = FILTER()
        state!(apndctrl, LifeCycle.STOPPED)
    end

    "Logs event to the referenced appender"
    function append!(ref::Reference, evnt::Event)
        isfiltered(ref.filter, evnt) && return

        !isnull(evnt.level) && ref.level < get(evnt.level) && return

        #TODO: handle recursive calls

        if state(ref.appender) != LifeCycle.STARTED
            errmsg = "Attempted to append to non-started appender $(name(ref.appender))"
            error(LOGGER, errmsg)
            !ignoreexceptions(ref.appender) && throw(LoggingException(errmsg))
        end

        isa(ref.appender, Filterable) && isfiltered(ref.appender, evnt) && return

        # append event
        try
            append!(ref.appender, evnt)
        catch ex
            error(LOGGER, "An exception occurred processing appender $(name(ref.appender))")
            if !ignoreexceptions(ref.appender)
                if ex <: ErrorException
                    rethrow(ex)
                else
                    throw(LoggingException(string(ex)))
                end
            end
        end
    end

    include("appenders/list.jl")
    include("appenders/console.jl")
    include("appenders/color_console.jl")
    include("appenders/file.jl")
    #include("appenders/socket.jl")

end

typealias AppenderReferences Dict{AbstractString, Appenders.Reference}
