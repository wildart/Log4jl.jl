module Appenders

    using Log4jl: Appender, Layout
    import Log4jl: name, layout

    export name, layer

    """ Console appender class
    """
    immutable Console <: Appender
        io::IO
        name::Nullable{String}
        layer::Nullable{Layout}
        Console() = new(STDERR, Nullable{String}(), Nullable{Layout}())
        function Console(config::Dict{Symbol,Any})
            io = get(config, :io, STDERR)
            name = get(config, :name, Nullable{String}())
            layer = get(config, :layer, Nullable{Layout}())
            new(io, name, layer)
        end
    end
    name(apnd::Console) = isnull(apnd.name) ? string(typeof(apnd)) : get(apnd.name)
    layer(apnd::Console) = isnull(apnd.layer) ? string(typeof(apnd)) : get(apnd.layer)

    immutable File <: Appender
    end

    immutable Socket <: Appender
    #Socket name="Graylog" protocol="udp" host="graylog.domain.com" port="12201"
    end

    immutable List <: Appender
    end
end