module Log4jl

export Level,
       Message,
       Layout,
       Appender,
       Configuration,
       Logger,
       trace, debug, info, warn, error, fatal,
       @trace, @debug, @info, @warn, @error, @fatal

import Base: append!, serialize, show, in, delete!, string,
             trace, info, warn, error

# To be set parameters
global LOG4JL_LINE_SEPARATOR
global LOG4JL_DEFAULT_STATUS_LEVEL
global LOG4JL_LOG_EVENT
global LOG4JL_CONTEXT_SELECTOR

# Imports
include("utils.jl")
include("types.jl")
include("message.jl")
include("event.jl")
include("layouts.jl")
include("appenders.jl")
include("config.jl")
include("logger.jl")
include("context.jl")

# Constants
const LOG4JL_DEFAULT_MESSAGE = Messages.ParameterizedMessage
const LOG4JL_CONFIG_DEFAULT_PREFIX = "log4jl"
const LOG4JL_CONFIG_EXTS = Dict(:YAML => [".yaml", ".yml"], :JSON=>[".json", ".jsn"], :LightXML=>[".xml"])
const LOG4JL_CONFIG_PARSER_CALL = "parse_<type>_config"
const ROOT_LOGGER_NAME = NAME()


# Functions
"Returns a `Logger` with the specified name for  the fully qualified module name."
function getLogger(name::NAME = NAME(""),
                                fqmn::AbstractString=string(current_module()),
                                msg::FACTORY=FACTORY()
                               )
    ctx = context(LOG4JL_CONTEXT_SELECTOR, fqmn)
    logname = isnull(name) ? "" : isempty(get(name)) ? fqmn : get(name)
    return logger(ctx, logname, msg)
end
function getLogger(name::AbstractString = "",
                                fqmn::AbstractString=string(current_module()),
                                msg::FACTORY=FACTORY() )
    return getLogger(NAME(name), fqmn, msg)
end

"Returns the root logger."
getRootLogger() = getLogger(ROOT_LOGGER_NAME)

"""Log4jl configuration

If programmatic configuration is specified then it will be evaluated into a `Configuration` object. If evaluation The default configuration will be used.
1. Log4jl will look for `log4jl.yaml` or `log4jl.yml` or a user defined YAML configuration file if `YAML` module is loaded, and will attempt to load the configuration
2. If a YAML file cannot be located, and if JSON module is loaded, attempt to load the configuration from `log4jl.json` or `log4jl.jsn` or a user defined JSON configuration file
3. If a JSON file cannot be located, and if XML module is loaded, attempt to load the configuration from `log4jl.xml` or a user defined XML configuration file
4. If no configuration file could be located the default configuration will be used. This will cause logging output to go to the console.

"""
macro configure(body...)
    cm = current_module()
    cm_path = moduledir(cm)

    local config
    local config_file = ""
    local config_eval

    # parse macro parameters
    if length(body) > 0 && isa(body[1], Expr) &&  body[1].head == :block
        config_eval = body
    else
        parser_type = :NONE
        if length(body) > 0 && isa(body[1], AbstractString)

            # Determine parser type based on a configuration file extension
            cfg_prefix, cfg_ext= splitext(body[1])
            for (p,exts) in LOG4JL_CONFIG_EXTS
                if cfg_ext in exts
                    parser_type = p
                    break
                end
            end

            config_file = joinpath(cm_path, body[1])
            config_file = isfile(config_file) ? config_file : ""
        else

            # Search for default configuration file
            for (p,exts) in LOG4JL_CONFIG_EXTS
                for ext in exts
                    cf = joinpath(cm_path, LOG4JL_CONFIG_DEFAULT_PREFIX*ext)
                    if isfile(cf)
                        config_file = cf
                        parser_type = p
                        break
                    end
                end
                !isempty(config_file) && break
            end

        end

        # dynamically load configuration reader
        pts = lowercase(string(parser_type))
        parser_call = replace(LOG4JL_CONFIG_PARSER_CALL, "<type>", pts)
        ptscript = joinpath(dirname(@__FILE__), "config", "$(pts).jl")
        config_eval = parse("include(\"$ptscript\"); $(parser_call)(\"$(config_file)\")")
    end

    # Evaluating configuration
    config = if isempty(config_file)
        DefaultConfiguration()
    else
        try
            eval(Log4jl, config_eval)
        catch err
            println(err)
            # error(LOGGER, "Configuration failed. Using default configuration. Error: $(err)")
            DefaultConfiguration()
        end
    end

    # logger context is initialize  and configured
    ctx = context(LOG4JL_CONTEXT_SELECTOR, string(cm))
    config!(ctx, config)

    # create logger methods
    for (fn,lvl) in ((:trace, Level.TRACE),
                     (:debug, Level.DEBUG),
                     (:info,  Level.INFO),
                     (:warn,  Level.WARN),
                     (:error, Level.ERROR),
                     (:fatal, Level.FATAL))

        @eval $fn(l::Logger, marker::Symbol, msg::AbstractString, params...) = log(l, string(current_module()), $lvl, MARKER(marker), msg, params...)
        @eval $fn(l::Logger, marker::Symbol, msg) = log(l, string(current_module()), $lvl, MARKER(marker), msg)
        @eval $fn(l::Logger, msg::AbstractString, params...) = log(l, string(current_module()), $lvl, MARKER(), msg, params...)
        @eval $fn(l::Logger, msg) = log(l, string(current_module()), $lvl, MARKER(), msg)

    end

    # create logger macros
    for fn in [:trace, :debug, :info, :warn, :error, :fatal]
        @eval macro $fn(msg...)
            # get current module `logger` constant
            mod = current_module()
            fcall = Expr(:call, esc($fn), esc(:logger), msg...)
            quote
                if isdefined($mod, :logger) && isconst($mod, :logger)
                    $fcall;
                end
            end
        end
    end
end

function __init__()
    # Default line separator
    global const LOG4JL_LINE_SEPARATOR = "LOG4JL_LINE_SEPARATOR" in keys(ENV) ?
                                         convert(Vector{UInt8}, ENV["LOG4JL_LINE_SEPARATOR"]) :
                                         @windows? [0x0d, 0x0a] : [0x0a]
    eval(Layouts, parse("import ..Log4jl.LOG4JL_LINE_SEPARATOR"))

    # Default logger context selector
    global const LOG4JL_DEFAULT_STATUS_LEVEL = "LOG4JL_DEFAULT_STATUS_LEVEL" in keys(ENV) ?
                                               eval(parse("Level.$(ENV["LOG4JL_DEFAULT_STATUS_LEVEL"])")) :
                                               Level.ERROR

    # Default logger context selector
    global const LOG4JL_LOG_EVENT = "LOG4JL_LOG_EVENT" in keys(ENV) ?
                                    eval(parse(ENV["LOG4JL_LOG_EVENT"])) :
                                    Log4jlEvent

    # Default logger context selector
    global const LOG4JL_CONTEXT_SELECTOR = "LOG4JL_CONTEXT_SELECTOR" in keys(ENV) ?
                                           eval(Expr(:call, parse(ENV["LOG4JL_CONTEXT_SELECTOR"]))) :
                                           ModuleContextSelector()
end


end
