"Context `Filter` method. The default returns NEUTRAL."
filter{E <: Event}(flt::Filter, evnt::E) = FilterResult.NEUTRAL

"Appender `Filter` method. The default returns NEUTRAL."
filter(flt::Filter, level::Level.EventLevel, marker::MARKER, msg) = FilterResult.NEUTRAL

start(flt::FILTER) = !isnull(flt) && start(get(flt))
stop(flt::FILTER) = !isnull(flt) && stop(get(flt))

include("filters/marker.jl")
include("filters/threshold.jl")
