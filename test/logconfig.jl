module TestLogConfig

using FactCheck
using Log4jl
import Log4jl: LoggerConfig, name, level, isadditive, isenabled

lcname = "TEST"
lclevel = Log4jl.Level.TRACE

facts("Logger Configuration") do
    context("specifies `root` logger configuration by default") do
        lc = LoggerConfig()
        @fact level(lc) --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact name(lc) --> isempty
        @fact isadditive(lc) --> true
    end

    context("created with name and level parameters") do
        lc = LoggerConfig(lcname, lclevel)
        @fact level(lc) --> lclevel
        @fact name(lc) --> lcname
        @fact isadditive(lc) --> true
    end
end

end