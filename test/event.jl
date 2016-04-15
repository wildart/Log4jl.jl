module TestEvent

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: Log4jlEvent, Level, Messages

facts("Events") do
    context("are created from messages") do
        msg = Messages.SimpleMessage("")
        evnt = Log4jlEvent()
        @fact level(evnt) --> Level.OFF
        @fact marker(evnt) --> symbol()

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, Fixtures.TESTMARKER, Fixtures.TESTLEVEL, msg)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact marker(evnt) --> Fixtures.TESTMARKER

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, Log4jl.MARKER(Fixtures.TESTMARKER), Fixtures.TESTLEVEL, msg)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact marker(evnt) --> Fixtures.TESTMARKER

        evnt = Log4jlEvent(Fixtures.TESTNAME, Fixtures.TESTNAME, Log4jl.MARKER(Fixtures.TESTMARKER), Log4jl.LEVEL(Fixtures.TESTLEVEL), msg)
        @fact level(evnt) --> Fixtures.TESTLEVEL
        @fact marker(evnt) --> Fixtures.TESTMARKER
    end
end

end
