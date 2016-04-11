module Fixtures

    import Log4jl
    import Log4jl: level, marker, append!

    export IncompleteMessage, InvalidConfiguration,
           TestEvent, level, marker,
           InvalidAppender, TestAppender, append!

    const TESTNAME   = "TEST"
    const TESTLEVEL  = Log4jl.Level.TRACE
    const TESTMARKER = :TESTMARKER

    type IncompleteMessage <: Log4jl.Message
    end

    type InvalidConfiguration <: Log4jl.Configuration
    end

    type TestEvent <: Log4jl.Event
    end
    level(evnt::TestEvent) = TESTLEVEL
    marker(evnt::TestEvent) = TESTMARKER

    type InvalidAppender <: Log4jl.Appender
    end

    type TestAppender <: Log4jl.Appender
        name::AbstractString
        layout::Log4jl.LAYOUT
        state::Log4jl.LifeCycle.State
    end
    TestAppender(cfg::Dict{Symbol, Any}) = TestAppender(TESTNAME, Log4jl.LAYOUT(), Log4jl.LifeCycle.INITIALIZED)
    TestAppender() = TestAppender(Dict{Symbol, Any}())
    append!(apnd::TestAppender, evnt::Log4jl.Event) = evnt

end