include("fixtures.jl")

tests = ["message", "appender", "logconfig", "config", "logger_params", "level"]

for t in tests
    fp = "$t.jl"
    include(fp)
end
