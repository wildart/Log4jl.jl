module Level
    import ..Log4jl

    bitstype 32 EventLevel
    const levels = Dict{Int32,Symbol}(
        Int32(typemax(Int16)) => :ALL,
        Int32(600) => :TRACE,
        Int32(500) => :DEBUG,
        Int32(400) => :INFO,
        Int32(300) => :WARN,
        Int32(200) => :ERROR,
        Int32(100) => :FATAL,
        Int32(0)   => :OFF
    )
    Base.isless(x::EventLevel, y::EventLevel) = isless(Int32(x), Int32(y))
    Base.convert{T<:Integer}(::Type{T}, x::EventLevel) = convert(T, Intrinsics.box(Int32, x))

    for (v, l) in levels
        eval(:(const $l = Intrinsics.box(EventLevel, $v)))
    end

    function Base.print(io::IO, level::EventLevel)
        vlvl = Int32(level)
        if haskey(levels, vlvl)
            print(io, levels[vlvl])
        end
    end
    Base.show(io::IO,x::EventLevel) = print(io, x, "::EventLevel")

    "Create a custom level and generate convenience functions"
    function add(lvl::Symbol, lvlval::Int32)
        lvlup = symbol(uppercase(string(lvl)))
        lvllw = symbol(lowercase(string(lvl)))
        @assert !isdefined(Level, lvlup) "Level $lvlup is already defined"
        eval(Level, :(const $lvlup = Intrinsics.box(EventLevel, $lvlval)))
        levels[lvlval] = lvlup
        isdefined(Base, lvllw) && eval(Log4jl, :(import Base.$lvllw))
        eval(Log4jl, parse("makemethods(:$lvllw, Level.$lvlup)"))
    end
end
typealias LEVEL Nullable{Level.EventLevel}