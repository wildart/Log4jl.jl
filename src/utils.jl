type BackTraceElement
    func::Symbol
    file::Symbol
    line::Int
end
BackTraceElement() = BackTraceElement(symbol(), symbol(), symbol(), -1)
typealias BACKTRACE Nullable{BackTraceElement}

function getbacktrace()
    bt = backtrace()
    btout = BackTraceElement[]
    for b in bt
        code = ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Cint), b, true)
        if !code[6]
            push!(btout, BackTraceElement(code[1],code[2],code[3]))
        end
    end
    return btout
end

function moduledir(m::Module)
    mname = string(m)
    mpath = Base.find_in_path(mname)

    # could not find by name, try `eval` function
    if mpath === nothing
        try
            m = eval(:(first(methods($m.eval))))
            mpath = string(m.func.code.file)
        catch
        end
    end

    # no luck - return empty
    mpath === nothing && return ""

    # path does not have module name - no package, remove only file from path
    # otherwise go to th root folder of the package
    rmpaths = contains(mpath, mname) ? 2 : 1

    return join(split(mpath, Base.path_separator)[1:end-rmpaths], Base.path_separator)
end

function isfqmn(fqmn::AbstractString, m::Module=Main)
    submdls = split(fqmn, '.')
    for i in 1:length(submdls)
        ms = symbol(submdls[i])
        !isdefined(m, ms) && return false
        m = getfield(m, ms)
    end
    return true
end

function getmodule(fqmn::AbstractString, m::Module=Main)
    submdls = split(fqmn, '.')
    for i in 1:length(submdls)
        ms = symbol(submdls[i])
        !isdefined(m, ms) && return nothing
        m = getfield(m, ms)
    end
    return m
end

const LOG4JL_CTX_PREFIX = "__Log4jl_"
mlcvar(fqmn::AbstractString) = symbol("$(LOG4JL_CTX_PREFIX)LC$(string(hash(fqmn)))__")

function submodules(m::Module, mdls::Vector{Symbol}= Symbol[])
    for vs in names(m, true)
        v = getfield(m, vs)
        fqmn = symbol(v)
        if isa(v, Module) && vs ∉ [:Main, :Core, :Base] && fqmn ∉ mdls
            push!(mdls, fqmn)
            submodules(v, mdls)
        end
    end
    return mdls
end

function evaltype(stype::AbstractString, smodule::AbstractString="")
    stype = isempty(smodule) ? stype : "$(smodule).$(stype)"
    try
        eval(parse(stype))
    catch
        Void
    end
end

function getlevel(strlevel::AbstractString)
    lt = evaltype(strlevel, "Level")
    return LEVEL(lt === Void ? nothing : lt)
end

function configlevel(conf::Dict)
    return haskey(conf, "level") ? getlevel((conf["level"] |> uppercase)) : LEVEL()
end
