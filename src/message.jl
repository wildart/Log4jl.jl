module Messages

    using Log4jl: Message
    import Log4jl: format, formatted, parameters

    type SimpleMessage <: Message
        message::AbstractString
    end
    formatted(msg::SimpleMessage)  = msg.message
    format(msg::SimpleMessage)     = msg.message
    parameters(msg::SimpleMessage) = nothing
    Base.show(io::IO, msg::SimpleMessage) = print(io, "SimpleMessage[message=",msg.message,']')

    type ObjectMessage <: Message
        message::Any
    end
    formatted(msg::ObjectMessage)  = string(msg.message)
    format(msg::ObjectMessage)     = formatted(msg)
    parameters(msg::ObjectMessage) = [msg.message]
    Base.show(io::IO, msg::ObjectMessage) = print(io, "ObjectMessage[message=",msg.message,']')

    """ Message pattern contains placeholders indicated by '{}' """
    type StringFormattedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
    end
    function formatted(msg::StringFormattedMessage)
        offs = map(ss->ss.offset, matchall(r"({})+",msg.pattern))
        @assert length(offs) == length(msg.params) "Pattern does not match parameters"
        sstart = 1
        sformatted = ""
        for (i,send) in enumerate(offs)
            sformatted *= msg.pattern[sstart:send]
            sformatted *= string(msg.params[i])
            sstart = send+3
        end
        sformatted
    end
    format(msg::StringFormattedMessage)     = msg.pattern
    parameters(msg::StringFormattedMessage) = msg.params
    Base.show(io::IO, msg::StringFormattedMessage) =
        print(io, "StringFormatMessage[pattern='",msg.pattern,"', args=",msg.params,']')

    """ Message pattern contains 'printf' format string"""
    type PrintfFormattedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
    end
    formatted(msg::PrintfFormattedMessage)  = @eval @sprintf($(msg.pattern), $(msg.params)...)
    format(msg::PrintfFormattedMessage)     = msg.pattern
    parameters(msg::PrintfFormattedMessage) = msg.params
    Base.show(io::IO, msg::PrintfFormattedMessage) =
        print(io, "PrintfFormattedMessage[pattern='",msg.pattern,"', args=",msg.params,']')


    # Message generating functions
    simplemessage(msg::AbstractString, params...) = SimpleMessage(msg)
    simplemessage(msg::Any) = ObjectMessage(msg)

    stringsformattermessage(msg::AbstractString, params...) = StringFormattedMessage(msg, [params...])
    stringsformattermessage(msg::Any) = ObjectMessage(msg)

    printfformattermessage(msg::AbstractString, params...) = PrintfFormattedMessage(msg, [params...])
    printfformattermessage(msg::Any) = ObjectMessage(msg)


    export simplemessage, stringsformattermessage, printfformattermessage

end
