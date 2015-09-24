""" Basic format layout

Formats events as: <timestamp> - <level> - <FQMN> - <message><new_line>
"""
type BasicLayout <: StringLayout
    dformat::Dates.DateFormat
    function BasicLayout(dformat::Dates.DateFormat=Dates.DateFormat("HH:MM:SS.sss"))
        return new(dformat)
    end
end

function BasicLayout(conf::Dict)
    sdformat = get(conf, "dateFormat", "HH:MM:SS.sss")
    return SerializedLayout(Dates.DateFormat(sdformat))
end

# Interface implementation

header(lyt::BasicLayout) = UInt8[]

footer(lyt::BasicLayout) = UInt8[]

function string(lyt::BasicLayout, evnt::Event)
    output = Dates.format(timestamp(evnt) |> Dates.unix2datetime, lyt.dformat)
    output *= " - "
    output *= string(level(evnt))
    output *= " - "
    output *= fqmn(evnt)
    output *= " - "
    output *= evnt |> message |> formatted
    output *= convert(ASCIIString, LOG4JL_LINE_SEPARATOR)
    return output
end
serialize(lyt::BasicLayout, evnt::Event) = string(lyt, evnt).data

# function serialize(lyt::BasicLayout, evnt::Event)
#     iob = IOBuffer()
#     write(iob, "$(Dates.format(timestamp(evnt) |> Dates.unix2datetime, lyt.dformat)) - ")
#     write(iob, "$(get(level(evnt))) - ")
#     write(iob, evnt |> message |> formatted)
#     write(iob, LOG4JL_LINE_SEPARATOR)
#     return takebuf_array(iob)
# end