#==
Run example with default log level:

    >julia simple.jl

Run example with elevated log level:

    >LOG4JL_DEFAULT_STATUS_LEVEL=ALL julia simple.jl

==#
module Log4jlExample
    println("Current:", current_module())
    # println("Current:", module_parent(current_module()))

    using Log4jl
    const logger = @Log4jl.logger

    module Log4jlExample2
        println("Current:", current_module())

        using Log4jl
        const logger = @Log4jl.logger URI="log4jl.json"
        Log4jl.level!(logger, Log4jl.Level.WARN)

        module Log4jlExample3
            println("Current:", current_module())

            using Log4jl
            const logger = @Log4jl.logger begin
                dc = Log4jl.DefaultConfiguration()
                appender!(dc, STDOUT = Log4jl.Appenders.Console(
                    layout = Log4jl.Layouts.PatternLayout("%d{%Y-%m-%d %H:%M:%S} [%t] %-5p %l %c{3} - %m%n")
                ))
                logger!(dc, "Log4jlExample.Log4jlExample2.Log4jlExample3", Log4jl.LoggerConfig("Custom", Log4jl.Level.WARN))
                reference!(dc, "Log4jlExample.Log4jlExample2.Log4jlExample3", "STDOUT")
                return dc
            end

            println(logger)
            println(logger.config)

            function test_log3()
                fatal(logger, "fffff {}", 5)
                @fatal "FFF {}" 5
                @debug "BBB {}" 1
                @warn  "DDD {}" 3
            end

        end

        function test_log2()
            Log4jlExample2.Log4jlExample3.test_log3()

            @trace "L2: AAA"
            @debug "L2: BBB"
            @info  "L2: CCC {}" 2
            @warn  "L2: DDD {}" 3
            @error "L2: EEE {}" 4
            @fatal "L2: FFF {}" 5
        end

    end

    function test_log1()
        Log4jlExample2.test_log2()

        trace(logger, "aaaaa")
        debug(logger, "bbbbb {}", 1)
        info(logger,  "ccccc {}", 2)
        @warn "ddddd {}" 3
        sleep(1.)
        fatal(logger, "fffff {}", 5)
        error(logger, "eeeee {}", 4)
    end

end

println("Current:", current_module())

println("Registered contexts:")
for (ctxname, ctx) in Log4jl.contexts(Log4jl.LOG4JL_CONTEXT_SELECTOR)
    println("\t$ctxname => $ctx")
    for (lgrname, lgr) in ctx.loggers
        # lgr = Log4jl.logger(ctx, lgrname)
        println("\t\t$lgrname => $lgr")
        println("\t\t\t$(lgr.config)")
    end
end
println()

Log4jlExample.test_log1()
println("END\n")
