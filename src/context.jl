"""
The anchor for the logging system. It maintains a list of all the loggers
requested by applications and a reference to the configuration.
It will be atomically updated whenever a reconfigure occurs.
"""
type LoggerContext <: LifeCycle.Object
    name::AbstractString
    loggers::LOGGERS
    configLocation::AbstractString
    config::Configuration
    state::LifeCycle.State
end
LoggerContext(name::AbstractString, cfgloc::AbstractString, cfg::Configuration) =
    LoggerContext(name, LOGGERS(), cfgloc, cfg, LifeCycle.INITIALIZED)
LoggerContext(name::AbstractString, cfgloc::AbstractString="") =
    LoggerContext(name, cfgloc, DefaultConfiguration())

show(io::IO, ctx::LoggerContext) = print(io, "LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]")

"Setup context with a new configuration and return previous one"
function setconfig!(ctx::LoggerContext, cfg::Configuration)
    prevcfg = ctx.config

    if isdefined(cfg, :properties)
        !haskey(cfg.properties, "host") && setindex!(cfg.properties, "host", gethostname())
        !haskey(cfg.properties, "context") && setindex!(cfg.properties, "context", ctx.name)
    end
    start(cfg)
    ctx.config = cfg
    ctx.configLocation = source(cfg)
    prevcfg !== nothing && stop(prevcfg)

    return prevcfg
end

"Setup context with a configuration located at the provided location"
function setconfig!(ctx::LoggerContext, cfgloc::AbstractString)
    ctx.configLocation = cfgloc
    reconfigure!(ctx)
end

"Reconfigure context"
function reconfigure!(ctx::LoggerContext)
    debug(LOGGER, "Reconfiguration started for context[name=$(ctx.name)] at $(ctx.configLocation)")
    cfg = getconfig(ctx.configLocation, ctx.name, current_module())
    @assert cfg !== nothing "No configuration found"
    setconfig!(ctx, cfg)
    debug(LOGGER, "Reconfiguration complete for context[name=$(ctx.name)] at $(ctx.configLocation)")
end

"Start context."
function start(ctx::LoggerContext)
    debug(LOGGER, "Starting LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]...")
    if state(ctx) == LifeCycle.INITIALIZED || state(ctx) == LifeCycle.STOPPED
        state!(ctx, LifeCycle.STARTING)
        reconfigure!(ctx)
        # add shutdown hook
        atexit(()->begin
                    debug(LOGGER, symbol("SHUTDOWN HOOK"), "Stopping LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]")
                    stop(ctx)
                   end)
        state!(ctx, LifeCycle.STARTED)
    end
    debug(LOGGER, "LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))] started OK.")
end

"Start context with a specific configuration."
function start(ctx::LoggerContext, cfg::Configuration)
    debug(LOGGER, "Starting LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]...")
    if state(ctx) == LifeCycle.INITIALIZED || state(ctx) == LifeCycle.STOPPED
        state!(ctx, LifeCycle.STARTING)
        # add shutdown hook
        atexit(()->begin
                    debug(LOGGER, symbol("SHUTDOWN HOOK"), "Stopping LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]")
                    stop(ctx)
                   end)
        state!(ctx, LifeCycle.STARTED)
    end
    setconfig!(ctx, cfg)
    debug(LOGGER, "LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))] started OK.")
end

"Stop context."
function stop(ctx::LoggerContext)
    debug(LOGGER, "Stopping LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]...")
    state(ctx) == LifeCycle.STOPPED && return
    state!(ctx, LifeCycle.STOPPING)

    prevcfg = ctx.config
    ctx.config = NullConfiguration()
    stop(prevcfg)

    state!(ctx, LifeCycle.STOPPED)
    debug(LOGGER, "Stopped LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))].")
end

"Checks if a logger with the specified name exists."
in(lname::AbstractString, ctx::LoggerContext) = haskey(ctx.loggers, lname)

"Returns a logger from a logger context"
function logger(ctx::LoggerContext, lname::AbstractString,
                msgfactory::DataType=LOG4JL_DEFAULT_MESSAGE)
    # return logger in exists
    lname in ctx && return ctx.loggers[lname]

    # otherwise create new logger and return it
    lgr = Logger(lname, msgfactory, logger(ctx.config, lname), filter(ctx.config))
    ctx.loggers[lname] = lgr
    return lgr
end

"Returns all loggers."
loggers(ctx::LoggerContext) = values(ctx.loggers)
