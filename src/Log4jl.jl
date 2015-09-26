module Log4jl

export trace, debug, info, warn, error, fatal
#       @trace, @debug, @info, @warn, @error, @fatal

import Base: append!, serialize, show, in, delete!, string,
             trace, info, warn, error

# To be set parameters
global LOG4JL_LINE_SEPARATOR
global LOG4JL_DEFAULT_STATUS_LEVEL
global LOG4JL_INTERNAL_STATUS_LEVEL
global LOG4JL_LOG_EVENT
global LOG4JL_CONTEXT_SELECTOR

# Imports
include("utils.jl")
include("types.jl")
include("message.jl")
include("event.jl")
include("layouts.jl")
include("appenders.jl")
include("logconfig.jl")
include("config.jl")
include("logger.jl")
include("context.jl")

# Constants
const LOG4JL_DEFAULT_MESSAGE = Messages.ParameterizedMessage
const LOG4JL_CONFIG_DEFAULT_PREFIX = "log4jl"
const LOG4JL_CONFIG_EXTS = Dict(:YAML => [".yaml", ".yml"], :JSON=>[".json", ".jsn"], :LightXML=>[".xml"])
const LOG4JL_CONFIG_PARSER_CALL = "parse_<type>_config"
const ROOT_LOGGER_NAME = NAME()

# Logger methods
for (fn,lvl) in ((:trace, Level.TRACE),
                 (:debug, Level.DEBUG),
                 (:info,  Level.INFO),
                 (:warn,  Level.WARN),
                 (:error, Level.ERROR),
                 (:fatal, Level.FATAL))

    @eval $fn(l::AbstractLogger, fqmn::AbstractString, marker::MARKER, msg, params...) = log(l, fqmn, $lvl, marker, msg, params...)
    @eval $fn(l::AbstractLogger, fqmn::AbstractString, marker::Symbol, msg, params...) = $fn(l, fqmn, MARKER(marker), msg, params...)
    @eval $fn(l::AbstractLogger, fqmn::AbstractString, msg::AbstractString, params...) = $fn(l, fqmn, MARKER(), msg, params...)
    @eval $fn(l::AbstractLogger, marker::MARKER, msg, params...) = $fn(l, string(current_module()), marker, msg, params...)
    @eval $fn(l::AbstractLogger, marker::Symbol, msg, params...) = $fn(l, string(current_module()), MARKER(marker), msg, params...)
    @eval $fn(l::AbstractLogger, msg, params...) = $fn(l, MARKER(), msg, params...)
end


"`logger` macro parameters parser"
function parseargs(params, dn, df=LOG4JL_DEFAULT_MESSAGE)
    config_eval = Nullable{Expr}()
    name = dn
    msgfactory = :($df)
    config_file = Nullable{AbstractString}()

    length(params) > 0 && for p in params
        trace(LOGGER, "Logger arameter: $p, $(typeof(p))")
        if isa(p, AbstractString)
            name = p
        elseif isa(p, Nullable)
            name = get(p, "")
        elseif isa(p, Expr) && p.head == :block
            config_eval = Nullable(p)
            config_file = Nullable{AbstractString}("")
        elseif isa(p, Expr) && (p.head == :(=) || p.head ==:kw)
            if p.args[1] == :URI
                config_file = NAME(p.args[2])
            elseif p.args[1] == :MSG
                msgfactory = p.args[2]
            end
        end
    end

    return name, msgfactory, config_file, config_eval
end


