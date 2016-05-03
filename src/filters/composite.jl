"""Composes and invokes one or more filters.
"""
type CompositeFilter <: Filter
    filters::Vector{Filter}
    state::LifeCycle.State
    CompositeFilter(filters::Vector{Filter}) = new(filters, LifeCycle.INITIALIZED)
end

"Make the filter available for use."
function start(flt::CompositeFilter)
    state!(flt, LifeCycle.STARTING)
    for f in flt.filters
        start(f)
    end
    state!(flt, LifeCycle.STARTED)
end

"Disable the filter."
function stop(flt::CompositeFilter)
    state!(flt, LifeCycle.STOPPING)
    for f in flt.filters
        stop(f)
    end
    state!(flt, LifeCycle.STOPPED)
end

function filter{E <: Event}(flt::CompositeFilter, evnt::E)
    result = FilterResult.NEUTRAL
    for f in flt.filters
        result = filter(f, evnt)
        (result == FilterResult.ACCEPT || result == FilterResult.DENY) && return result
    end
    return result
end

function filter(flt::CompositeFilter, level::Level.EventLevel, marker::MARKER, msg)
    result = FilterResult.NEUTRAL
    for f in flt.filters
        result = filter(f, level, marker, msg)
        (result == FilterResult.ACCEPT || result == FilterResult.DENY) && return result
    end
    return result
end