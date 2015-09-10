module Layouts

    import ..Log4jl: Layout, header, footer,
                     StringLayout,
                     Event, message, level, timestamp,
                     Message, formatted,
                     LOG4JL_LINE_SEPARATOR

    import Base: serialize

    export name, layer

    include("layouts/basic.jl")


end
