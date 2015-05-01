module Messages

    using Log4jl: Message

    type SimpleMessage <: Message
        message::String
    end
    format(msg::SimpleMessage)     = msg.message
    message(msg::SimpleMessage)    = msg.message
    parameters(msg::SimpleMessage) = nothing
    Base.show(io::IO, msg::SimpleMessage) = print(io, "SimpleMessage[message=",msg.message,']')

end