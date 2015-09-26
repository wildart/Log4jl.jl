"""
The anchor for the logging system. It maintains a list of all the loggers
requested by applications and a reference to the configuration.
It will be atomically updated whenever a reconfigure occurs.
"""
type LoggerContext <: LifeCycle.Object
    name::AbstractString
    loggers::LOGGERS
    config::Configuration
    configLocation::AbstractString
    state::LifeCycle.State
end
LoggerContext(name::AbstractString, cgf::Configuration, cfgloc::AbstractString) =
    LoggerContext(name, LOGGERS(), cgf, cfgloc, LifeCycle.INITIALIZED)
LoggerContext(name::AbstractString) = LoggerContext(name, DefaultConfiguration(), "")

config(ctx::LoggerContext) = ctx.config

function start(ctx::LoggerContext)
    debug(LOGGER, "Starting LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]...")
    if state(ctx) == LifeCycle.INITIALIZED || state(ctx) == LifeCycle.STOPPED
        # add shutdonw hook
        atexit(()->begin
                    debug(LOGGER, symbol("SHUTDOWN HOOK"), "Stopping LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]")
                    stop(ctx)
                   end)
        state!(ctx, LifeCycle.STARTED)
    end
    start(config(ctx))
    debug(LOGGER, "LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))] started OK.")
end

function stop(ctx::LoggerContext)
    debug(LOGGER, "Stopping LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))]...")
    state(ctx) == LifeCycle.STOPPED && return
    state!(ctx, LifeCycle.STOPPING)
    stop(ctx.config)
    state!(ctx, LifeCycle.STOPPED)
    debug(LOGGER, "Stopped LoggerContext[name=$(ctx.name), state=$(string(state(ctx)))].")
end

"Returns a logger from a logger context"
function logger(ctx::LoggerContext, name::AbstractString, msgfactory)
    # return logger in exists
    name in ctx && return ctx.loggers[name]

    # otherwise create new logger and return it
    lgr = Logger(name, msgfactory, logger(ctx.config, name))
    ctx.loggers[name] = lgr
    return lgr
end

"Returns all loggers."
loggers(ctx::LoggerContext) = values(ctx.loggers)

"Checks if a logger with the specified name exists."
in(name::AbstractString, ctx::LoggerContext) = name in keys(ctx.loggers)

"Returns the current `Configuration`."
config(ctx::LoggerContext) = ctx.config
