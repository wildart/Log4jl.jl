""" Abstract event filtering """
abstract Filter <: LifeCycle.Object

typealias FILTER Nullable{Filter}

module FilterResult
    @enum ResultType ACCEPT NEUTRAL DENY
end

"""Determines if the event should be filtered.
Returns `true` if the event should be filtered, `false` otherwise.
"""
isfiltered(flt::FILTER, evnt::Event) = !isnull(flt) && filter(get(flt), evnt) == FilterResult.DENY

"Context `Filter` method. The default returns NEUTRAL."
filter{E <: Event}(flt::Filter, evnt::E) = FilterResult.NEUTRAL

"Appender `Filter` method. The default returns NEUTRAL."
filter(flt::Filter, level::Level.EventLevel, marker::MARKER, msg) = FilterResult.NEUTRAL

include("filters/marker.jl")
include("filters/threshold.jl")
