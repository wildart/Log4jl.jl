"""The `MarkerFilter` compares the configured marker value against the marker that is included in the `Event`.
A match occurs when the marker matches the Event's marker.

Default values: `match` is `NEUTRAL`, `mismatch` is `DENY`.
"""
type MarkerFilter <: Filter
    marker::Symbol
    match::FilterResult.ResultType
    mismatch::FilterResult.ResultType
    state::LifeCycle.State
    MarkerFilter(marker::Symbol, match::FilterResult.ResultType, mismatch::FilterResult.ResultType) =
        new(marker, match, mismatch, LifeCycle.INITIALIZED)
end
MarkerFilter(marker::Symbol) = MarkerFilter(marker, FilterResult.NEUTRAL, FilterResult.DENY)

function MarkerFilter(config::Dict{AbstractString,Any})
    if !haskey(config, "marker")
        error(LOGGER, "No marker found. `marker` parameter is required for `MarkerFilter`")
        return nothing
    end
    fmarker = symbol(config["marker"])
    rmatch = if haskey(config, "match")
        evaltype(config["match"], "FilterResult")
    else
        FilterResult.NEUTRAL
    end
    rmismatch = if haskey(config, "mismatch")
        evaltype(config["mismatch"], "FilterResult")
    else
        FilterResult.DENY
    end
    MarkerFilter(fmarker, rmatch, rmismatch)
end
MarkerFilter(;kwargs...) = map(e->(string(e[1]),e[2]), kwargs) |> Dict{AbstractString,Any} |> MarkerFilter

"Make the filter available for use."
function start(flt::MarkerFilter)
    state!(flt, LifeCycle.STARTED)
end

"Disable the filter."
function stop(flt::MarkerFilter)
    state!(flt, LifeCycle.STOPPED)
end

filter{E <: Event}(flt::MarkerFilter, evnt::E) = filter(flt, marker(evnt))
filter(flt::MarkerFilter, level::Level.EventLevel, marker::MARKER, msg) = filter(flt, marker)
filter(flt::MarkerFilter, mkr::MARKER) = (!isnull(mkr) && get(mkr) == flt.marker) ? flt.match : flt.mismatch
