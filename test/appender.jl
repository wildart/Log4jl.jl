module TestAppender

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: name, layout, append!, state

facts("Appenders") do
    context("should have required methods implemented") do
        apnd = Fixtures.InvalidAppender()
        @fact_throws MethodError InvalidAppender(Dict{Symbol,Any}())
        @fact_throws AssertionError name(apnd)
        @fact_throws AssertionError layout(apnd)
        @fact_throws AssertionError state(apnd)
        @fact_throws AssertionError filter(apnd)
        @fact_throws AssertionError append!(apnd, Fixtures.TestEvent())

        testapnd = Fixtures.TestAppender()
        testevent = Fixtures.TestEvent()
        @fact name(testapnd) --> Fixtures.TESTNAME
        @fact layout(testapnd) --> isnull
        @fact filter(testapnd) --> isnull
        @fact append!(testapnd, testevent) --> testevent
        @fact state(testapnd) --> Log4jl.LifeCycle.INITIALIZED
    end
end

end