"""Create logger

Creates logger instance. It accepts following parameters:

1. `name`: a logger name as string from the configuration
2. `message_type`: a message type used in a configured logger
3. `configuration`: a configuration location or program
"""
macro logger(params...)
    # get current module and its locations
    cm = current_module()
    cmname = string(cm)
    cmdir = moduledir(cm)

    # println(params)
    # println(map(typeof, params))

    # Parse arguments
    logname, msgfactory, config_file, config_eval = parseargs(params, cmname)

    # Form configuration
    # if isnull(config_eval)
    #     config_loc = joinpath(cmdir, get(config_file, ""))
    #     config_file, parser_type = if isnull(config_file)
    #         searchConfiguration(cmdir)
    #     else
    #         config_loc, findConfigurationParser(config_loc)
    #     end
    #     config_eval = formConfiguration(config_file, parser_type)
    # end

    # Evaluate configuration
    # config = evalConfiguration(config_eval)

    # logger context is initialize and configured
    # ctx = context(LOG4JL_CONTEXT_SELECTOR, cmname,
    #               isnull(config_eval) ? config_file : config_eval)

    # start context if necessary
    # ctx.state == LifeCycle.INITIALIZED && start(ctx)

    # config!(ctx, config)

    # # create logger macros
    # for fn in [:trace, :debug, :info, :warn, :error, :fatal]
    #     @eval macro $fn(msg...)
    #         # get current module `logger` constant
    #         mod = current_module()
    #         fcall = Expr(:call, esc($fn), esc(:logger), string(mod), msg...)
    #         quote
    #             if isdefined($mod, :logger) && isconst($mod, :logger)
    #                 $fcall;
    #             end
    #         end
    #     end
    # end

    # quote
    #     println($name)
    #     println($msgfactory)
    #     println($config_file)
    #     println($config_eval)
    #     println($config)
    # end

    # find context using a module name
    ctx = if isnull(config_eval)
        debug(LOGGER, """Configuration file is $(!isnull(config_file) ? get(config_file) : "not provided")""")
        context(LOG4JL_CONTEXT_SELECTOR, cm, get(config_file, ""))
    else
        context(LOG4JL_CONTEXT_SELECTOR, cm, config_eval)
    end

    # start context if necessary
    ctx.state == LifeCycle.INITIALIZED && start(ctx)

    # return logger
    quote
        logger($ctx, $logname, $msgfactory)
    end
end

macro rootlogger(params...)
    :(@logger $ROOT_LOGGER_NAME $(params...))
end



# Functions
"Loads the `LoggerContext` using the `ContextSelector`."
function getContext(config_file, config_eval)
    # find context using a module name
    ctxname = string(current_module())
    # find context using a module name
    ctx = context(LOG4JL_CONTEXT_SELECTOR, ctxname)
    # start context if necessary
    ctx.state == LifeCycle.INITIALIZED && start(ctx)
    # return context
    return ctx
end

"Returns a `Logger` with the a specified name."
function getLogger(name::NAME=NAME(string(current_module())),
                   msgfactory::FACTORY=FACTORY())
    # empty logger name is a root
    logname = get(name, "")
    # use provided or default message factory
    mf = get(msgfactory, LOG4JL_DEFAULT_MESSAGE)
    # return logger
    return logger(getContext(), logname, mf)
end
getLogger(name::AbstractString, msgfactory::DataType) = getLogger(NAME(name), FACTORY(msgfactory))

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
        config_eval = body[1]
        config_file = "CUSTOM"
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

    # logger context is initialize and configured
    ctx = context(LOG4JL_CONTEXT_SELECTOR, string(cm), config_file == "CUSTOM" ? "" : config_file)
    config!(ctx, config)

    # create logger macros
    for fn in [:trace, :debug, :info, :warn, :error, :fatal]
        @eval macro $fn(msg...)
            # get current module `logger` constant
            mod = current_module()
            fcall = Expr(:call, esc($fn), esc(:logger), string(mod), msg...)
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
    global const LOG4JL_INTERNAL_STATUS_LEVEL = "LOG4JL_INTERNAL_STATUS_LEVEL" in keys(ENV) ?
                                               eval(parse("Level.$(ENV["LOG4JL_INTERNAL_STATUS_LEVEL"])")) :
                                               Level.WARN

    # Default logger context selector
    global const LOG4JL_LOG_EVENT = "LOG4JL_LOG_EVENT" in keys(ENV) ?
                                    eval(parse(ENV["LOG4JL_LOG_EVENT"])) :
                                    Log4jlEvent

    # Default logger context selector
    global const LOG4JL_CONTEXT_SELECTOR = "LOG4JL_CONTEXT_SELECTOR" in keys(ENV) ?
                                           eval(Expr(:call, parse(ENV["LOG4JL_CONTEXT_SELECTOR"]))) :
                                           ModuleContextSelector()

    # Internal status logger
    global const LOGGER = SimpleLogger("StatusLogger", LOG4JL_DEFAULT_MESSAGE, LOG4JL_INTERNAL_STATUS_LEVEL)
    LOGGER.showname = false # do not show
end


end
