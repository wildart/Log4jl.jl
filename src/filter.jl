""" Abstract event filtering """
abstract Filter <: LifeCycle.Object

typealias FILTER Nullable{Filter}

@enum FilterResult ACCEPT NEUTRAL DENY

"""Determines if the event should be filtered.
Returns `true` if the event should be filtered, `false` otherwise.
"""
isfiltered(flt::FILTER, evnt::Event) = !isnull(flt) && filter(get(flt), evnt) == DENY

"Filter an event. Returns `FilterResult` value."
filter{E <: Event}(flt::Filter, evnt::E) = throw(AssertionError("Function 'filter' is not implemented for type $(typeof(flt))"))

include("filters/marker.jl")
include("filters/threshold.jl")
