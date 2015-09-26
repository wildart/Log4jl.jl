"Logger context selector"
abstract ContextSelector

"Returns a logger context with specific configuration."
context(ctxsel::ContextSelector,
        fqmn::AbstractString,
        cfg::Configuration,
        cfgloc::AbstractString) = throw(AssertionError("Function 'context' is not implemented for type $(typeof(ctxsel))"))

"Returns a logger context with evaluated configuration."
context(ctxsel::ContextSelector,
        fqmn::AbstractString,
        cfgexp::Nullable{Expr}) = context(ctxsel, fqmn, evalConfiguration(cfgexp), "")

context(ctxsel::ContextSelector,
        fqmn::Module,
        cfgexp::Nullable{Expr}) = context(ctxsel, string(fqmn), cfgexp)

"Returns a logger context with located configuration."
context(ctxsel::ContextSelector,
        fqmn::AbstractString,
        cfgloc::AbstractString) = context(ctxsel, getmodule(fqmn), cfgloc)

function context(ctxsel::ContextSelector, fqmn::Module, cfgloc::AbstractString)
    # Get module dir
    cmdir = moduledir(fqmn)

    config_file, parser_type = if isempty(cfgloc)
        # search a module directory for configurations
        searchConfiguration(cmdir)
    else
        # or use a provided location to a determine parser
        config_loc = joinpath(cmdir, cfgloc)
        config_loc, findConfigurationParser(config_loc)
    end

    # Get configuration type and instantiate object from it
    cfgtype = LOG4JL_CONFIG_TYPES[get(parser_type, :DEFAULT)]
    cfg = try
        eval(Log4jl, Expr(:call, cfgtype, config_file))
    catch err
        error(LOGGER, "Configuration failed. Using default configuration. Error: $(err)")
        DefaultConfiguration()
    end

    context(ctxsel, string(fqmn), cfg, config_file)
end
context(ctxsel::ContextSelector, cfgloc::AbstractString) = context(ctxsel, current_module(), cfgloc)

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
    context::LoggerContext
    SingleContextSelector() = new(LoggerContext("Default"))
end
context(ctxsel::SingleContextSelector, fqmn::AbstractString, cfgloc::AbstractString="") = ctxsel.context
contexts(ctxsel::SingleContextSelector) = Dict(:Main=>ctxsel.context)



"""Module context selector choses `LoggerContext` based on module name

All `LoggerContext` instances are stored inside a module where `Log4jl` configuration was performed in a constant with unique name `__Log4jl_LC<ID>__`
"""
type ModuleContextSelector <: ContextSelector
    default::LoggerContext
    ModuleContextSelector() = new(LoggerContext("Default"))
end

function context(ctxsel::ModuleContextSelector,
                 fqmn::AbstractString,
                 cfg::Configuration,
                 cfgloc::AbstractString)
    # return default context if module doesn't exist
    m = getmodule(fqmn)
    if m !== nothing
        mlc_var = mlcvar(fqmn)
        isconst(m, mlc_var) && return getfield(m, mlc_var)

        # otherwise create a new context
        ctx = LoggerContext(string(mlc_var), cfg, cfgloc)

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
