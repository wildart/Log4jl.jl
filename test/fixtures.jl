module Fixtures

    import Log4jl
    import Log4jl: level, marker, append!

    export IncompleteMessage, InvalidConfiguration,
           TestEvent, level, marker,
           InvalidAppender, TestAppender, append!

    const TESTNAME   = "TEST"
    const TESTLEVEL  = Log4jl.Level.INFO
    const TESTLEVELN  = Log4jl.LEVEL(TESTLEVEL)
    const TESTMARKER = :TESTMARKER

    type IncompleteMessage <: Log4jl.Message
    end
    TESTMSG = Log4jl.Messages.SimpleMessage(Fixtures.TESTNAME)

    type InvalidConfiguration <: Log4jl.Configuration
    end

    type TestEvent <: Log4jl.Event
    end
    level(evnt::TestEvent) = TESTLEVEL
    marker(evnt::TestEvent) = Log4jl.MARKER(TESTMARKER)

    type TestFilter <: Log4jl.Filter
    end
    TESTFILTER = TestFilter()

    type InvalidAppender <: Log4jl.Appender
    end

    type TestAppender <: Log4jl.Appender
        name::AbstractString
        layout::Log4jl.LAYOUT
        filter::Log4jl.FILTER
        state::Log4jl.LifeCycle.State
    end
    TestAppender(cfg::Dict{Symbol, Any}) = TestAppender(TESTNAME, Log4jl.LAYOUT(), Log4jl.FILTER(), Log4jl.LifeCycle.INITIALIZED)
    TestAppender() = TestAppender(Dict{Symbol, Any}())
    append!(apnd::TestAppender, evnt::Log4jl.Event) = evnt

end