module TestMessages

using ..Fixtures
using Log4jl
using Log4jl.Messages
import Log4jl: format, formatted, parameters
using FactCheck

msgInput = ["test", 10, 11.]

facts("Massages") do
    context("should have required methods implemented") do
        msg = Fixtures.IncompleteMessage()
        @fact_throws AssertionError format(msg)
        @fact_throws AssertionError parameters(msg)
        @fact_throws AssertionError formatted(msg)
    end
    context("can be created from string input") do
        msg = SimpleMessage(msgInput[1])
        @fact format(msg) --> msgInput[1]
        @fact parameters(msg) --> nothing
        @fact formatted(msg) --> msgInput[1]
        @fact parameters(SimpleMessage(msg)) --> Any[msg]
    end
    context("can be created from object input") do
        msg = ObjectMessage(msgInput)
        @fact format(msg) --> string(msgInput)
        @fact parameters(msg) --> Any[msgInput]
        @fact formatted(msg) --> string(msgInput)
    end
    context("can be created from parameterized string input") do
        msgPattern = "Test: {}, {}, {}"
        msg = ParameterizedMessage(msgPattern, msgInput...)
        @fact format(msg) --> msgPattern
        @fact parameters(msg) --> msgInput
        @fact formatted(msg) --> "Test: test, 10, 11.0"
        @fact parameters(ParameterizedMessage(msg)) --> Any[msg]
    end
    context("can be created from 'printf' formatted input") do
        msgPattern = "Test: %s, %d, %.1f"
        msg = PrintfFormattedMessage(msgPattern, msgInput...)
        @fact format(msg) --> msgPattern
        @fact parameters(msg) --> msgInput
        @fact formatted(msg) --> "Test: test, 10, 11.0"
        @fact parameters(PrintfFormattedMessage(msg)) --> Any[msg]
    end
end

end