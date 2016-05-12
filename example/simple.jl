#==
Run example with default log level:

    >julia simple.jl

Run example with elevated log level:

    >LOG4JL_DEFAULT_STATUS_LEVEL=ALL julia simple.jl

==#
module X
    println("Current:", current_module())
    # println("Current:", module_parent(current_module()))

    using Log4jl
    @Log4jl logger = @logger

    module Y
        println("Current:", current_module())

        using Log4jl
        @Log4jl logger = @logger(URI="log4jl.json")
        Log4jl.level!(logger, Log4jl.Level.WARN)

        module Z
            println("Current:", current_module())

            using Log4jl
            @Log4jl logger = @Log4jl.logger begin
                # Create a configuration for the logger
                cfg = Log4jl.DefaultConfiguration()
                # Add an appender to the configuration
                Log4jl.appender!(cfg, OUTPUT = Log4jl.Appenders.Console(
                    layout = Log4jl.Layouts.PatternLayout("%d{%Y-%m-%d %H:%M:%S} [%t] %-5p %l %c{3} - %m%n")
                ))
                # Add logger configuration with the name of the logger (i.e. "X.Y.Z")
                #Log4jl.logger!(cfg, "X.Y.Z", Log4jl.LoggerConfig("LWC", Log4jl.Level.WARN))
                Log4jl.logger!(cfg, "X.Y.Z", Log4jl.Level.WARN)
                # Reference the appender in the logger configuration
                Log4jl.reference!(cfg, "X.Y.Z" => "OUTPUT")
                return cfg
            end

            println(logger)
            println(logger.config)

            function test_log3()
                fatal(logger, "L3: fatal {}", 5)
                @fatal "L3: FATAL {}" 5
                @debug "L3: DEBUG {}" 1
                @warn  "L3: WARN {}" 3
                @info  "L3: INFO {}" 2
                @debug "L3: DEBUG"
                trace(logger, "L3: TRACE")
            end

        end

        function test_log2()
            Y.Z.test_log3()

            @trace "L2: TRACE"
            @debug "L2: DEBUG"
            @info  "L2: INFO {}" 2
            @warn  "L2: WARN {}" 3
            @error "L2: ERROR {}" 4
            @fatal "L2: FATAL {}" 5
        end

    end

    function test_log1()
        Y.test_log2()

        trace(logger, "aaaaa")
        debug(logger, "bbbbb {}", 1)
        info(logger,  "ccccc {}", 2)
        @warn "ddddd {}" 3
        sleep(1.)
        fatal(logger, "fffff {}", 5)
        error(logger, "eeeee {}", 4)
        Log4jl.verbose(logger, "vvvvv {}", 6)
    end

end

println("Current:", current_module())

println("Registered contexts:")
for (ctxname, ctx) in Log4jl.contexts(Log4jl.LOG4JL_CONTEXT_SELECTOR)
    println("\t$ctxname => $ctx")
    for (lgrname, lgr) in ctx.loggers
        # lgr2 = Log4jl.logger(ctx, lgrname)
        println("\t\t$lgrname => $lgr")
        println("\t\t\t$(lgr.config) => $(Log4jl.references(lgr.config))")
    end
end
println()

X.test_log1()
println("END\n")

xdump(X.logger)