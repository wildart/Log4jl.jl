module TestConfig

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: Configuration, name, source, logger, loggers, default!, root,
               appender, appenders, appender!, state, configure,
               LoggerConfig, level, level!, isadditive, references, reference!

testapnd = Fixtures.TestAppender()

facts("Configurations") do
    context("should have required methods implemented") do
        cfg = Fixtures.InvalidConfiguration()
        @fact_throws AssertionError name(cfg)
        @fact_throws AssertionError source(cfg)
        @fact_throws AssertionError root(cfg)
        @fact_throws AssertionError logger(cfg, Fixtures.TESTNAME)
        @fact_throws AssertionError loggers(cfg)
        @fact_throws AssertionError appender(cfg, Fixtures.TESTNAME)
        @fact_throws AssertionError appenders(cfg)
        @fact appender!(cfg, Fixtures.TESTNAME, testapnd) --> nothing
    end

    context("there exists empty configuration") do
        cfg = Log4jl.NullConfiguration()
        @fact name(cfg) --> "Null"
        @fact source(cfg) --> isempty
        @fact isa(root(cfg), Log4jl.LoggerConfig) --> true
        @fact logger(cfg, Fixtures.TESTNAME) --> root(cfg)
        @fact loggers(cfg) --> isempty
        @fact appender(cfg, Fixtures.TESTNAME) --> nothing
        @fact appenders(cfg) --> isempty
        @fact appender!(cfg, Fixtures.TESTNAME, testapnd) --> nothing
    end

    context("should be referenced to logger with `LoggerConfig` object") do
        root = LoggerConfig()
        @fact name(root) --> isempty
        @fact level(root) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact level(Nullable(root)) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        level!(root, Fixtures.TESTLEVEL)
        @fact level(root) --> Fixtures.TESTLEVEL
        @fact level(Nullable(root)) --> Fixtures.TESTLEVEL
        @fact root --> isadditive
        context("which references appenders") do
            @fact length(references(root)) --> 0
            reference!(root, testapnd)
            @fact length(references(root)) --> greater_than(0)
        end
    end

    context("there exists default configuration") do
        cfg = Log4jl.DefaultConfiguration()
        @fact name(cfg) --> "Default"
        @fact source(cfg) --> isempty
        @fact isa(root(cfg), Log4jl.LoggerConfig) --> true
        context("with default parameters when not started") do
            @fact logger(cfg, Fixtures.TESTNAME) --> root(cfg)
            @fact loggers(cfg) --> isempty
            @fact appenders(cfg) --> isempty
            @fact state(cfg) --> Log4jl.LifeCycle.INITIALIZED
        end
        context("it should be initialized by `configure`") do
            # No appender and references
            @fact length(appenders(cfg)) --> 0
            @fact length(loggers(cfg)) --> 0
            @fact length(references(root(cfg))) --> 0
            configure(cfg)
            apnds = appenders(cfg) |> values
            @fact length(apnds) --> greater_than(0)
            apnd = appender(cfg, "Default")
            @fact isa(apnd, Log4jl.Appenders.Console) --> true
            apndrefs = references(root(cfg))
            @fact length(apndrefs) --> greater_than(0)
            @fact isa(first(apndrefs), Log4jl.Appenders.Reference) --> true
            @fact first(apnds) --> first(apndrefs).appender

        end
    end
    context("have a root logger which can be setup by calling `default!` function") do
        cfg = Log4jl.DefaultConfiguration()
        @fact length(appenders(cfg)) --> 0
        @fact length(loggers(cfg)) --> 0
        apndref = default!(cfg)
        @fact length(appenders(cfg)) --> greater_than(0)
        @fact isa(apndref, Log4jl.Appenders.Reference) --> true
        @fact appenders(cfg)["Default"] --> apndref.appender
    end
end

end