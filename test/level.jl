module TestLevel

using FactCheck
using Log4jl
import Log4jl.Level

facts("Levels") do
    context("are comparable") do
        @fact Level.OFF --> less_than(Level.ALL)
        @fact Level.TRACE --> less_than(Level.ALL)
        @fact Level.OFF --> less_than(Level.TRACE)
    end
    context("suport custom values") do
        lvl = :DIAG
        vlvl = Int32(550)
        Level.add(lvl, vlvl)
        @fact_throws AssertionError Level.add(lvl, vlvl)
        @fact Level.OFF --> less_than(Level.DIAG)
        @fact Level.DIAG --> less_than(Level.TRACE)
    end
end

end
