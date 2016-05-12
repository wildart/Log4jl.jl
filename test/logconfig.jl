module TestLogConfig

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: LoggerConfig, name, level, isadditive, isenabled, parent, parent!, level!


facts("Logger Configuration") do
    context("specifies `root` logger configuration by default") do
        lc = LoggerConfig()
        @fact level(lc) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact name(lc) --> isempty
        @fact lc --> not(isadditive)
        @fact parent(lc) --> isnull
    end

    context("created with name and level parameters") do
        lc = LoggerConfig(Fixtures.TESTNAME)
        @fact level(lc) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact name(lc) --> Fixtures.TESTNAME
        @fact lc --> not(isadditive)
    end

    context("could have a different log level and a parent") do
        lc = LoggerConfig(Fixtures.TESTNAME, level=Fixtures.TESTLEVELN)
        @fact level(lc) --> Fixtures.TESTLEVEL
        level!(lc, Log4jl.Level.OFF)
        @fact level(lc) --> Log4jl.Level.OFF
        plc = LoggerConfig()
        parent!(lc, plc)
        @fact parent(lc) --> not(isnull)
        @fact get(parent(lc)) --> plc
    end
end

end
