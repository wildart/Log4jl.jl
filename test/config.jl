module TestConfig

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: Configuration, name, source, logger, loggers,
               appender, appenders, appender!, state, setup, configure,
               LoggerConfig, level, level!, isadditive, references, reference!

testapnd = Fixtures.TestAppender()

facts("Configurations") do
    context("should have required methods implemented") do
        cfg = Fixtures.InvalidConfiguration()
        @fact_throws AssertionError name(cfg)
        @fact_throws AssertionError source(cfg)
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
        @fact logger(cfg, Fixtures.TESTNAME) --> cfg.root
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
        context("with default parameters when not started") do
            @fact logger(cfg, Fixtures.TESTNAME) --> cfg.root
            @fact loggers(cfg) --> isempty
            @fact appenders(cfg) --> isempty
            @fact state(cfg) --> Log4jl.LifeCycle.INITIALIZED
        end
        context("appender is added when `setup` is performed") do
            @fact length(appenders(cfg)) --> 0
            setup(cfg)
            @fact length(appenders(cfg)) --> greater_than(0)
            apnd = appender(cfg, "Default")
            @fact isa(apnd, Log4jl.Appenders.Console) --> true
        end
        context("logger configuration is added when `configure` is performed") do
            # There is no other logger then "root"
            @fact length(loggers(cfg)) --> 0
            lgrcfg = logger(cfg, "Default")
            @fact isa(lgrcfg, Log4jl.LoggerConfig) --> true
            @fact lgrcfg --> cfg.root

            apnds = appenders(cfg) |> values
            @fact length(apnds) --> greater_than(0)
            @fact length(references(lgrcfg)) --> 0
            configure(cfg)

            apndrefs = references(lgrcfg)
            @fact length(apndrefs) --> greater_than(0)
            @fact isa(first(apndrefs), Log4jl.Appenders.Reference) --> true
            @fact first(apnds) --> first(apndrefs).appender
        end
    end
end

end