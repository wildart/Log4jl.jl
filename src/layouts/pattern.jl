# Patterns

const OLD_CONVERSION_PATTERN     = "%d{%d-%b %H:%M:%S}:%p:%t:%m%n"
const BASIC_CONVERSION_PATTERN   = "%r %p %c: %m%n"
const DEFAULT_CONVERSION_PATTERN = "%m%n"
const SIMPLE_CONVERSION_PATTERN  = "%p - %m%n"
const TTCC_CONVERSION_PATTERN    = "%r [%t] %-5p %c - %m%n"

""" Pattern format layout

A flexible layout configurable with pattern string. The conversion pattern is closely related to the conversion pattern of the `printf` function in C. A conversion pattern is composed of literal text and format control expressions called *conversion patterns*.

Conversion Pattern |Description
:------------------|:------------
c{precision}|Outputs the name of the logger that published the logging event.
C{precision}|Outputs the fully qualified module name of the caller issuing the
            |logging request. This conversion specifier can be optionally
            |followed by *precision specifier*, that follows the same rules
            |as the logger name converter.
d{pattern}  |Outputs the date of the logging event. The date conversion specifier
            |may be followed by a set of braces containing a date and time
            |pattern string in `strftime` format.
D{pattern}  |Outputs the date of the logging event. The date conversion specifier
            |may be followed by a set of braces containing a date and time
            |pattern string in `Dates.DateFormat` format.
F           |Outputs the file name where the logging request was issued.
K{key}      |Outputs the entries in a `MapMessage`, if one is present in the event.
            |The **K** conversion character can be followed by the key for the map
            |placed between braces, as in **%K{clientNumber}** where `clientNumber`
            |is the key.
l           |Outputs location information of the caller which generated the logging event.
L           |Outputs the line number from where the logging request was issued.
m           |Outputs the application supplied message associated with the logging event.
M           |Outputs the method name where the logging request was issued.
n           |Outputs the platform dependent line separator character or characters.
p           |Outputs the level of the logging event.
r           |Outputs the number of milliseconds elapsed since logger was configured
            |until the creation of the logging event.
t           |Outputs the process identifier that generated the logging event.
u{type}     |Includes either a random or a time-based UUID. `type` parameter specifies
            |type of the created UUID as string: `TIME` for type 1 and `RANDOM` for type 4.
%           |The sequence **%%** outputs a single percent sign.
"""
type PatternLayout <: StringLayout
    pattern::AbstractString
    header::AbstractString
    footer::AbstractString
    #TODO: RegEx replacement of a procuded message
    # replace::Regex
    # replacement::AbstractString

    strftime_format::AbstractString
    date_format::Dates.DateFormat
    conversion::Regex
    initialized::UInt64
    needbacktrace::Bool
    rng::MersenneTwister
    matched::Base.RegexMatchIterator

    function PatternLayout(pattern::AbstractString=DEFAULT_CONVERSION_PATTERN)
        lyt = new()
        lyt.strftime_format = "%Y-%m-%d %H:%M:%S"
        lyt.date_format = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS.sss")
        lyt.conversion = r"%(-?\d+)?(\.\d+)?(c|C|d|D|F|K|l|L|m|M|n|p|r|t|u|%)?({\d+}|{\D+}|{\w+})?"
        lyt.initialized = time_ns()
        lyt.pattern = pattern
        lyt.rng = MersenneTwister(lyt.initialized)

        # match conversions patterns
        lyt.matched = eachmatch(lyt.conversion, lyt.pattern)

        # Check if backtrace is needed
        lyt.needbacktrace = false
        for m in lyt.matched
            lyt.needbacktrace = m.captures[3][1] in Set(Any['l', 'L', 'M', 'F'])
            lyt.needbacktrace && break
        end

        return lyt
    end
end

function PatternLayout(conf::Dict)
    pattern = get(conf, "pattern", DEFAULT_CONVERSION_PATTERN)
    header = get(conf, "header", "")
    footer = get(conf, "footer", "")
    return PatternLayout(pattern)
end

show(io::IO, lyt::PatternLayout) = print(io, "Pattern($(lyt.pattern))")


# Interface implementation

header(lyt::PatternLayout) = UInt8[]

footer(lyt::PatternLayout) = UInt8[]

serialize(lyt::PatternLayout, evnt::Event) = formatpattern(lyt, evnt)

string(lyt::PatternLayout, evnt::Event) = bytestring(serialize(lyt, evnt))

function formatpattern(lyt::PatternLayout, evnt::Event)
    logstring = UInt8[]

    # Find proper frame
    bt = nothing
    if lyt.needbacktrace
        bts = getbacktrace()
        idx = find(bt->bt.func == :log, bts)
        bt = bts[idx[end]+2]
    end

    # process conversion params
    s = 1
    for m in lyt.matched
        append!(logstring, lyt.pattern[s:(m.offset-1)].data)

        # minimum width
        minw = m.captures[1] != nothing ? try parse(Int, m.captures[1]); catch 0 end : 0
        # maximum width
        maxw = m.captures[2] != nothing ? try parse(Int, m.captures[2][2:end]); catch 0 end : 0
        # formating symbol
        sym = m.captures[3][1]
        # formating symbol parameters
        symparam =  m.captures[4] != nothing ? m.captures[4][2:end-1] : ""

        # process formating symbols
        if sym == 'm' # message
            append!(logstring, (evnt |> message |> formatted).data)
        elseif sym == 'n' # newline
            append!(logstring, LOG4JL_LINE_SEPARATOR)
        elseif sym == '%' # %
            push!(logstring, 0x25)
        else
            output = if sym == 'c' # category name (or logger name)
                evnt |> logger
            elseif sym == 'C' # module
                evnt |> fqmn
            elseif sym == 'd' # date: strftime
                tformat = !isempty(symparam) ? symparam : lyt.strftime_format
                Libc.strftime(tformat,timestamp(evnt))
            elseif sym == 'D' # date: Dates.DateFormat
                tformat = !isempty(symparam) ? Dates.DateFormat(symparam) : lyt.date_format
                Dates.format(timestamp(evnt) |> Dates.unix2datetime, tformat)
            elseif sym == 'F' # file
                bt != nothing ? basename(string(bt.file)) : "NA"
            elseif sym == 'l' # func[file:line]
                bt != nothing ? "$(bt.func)[$(basename(string(bt.file))):$(bt.line)]" : "NA"
            elseif sym == 'L' # line
                bt != nothing ? string(bt.line) : "NA"
            elseif sym == 'M' # function
                bt != nothing ? string(bt.func) : "NA"
            elseif sym == 'p' # level
                rpad(evnt |> level |> string, 5, " ")
            elseif sym == 'r' # time elapsed (milliseconds)
                round(Int, (time_ns()-lyt.initialized)/10e6) |> string
            elseif sym == 't' # thread or PID
                getpid() |> string
            elseif sym == 'u' # UUID
                (symparam == "RANDOM" ? Base.Random.uuid4(lyt.rng) : Base.Random.uuid1(lyt.rng)) |> string
            else
                ""
            end

            # adjust output
            lout = length(output)
            if lout > maxw && maxw != 0
                output = output[(lout-maxw+1):end]
                lout = maxw
            end
            if lout < abs(minw) && minw != 0
                output = minw > 0 ? lpad(output, minw, ' ') : rpad(output, -minw, ' ')
            end
            append!(logstring, output.data)
        end
        s = m.offset+length(m.match)
    end
    if s < length(lyt.pattern)
        append!(logstring, lyt.pattern[s:end].data)
    end
    return logstring
end