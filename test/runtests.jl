tests = ["message"]

for t in tests
    fp = "$t.jl"
    include(fp)
end
