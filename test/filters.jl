module TestFilters

using ..Fixtures
using Log4jl
import Log4jl: FILTER, filter, isfiltered, MarkerFilter, ThresholdFilter, FilterResult
using FactCheck

evnt = Fixtures.TestEvent() # Level = INFO

facts("Filters") do
    context("can filter on event marker") do
        flt = MarkerFilter(Fixtures.TESTMARKER)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> FilterResult.NEUTRAL
        flt = MarkerFilter(Fixtures.TESTMARKER, FilterResult.DENY, FilterResult.ACCEPT)
        @fact isfiltered(FILTER(flt), evnt) --> true
        @fact filter(flt, evnt) --> FilterResult.DENY
    end

    context("can filter on event level") do
        flt = ThresholdFilter() # Level = ERROR
        @fact isfiltered(FILTER(flt), evnt) --> true
        @fact filter(flt, evnt) --> FilterResult.DENY
        flt = ThresholdFilter(Log4jl.Level.DEBUG)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> FilterResult.NEUTRAL
        flt = ThresholdFilter(Log4jl.Level.WARN, FilterResult.ACCEPT, FilterResult.NEUTRAL)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> FilterResult.NEUTRAL
    end
end

end
