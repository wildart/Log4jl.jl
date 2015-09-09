module Messages

    using Log4jl: Message
    import Log4jl: format, formatted, parameters

    "Message handles everything as string."
    type SimpleMessage <: Message
        message::AbstractString
    end
    formatted(msg::SimpleMessage)  = msg.message
    format(msg::SimpleMessage)     = msg.message
    parameters(msg::SimpleMessage) = nothing
    Base.show(io::IO, msg::SimpleMessage) = print(io, "SimpleMessage[message=",msg.message,']')


    "Message with raw objects"
    type ObjectMessage <: Message
        message::Any
    end
    formatted(msg::ObjectMessage)  = string(msg.message)
    format(msg::ObjectMessage)     = formatted(msg)
    parameters(msg::ObjectMessage) = Any[msg.message]
    Base.show(io::IO, msg::ObjectMessage) = print(io, "ObjectMessage[message=",msg.message,']')


    "Message pattern contains placeholders indicated by '{}'"
    type ParameterizedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
    end
    ParameterizedMessage(ptrn::AbstractString, params...) = ParameterizedMessage(ptrn, [params...])
    function formatted(msg::ParameterizedMessage)
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
    format(msg::ParameterizedMessage)     = msg.pattern
    parameters(msg::ParameterizedMessage) = msg.params
    Base.show(io::IO, msg::ParameterizedMessage) =
        print(io, "ParameterizedMessage[pattern='",msg.pattern,"', args=",msg.params,']')


    "Message pattern contains 'printf' format string"
    type PrintfFormattedMessage <: Message
        pattern::AbstractString
        params::Vector{Any}
    end
    PrintfFormattedMessage(ptrn::AbstractString, params...) = PrintfFormattedMessage(ptrn, [params...])
    formatted(msg::PrintfFormattedMessage)  = @eval @sprintf($(msg.pattern), $(msg.params)...)
    format(msg::PrintfFormattedMessage)     = msg.pattern
    parameters(msg::PrintfFormattedMessage) = msg.params
    Base.show(io::IO, msg::PrintfFormattedMessage) =
        print(io, "PrintfFormattedMessage[pattern='",msg.pattern,"', args=",msg.params,']')


    #TODO: MapMessage: XML, JSON, Dict
    #TODO: StructuredDataMessage: RFC 5424

    # Message generating functions
    simplemessage(msg::AbstractString, params...) = SimpleMessage(msg)
    simplemessage(msg::Any) = ObjectMessage(msg)

    parameterizedmessage(msg::AbstractString, params...) = ParameterizedMessage(msg, params...)
    parameterizedmessage(msg::Any) = simplemessage(msg)

    printfformattermessage(msg::AbstractString, params...) = PrintfFormattedMessage(msg, params...)
    printfformattermessage(msg::Any) = simplemessage(msg)


    export simplemessage, parameterizedmessage, printfformattermessage

end
