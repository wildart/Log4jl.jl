"""This filter returns the `match` result if the level in the `Event` is the same or more specific than the configured level and the onMismatch value otherwise.
For example, if the `ThresholdFilter` is configured with `Level.ERROR` and the `Event` contains `Level.DEBUG` then the `mismatch` value will be returned since `ERROR` events are more specific than `DEBUG`.

Default values: `level` is `ERROR`, `match` is `NEUTRAL`, `mismatch` is `DENY`.
"""
type ThresholdFilter <: Filter
    level::Level.EventLevel
    match::FilterResult.ResultType
    mismatch::FilterResult.ResultType
    state::LifeCycle.State
    ThresholdFilter(lvl::Level.EventLevel, match::FilterResult.ResultType, mismatch::FilterResult.ResultType) =
        new(lvl, match, mismatch, LifeCycle.INITIALIZED)
end
ThresholdFilter(lvl::Level.EventLevel) = ThresholdFilter(lvl, FilterResult.NEUTRAL, FilterResult.DENY)
ThresholdFilter() = ThresholdFilter(Level.ERROR)

"Make the filter available for use."
function start(flt::ThresholdFilter)
    state!(cfg, LifeCycle.STARTED)
end

"Disable the filter."
function stop(flt::ThresholdFilter)
    state!(cfg, LifeCycle.STOPPED)
end

filter{E <: Event}(flt::ThresholdFilter, evnt::E) = filter(flt, level(evnt))
filter(flt::ThresholdFilter, lvl::Level.EventLevel) = flt.level >= lvl ? flt.match : flt.mismatch
