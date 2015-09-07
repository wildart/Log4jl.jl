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

    dlm = @windows? '\\' : '/'
    return join(split(mpath, dlm)[1:end-rmpaths], dlm)
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

mlcvar(fqmn::AbstractString) = symbol("__Log4jl_LC$(string(hash(fqmn)))__")

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