module TestFilters

using ..Fixtures
using Log4jl
import Log4jl: FILTER, MARKER, filter, isfiltered, MarkerFilter, ThresholdFilter, FilterResult, state, start, stop
using FactCheck

evnt = Fixtures.TestEvent() # Level = INFO

facts("Filters") do
    context("need to implement certain methods") do
        @fact filter(Fixtures.TESTFILTER, evnt) --> FilterResult.NEUTRAL
        @fact filter(Fixtures.TESTFILTER, Fixtures.TESTLEVEL, MARKER(Fixtures.TESTMARKER), Fixtures.TESTMSG) --> FilterResult.NEUTRAL
        @fact isfiltered(FILTER(Fixtures.TESTFILTER), evnt) --> false
    end
    context("can filter on event marker") do
        flt = MarkerFilter(Fixtures.TESTMARKER)
        @fact isfiltered(FILTER(flt), evnt) --> false
        @fact filter(flt, evnt) --> FilterResult.NEUTRAL
        flt = MarkerFilter(Fixtures.TESTMARKER, FilterResult.DENY, FilterResult.ACCEPT)
        @fact isfiltered(FILTER(flt), evnt) --> true
        @fact filter(flt, evnt) --> FilterResult.DENY
        @fact filter(flt, Fixtures.TESTLEVEL, MARKER(Fixtures.TESTMARKER), Fixtures.TESTMSG) --> FilterResult.DENY
        @fact state(flt) --> Log4jl.LifeCycle.INITIALIZED
        start(FILTER(flt))
        @fact state(flt) --> Log4jl.LifeCycle.STARTED
        stop(FILTER(flt))
        @fact state(flt) --> Log4jl.LifeCycle.STOPPED
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
        @fact filter(flt, Fixtures.TESTLEVEL, MARKER(Fixtures.TESTMARKER), Fixtures.TESTMSG) --> FilterResult.NEUTRAL
        @fact state(flt) --> Log4jl.LifeCycle.INITIALIZED
        start(flt)
        @fact state(flt) --> Log4jl.LifeCycle.STARTED
        stop(flt)
        @fact state(flt) --> Log4jl.LifeCycle.STOPPED
    end
end

end
