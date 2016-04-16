module TestFilters

using ..Fixtures
using Log4jl
import Log4jl: FILTER, filter, isfiltered, MarkerFilter, ThresholdFilter
using FactCheck

evnt = Fixtures.TestEvent() # Level = INFO

facts("Filters") do
    context("can filter on event marker") do
        flt = MarkerFilter(Fixtures.TESTMARKER)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> Log4jl.NEUTRAL
        flt = MarkerFilter(Fixtures.TESTMARKER, Log4jl.DENY, Log4jl.ACCEPT)
        @fact isfiltered(FILTER(flt), evnt) --> true
        @fact filter(flt, evnt) --> Log4jl.DENY
    end

    context("can filter on event level") do
        flt = ThresholdFilter() # Level = ERROR
        @fact isfiltered(FILTER(flt), evnt) --> true
        @fact filter(flt, evnt) --> Log4jl.DENY
        flt = ThresholdFilter(Log4jl.Level.DEBUG)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> Log4jl.NEUTRAL
        flt = ThresholdFilter(Log4jl.Level.WARN, Log4jl.ACCEPT, Log4jl.NEUTRAL)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> Log4jl.NEUTRAL
    end
end

end
