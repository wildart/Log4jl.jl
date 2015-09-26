tests = ["message", "logger"]

for t in tests
    fp = "$t.jl"
    include(fp)
end
