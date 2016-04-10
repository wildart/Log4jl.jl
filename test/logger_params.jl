module TestLoggerParams

using Log4jl
using FactCheck

cmname = string(current_module())

macro logger(params...)
    parser_type = Nullable{Symbol}()
    name, msgfactory, config_file, config_eval = Log4jl.parseargs(params, cmname)
    quote
        $name, $msgfactory, $config_file, $config_eval
    end
end

macro rootlogger(params...)
    :(@logger $(Log4jl.ROOT_LOGGER_NAME) $(params...))
end

facts("Parameter parser of `logger` macro") do
    context("no parameters") do
        res = @logger
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> true
    end
    context("logger name") do
        res = @logger "AAA"
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> true
    end
    context("root name") do
        res = @rootlogger
        @fact isempty(res[1]) --> true
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> true
    end
    context("massage factory") do
        res = @logger MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> true
    end
    context("configuration uri") do
        res = @logger URI="log4jl.yml"
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact get(res[3]) --> "log4jl.yml"
        @fact isnull(res[4]) --> true
    end
    context("programmable configuration") do
        res = @logger begin 1 end
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> false
    end
    context("logger name and massage factory") do
        res = @logger "AAA" MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> true
    end
    context("logger name and configuration uri") do
        res = @logger "AAA" URI="log4jl.yml"
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact get(res[3]) --> "log4jl.yml"
        @fact isnull(res[4]) --> true
    end
    context("logger name and programmable configuration") do
        res = @logger "AAA" begin 1 end
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_MESSAGE
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> false
    end
    context("massage factory and configuration uri") do
        res = @logger MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL URI="log4jl.yml"
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact get(res[3]) --> "log4jl.yml"
        @fact isnull(res[4]) --> true
    end
    context("configuration uri and massage factory") do
        res = @logger URI="log4jl.yml" MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact get(res[3]) --> "log4jl.yml"
        @fact isnull(res[4]) --> true
    end
    context("massage factory and programmable configuration") do
        res = @logger MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL begin 1 end
        @fact res[1] --> cmname
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> false
    end
    context("name, massage factory and programmable configuration") do
        res = @logger "AAA" MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL begin 1 end
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact isnull(res[3]) --> true
        @fact isnull(res[4]) --> false
    end
    context("name, configuration uri and massage factory") do
        res = @logger "AAA" URI="log4jl.yml" MSG=Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact res[1] --> "AAA"
        @fact res[2] --> Log4jl.LOG4JL_DEFAULT_STATUS_LEVEL
        @fact get(res[3]) --> "log4jl.yml"
        @fact isnull(res[4]) --> true
    end

end

end