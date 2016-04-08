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
    return BasicLayout(Dates.DateFormat(sdformat))
end

# Interface implementation

header(lyt::BasicLayout) = UInt8[]

footer(lyt::BasicLayout) = UInt8[]

function string(lyt::BasicLayout, evnt::Event)
    output = Dates.format(timestamp(evnt) |> Dates.unix2datetime, lyt.dformat)
    output *= " - "
    output *= rpad(string(level(evnt)), 5, " ")
    output *= " - "
    output *= fqmn(evnt)
    output *= " - "
    output *= evnt |> message |> formatted
    output *= bytestring(LOG4JL_LINE_SEPARATOR)
    return output
end
serialize(lyt::BasicLayout, evnt::Event) = string(lyt, evnt).data
