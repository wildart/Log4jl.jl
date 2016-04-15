include("fixtures.jl")

tests = ["message", "appender", "logconfig", "config", "logger_params", "level", "event"]

for t in tests
    fp = "$t.jl"
    include(fp)
end
