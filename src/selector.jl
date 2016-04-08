"Logger context selector"
abstract ContextSelector

"Return current context"
context(ctxsel::ContextSelector, fqmn::AbstractString, cfgloc::AbstractString) = throw(AssertionError("Function 'context' is not implemented for type $(typeof(ctxsel))"))
context(ctxsel::ContextSelector, cfgloc::AbstractString="") = context(ctxsel, string(current_module()), cfgloc)

"Return all contexts"
contexts(ctxsel::ContextSelector) = throw(AssertionError("Function 'contexts' is not implemented for type $(typeof(ctxsel))"))

"Remove specified logger context"
delete!(ctxsel::ContextSelector, ctx::LoggerContext) = throw(AssertionError("Function 'contexts' is not implemented for type $(typeof(ctxsel))"))

####################################
# Implementations of ContextSelector
####################################

"""Single context selector

Simple logger context selector that keeps only one context inside itself.
"""
type SingleContextSelector <: ContextSelector
    default::LoggerContext
    SingleContextSelector() = new(LoggerContext("Default"))
end
context(ctxsel::SingleContextSelector, fqmn::AbstractString, cfgloc::AbstractString="") = ctxsel.default
contexts(ctxsel::SingleContextSelector) = Dict(:Default=>ctxsel.default)


"""Module context selector choses `LoggerContext` based on module name

All `LoggerContext` instances are stored inside a module where `Log4jl` configuration was performed in a constant with unique name `__Log4jl_LC<ID>__`
"""
type ModuleContextSelector <: ContextSelector
    default::LoggerContext
    ModuleContextSelector() = new(LoggerContext("Default"))
end

function context(ctxsel::ModuleContextSelector,
                 fqmn::AbstractString,
                 cfgloc::AbstractString="")

    # return default context if module doesn't exist
    isempty(fqmn) && return ctxsel.default

    # get module for context selector
    ctx_module = getmodule(fqmn)

    # return context object in the module
    mlc_var = mlcvar(string(fqmn))
    if isconst(ctx_module, mlc_var)
        trace(LOGGER, "Found context: $mlc_var")
        return getfield(ctx_module, mlc_var)
    end

    ctx = ctxsel.default

    # check configuration source
    cfgloc = locateconfig(cfgloc, ctx_module)
    if isempty(cfgloc)
        trace(LOGGER, "Invalid configuration source")

        # look for parent context
        parent_ctx_module = module_parent(ctx_module)
        found = false
        for vs in names(parent_ctx_module, true)
            if startswith(string(vs), LOG4JL_CTX_PREFIX)
                ctx = getfield(parent_ctx_module, vs)
                trace(LOGGER, "Found parent context: $vs")
                found = true
                break
            end
        end
        !found && trace(LOGGER, "No parent context found.")
    else
        trace(LOGGER, "Creating new context in the module: $ctx_module")

        # otherwise create a new context
        ctx = LoggerContext(string(mlc_var), cfgloc)

        # define constant in module with LoggerContext object
        ccall(:jl_set_const, Void, (Any, Any, Any), ctx_module,  mlc_var, ctx)
    end

    # return default context if non found
    return ctx
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
