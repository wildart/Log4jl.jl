module TestLogConfig

using ..Fixtures
using FactCheck
using Log4jl
import Log4jl: LoggerConfig, name, level, isadditive, isenabled


facts("Logger Configuration") do
    context("specifies `root` logger configuration by default") do
        lc = LoggerConfig()
        @fact level(lc) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact name(lc) --> isempty
        @fact lc --> not(isadditive)
    end

    context("created with name and level parameters") do
        lc = LoggerConfig(Fixtures.TESTNAME, Fixtures.TESTLEVEL)
        @fact level(lc) --> Fixtures.TESTLEVEL
        @fact name(lc) --> Fixtures.TESTNAME
        @fact lc --> not(isadditive)
    end
end

end
