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