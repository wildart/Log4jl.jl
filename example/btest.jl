module btest

type BackTraceElement
    mod::Symbol
    func::Symbol
    file::Symbol
    line::Int
end

function getbacktrace()
    bt = backtrace()
    btout = BackTraceElement[]
    mod = current_module()
    for b in bt
        code = ccall(:jl_lookup_code_address, Any, (Ptr{Void}, Cint), b, true)
        if !code[6]
            push!(btout, BackTraceElement(symbol(mod),code[1],code[2],code[3]))
        end
    end
    return btout
end


function test1()
    println("Calling test 1")
    test2("Calling test 2")
    a = pwd()
    return joinpath(a,"a")
end


function test2(a)
    println("$a")
    bts = getbacktrace()
    for bt in bts
        println(bt)
    end
end

test1()
end