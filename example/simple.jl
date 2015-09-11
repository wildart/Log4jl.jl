#==
Run example with default log level:

    >julia simple.jl

Run example with elevated log level:

    >LOG4JL_DEFAULT_STATUS_LEVEL=ALL julia simple.jl

==#
module Log4jlExample
    println("Current:", current_module())
    println("Current:", module_parent(current_module()))

    using Log4jl
    @Log4jl.configure

    module Log4jlExample2
        println("Current:", current_module())

        using Log4jl
        @Log4jl.configure "log4jl.json"

        module Log4jlExample3
            println("Current:", current_module())

            using Log4jl
            @Log4jl.configure begin
                Log4jl.DefaultConfiguration()
            end

            const logger = Log4jl.getLogger()

            @fatal "FFF {}" 5
            @debug "BBB {}" 1
            @warn  "DDD {}" 3

        end

        const logger = Log4jl.getLogger()

        @trace "AAA"
        @info  "CCC {}" 2
        @error "EEE {}" 4

    end

    const logger = Log4jl.getLogger()

    trace(logger, "aaaaa")
    debug(logger, "bbbbb {}", 1)
    info(logger,  "ccccc {}", 2)
    warn(logger,  "ddddd {}", 3)
    error(logger, "eeeee {}", 4)
    fatal(logger, "fffff {}", 5)

end