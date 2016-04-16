"""The `MarkerFilter` compares the configured marker value against the marker that is included in the `Event`.
A match occurs when the marker matches the Event's marker.

Default values: `match` is `NEUTRAL`, `mismatch` is `DENY`.
"""
type MarkerFilter <: Filter
    marker::Symbol
    match::FilterResult
    mismatch::FilterResult
    state::LifeCycle.State
    MarkerFilter(marker::Symbol, match::FilterResult, mismatch::FilterResult) = new(marker, match, mismatch, LifeCycle.INITIALIZED)
end
MarkerFilter(marker::Symbol) = MarkerFilter(marker, NEUTRAL, DENY)

"Make the filter available for use."
function start(flt::MarkerFilter)
    state!(cfg, LifeCycle.STARTED)
end

"Disable the filter."
function stop(flt::MarkerFilter)
    state!(cfg, LifeCycle.STOPPED)
end

filter{E <: Event}(flt::MarkerFilter, evnt::E) = filter(flt, marker(evnt))
filter(flt::MarkerFilter, mkr::MARKER) = (!isnull(mkr) && get(mkr) == flt.marker) ? flt.match : flt.mismatch
