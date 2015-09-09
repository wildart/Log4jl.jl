module Appenders

    import ..Log4jl: Appender, Layout, Event, Message,
                             name, layout
    import Base: empty!, write

    export name, layout, appender

    include("appenders/list.jl")
    include("appenders/console.jl")
    #include("appenders/file.jl")
    #include("appenders/socket.jl")

end
