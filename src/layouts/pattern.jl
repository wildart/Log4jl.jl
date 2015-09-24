# Patterns

const OLD_CONVERSION_PATTERN     = "%d{%d-%b %H:%M:%S}:%p:%t:%m%n"
const BASIC_CONVERSION_PATTERN   = "%r %p %c: %m%n"
const DEFAULT_CONVERSION_PATTERN = "%m%n"
const SIMPLE_CONVERSION_PATTERN  = "%p - %m%n"
const TTCC_CONVERSION_PATTERN    = "%r [%t] %-5p %c - %m%n"

""" Pattern format layout

A flexible layout configurable with pattern string. The conversion pattern is closely related to the conversion pattern of the `printf` function in C. A conversion pattern is composed of literal text and format control expressions called *conversion specifiers*.
"""
type PatternLayout <: StringLayout
    pattern::AbstractString
    header::AbstractString
    footer::AbstractString
    #TODO: RegEx replacement of a procuded message
    # replace::Regex
    # replacement::AbstractString

    dformat::AbstractString
    conversion::Regex
    initialized::UInt64

    function PatternLayout(pattern::AbstractString=DEFAULT_CONVERSION_PATTERN)
        lyt = new()
        lyt.dformat = "%Y-%m-%d %H:%M:%S"
        lyt.conversion = r"%(-?\d+)?(\.\d+)?(c|C|d|F|K|l|L|m|M|n|p|t|u|%)?({\d+}|{\D+}|{\w+})?"
        lyt.initialized = time_ns()
        lyt.pattern = pattern
        return lyt
    end
end

function PatternLayout(conf::Dict)
    pattern = get(conf, "pattern", DEFAULT_CONVERSION_PATTERN)
    header = get(conf, "header", "")
    footer = get(conf, "footer", "")
    return PatternLayout(pattern)
end


# Interface implementation

header(lyt::PatternLayout) = UInt8[]

footer(lyt::PatternLayout) = UInt8[]

serialize(lyt::PatternLayout, evnt::Event) = formatpattern(lyt, evnt)

string(lyt::PatternLayout, evnt::Event) = bytestring(serialize(lyt, evnt))

function formatpattern(lyt::PatternLayout, evnt::Event)
    logstring = UInt8[]
    matched = eachmatch(lyt.conversion, lyt.pattern) # match conversions params

    # Check if backtrace is needed
    needbacktrace = false
    for m in matched
        needbacktrace = m.captures[3][1] in Set(Any['l', 'L', 'M', 'F'])
        needbacktrace && break
    end

    # Find proper frame
    bt = nothing
    if true #needbacktrace
        bts = getbacktrace()
        idx = find(bt->bt.func == :log, bts)
        bt = bts[idx[end]+2]
    end

    # process conversion params
    s = 1
    for m in matched
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
            elseif sym == 'd' # date
                tformat = !isempty(symparam) ? symparam : lyt.dformat
                Libc.strftime(tformat,timestamp(evnt))
            elseif sym == 'F' # file
                bt != nothing ? basename(string(bt.file)) : "NA"
            elseif sym == 'l' # module(func:line)
                bt != nothing ? "$(bt.mod)($(bt.func):$(bt.line))" : "NA"
            elseif sym == 'L' # line
                bt != nothing ? string(bt.line) : "NA"
            elseif sym == 'M' # function
                bt != nothing ? string(bt.func) : "NA"
            elseif sym == 'p' # level
                evnt |> level |> string
            elseif sym == 'r' # time elapsed (milliseconds)
                round(Int, (time_ns()-lyt.initialized)/10e6) |> string
            elseif sym == 't' # thread or PID
                getpid() |> string
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