""" Basic format layout

Formats events as: <timestamp> - <level> - <message><new_line>
"""
type BasicLayout <: StringLayout
    dformat::Dates.DateFormat
    function BasicLayout(dformat::Dates.DateFormat=Dates.DateFormat("HH:MM:SS.sss"))
        return new(dformat)
    end
end

header(lyt::BasicLayout) = UInt8[]

footer(lyt::BasicLayout) = UInt8[]

function serialize(lyt::BasicLayout, evnt::Event)
    iob = IOBuffer()
    write(iob, "$(Dates.format(timestamp(evnt) |> Dates.unix2datetime, lyt.dformat)) - ")
    write(iob, "$(get(level(evnt))) - ")
    write(iob, evnt |> message |> formatted)
    write(iob, LOG4JL_LINE_SEPARATOR)
    return takebuf_array(iob)
end