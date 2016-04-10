include("fixtures.jl")

tests = ["message", "appender", "logconfig", "config", "logger_params"]

for t in tests
    fp = "$t.jl"
    include(fp)
end
