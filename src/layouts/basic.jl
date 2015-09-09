""" Basic format layout

Formats events as: <level> - <message><new_line>
"""
type BasicLayout <: StringLayout
    header::String
    BasicLayout(header::String="Header") = new(header)
end

header(lyt::BasicLayout) = append!(lyt.header.data, LOG4JL_LINE_SEPARATOR)

footer(lyt::BasicLayout) = UInt8[]

function serialize(lyt::BasicLayout, evnt::Event)
    iob = IOBuffer()
    write(iob, event |> message |> formatted)
    return takebuf_array(iob)
end

