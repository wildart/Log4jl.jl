"""
The anchor for the logging system. It maintains a list of all the loggers
requested by applications and a reference to the configuration.
It will be atomically updated whenever a reconfigure occurs.
"""
type LoggerContext
    name::AbstractString
    loggers::LOGGERS
    config::Configuration
    configLocation::AbstractString
end
LoggerContext(name::AbstractString) = LoggerContext(name, LOGGERS(), DefaultConfiguration(), "")

"Returns a logger from a logger context"
function logger(ctx::LoggerContext, name::AbstractString, msg::FACTORY=FACTORY())
    # return logger in exists
    name in ctx && return ctx.loggers[name]

    # otherwise create new logger and return it
    logcnf = logger(config, name)
    logcnf = logcnf !== nothing ? logcnf : TODO
    logger = Logger(name, msgfact, logcnf)
    ctx.loggers[name] = logger
    return logger
end

"Returns all loggers."
loggers(ctx::LoggerContext) = values(ctx.loggers)

"Checks if a logger with the specified name exists."
in(name::AbstractString, ctx::LoggerContext) = name in keys(ctx.loggers)

"Returns the current `Configuration`."
config(ctx::LoggerContext) = ctx.config

"Set the configuration to be used in the context."
function config!(ctx::LoggerContext, cfg::Configuration)
    ctx.config = cfg
    #TODO: reconfigure()
end



"Logger context selector"
abstract ContextSelector

"Returns a logger context."
context(ctxsel::ContextSelector, fqmn::AbstractString, cfgloc::AbstractString="") = throw(AssertionError("Function 'context' is not implemented for type $(typeof(ctxsel))"))

"Return all contexts"
contexts(ctxsel::ContextSelector) = throw(AssertionError("Function 'contexts' is not implemented for type $(typeof(ctxsel))"))

"Remove specified logger context"
delete!(ctxsel::ContextSelector, ctx::LoggerContext) = throw(AssertionError("Function 'contexts' is not implemented for type $(typeof(ctxsel))"))



"Simple logger context selector that keeps only one context"
type SingleContextSelector <: ContextSelector
    context::LoggerContext
    SingleContextSelector() = new(LoggerContext("Default"))
end
context(ctxsel::SingleContextSelector, fqmn::AbstractString, cfgloc::AbstractString="") = ctxsel.context
contexts(ctxsel::SingleContextSelector) = Dict(:Default=>ctxsel.context)


"""Module context selector choses `LoggerContext` based on module name

All `LoggerContext` instances are stored in module constants with unique name `__Log4jl_LC<ID>__`
"""
type ModuleContextSelector <: ContextSelector
    default::LoggerContext
    ModuleContextSelector() = new(LoggerContext("Default"))
end

function context(ctxsel::ModuleContextSelector, fqmn::AbstractString, cfgloc::AbstractString="")
    # return default context if module doesn't exist
    m = getmodule(fqmn)
    if m !== nothing
        mlc_var = mlcvar(fqmn)
        isconst(m, mlc_var) && return getfield(m, mlc_var)

        # otherwise create a new context
        ctx = LoggerContext(string(mlc_var))
        ctx.configLocation = cfgloc

        # define constant in module with LoggerContext object
        ccall(:jl_set_const, Void, (Any, Any, Any), m,  mlc_var, ctx)

        return ctx
    end
    return ctxsel.default
end

function contexts(ctxsel::ModuleContextSelector)

    function submodules(m::Module, mdls::Vector{Symbol}= Symbol[], ctxs = Dict{Symbol,LoggerContext}())
        for vs in names(m, true)
            !isdefined(m, vs) && continue
            v = getfield(m, vs)
            if isa(v, Module) && vs ∉ [:Main, :Core, :Base]
                fqmn = symbol(v)
                fqmn in mdls && continue
                push!(mdls, fqmn)
                mlc_var = mlcvar(string(fqmn))
                if isdefined(v, mlc_var)
                    ctxs[fqmn] = getfield(v, mlc_var)
                end
                submodules(v, mdls, ctxs)
            end
        end
        return mdls, ctxs
    end

    mdls, ctxs = submodules(Main)
    ctxs[:Default] = ctxsel.default
    return ctxs
end
