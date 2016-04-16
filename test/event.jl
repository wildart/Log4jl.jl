module TestEvent

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: Log4jlEvent, Level, MARKER, LEVEL

facts("Events") do
    context("are created from messages") do
        evnt = Log4jlEvent()
        @fact level(evnt) --> Level.OFF
        @fact marker(evnt) --> isnull

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, Fixtures.TESTMARKER, Fixtures.TESTLEVEL, Fixtures.TESTMSG)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact get(marker(evnt)) --> Fixtures.TESTMARKER

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, MARKER(Fixtures.TESTMARKER), Fixtures.TESTLEVEL, Fixtures.TESTMSG)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact get(marker(evnt)) --> Fixtures.TESTMARKER

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, MARKER(Fixtures.TESTMARKER), LEVEL(Fixtures.TESTLEVEL), Fixtures.TESTMSG)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact get(marker(evnt)) --> Fixtures.TESTMARKER
    end
end

end
