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
        lc = LoggerConfig(Fixtures.TESTNAME, Fixtures.TESTLEVEL)
        @fact level(lc) --> Fixtures.TESTLEVEL
        @fact name(lc) --> Fixtures.TESTNAME
        @fact lc --> not(isadditive)
    end

    context("could have a different log level and a parent") do
        lc = LoggerConfig(Fixtures.TESTNAME, Fixtures.TESTLEVELN)
        @fact level(lc) --> Fixtures.TESTLEVEL
        level!(lc, Log4jl.Level.OFF)
        @fact level(lc) --> Log4jl.Level.OFF
        plc = LoggerConfig()
        parent!(lc, plc)
        println(parent(lc))
        @fact parent(lc) --> not(isnull)
        @fact get(parent(lc)) --> plc
    end

    context("can filter logging messages and events") do
        lc = LoggerConfig(Fixtures.TESTNAME, Log4jl.Level.INFO)
        @fact isenabled(lc, Log4jl.Level.INFO, Fixtures.TESTMARKER, "MSG") --> true
        level!(lc, Log4jl.Level.OFF)
        @fact isenabled(lc, Log4jl.Level.INFO, Fixtures.TESTMARKER, "MSG") --> false
    end
end

end
