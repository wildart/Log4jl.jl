module Layouts

    import ..Log4jl: Layout, header, footer,
                     StringLayout,
                     Event, message, level, timestamp, fqmn, logger, marker,
                     Message, formatted,
                     LOG4JL_LINE_SEPARATOR, getbacktrace

    import Base: serialize, string

    include("layouts/basic.jl")
    include("layouts/pattern.jl")
    include("layouts/serialized.jl")

end
