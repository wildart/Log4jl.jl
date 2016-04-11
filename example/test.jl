module Test
@time eval(:(using Log4jl))

@time const logger = @Log4jl.logger "Log4jlExample"

function test()
error(logger, "test 1")
@error "test {}" 2
end

# println("Name:")
# @time @Log4jl.logger "AAA"
# println()

# println("Root:")
# @time @Log4jl.rootlogger
# println()

# println("Msg:")
# @time @Log4jl.logger MSG=LOG4JL_DEFAULT_STATUS_LEVEL
# println()

# println("Vaild URI:")
# @time @Log4jl.logger(URI="log4jl.yml") |> println

# println("Invalid URI:")
# @time @Log4jl.logger(URI="log4j1l.yml") |> println


# println("Bad parser:")
# @Log4jl.logger URI="log4jl.xxx"
# println()

# println("Code:")
# @Log4jl.logger begin 1 end
# println()

# println("ALL:")
# @Log4jl.logger URI="log4jl.yml" MSG=LOG4JL_DEFAULT_STATUS_LEVEL
# println()

# println("ALL:")
# @Log4jl.logger "AAA" MSG=LOG4JL_DEFAULT_STATUS_LEVEL begin 1 end
# println()
end

Test.test()