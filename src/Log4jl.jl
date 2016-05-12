module Log4jl

export trace, debug, info, warn, error, fatal,
       # @trace, @debug, @info, @warn, @error, @fatal,
       @logger, @Log4jl

import Base: append!, serialize, show, in, delete!, string,
             trace, info, warn, error, filter

# To be set parameters
global LOG4JL_LINE_SEPARATOR
global LOG4JL_DEFAULT_STATUS_LEVEL
global LOG4JL_INTERNAL_STATUS_LEVEL
global LOG4JL_LOG_EVENT
global LOG4JL_CONTEXT_SELECTOR
global LOGGER

const LOG4JL_CONFIG_DEFAULT_PREFIX = "log4jl"
const LOG4JL_CONFIG_EXTS = Dict{Symbol, Vector{AbstractString}}()
const LOG4JL_CONFIG_TYPES = Dict{Symbol, DataType}()

# Imports
include("utils.jl")
include("levels.jl")
include("types.jl")
include("messages.jl")
include("event.jl")
include("filter.jl")
include("layouts.jl")
include("appenders.jl")
include("logconfig.jl")
include("config.jl")
include("logger.jl")
include("context.jl")
include("selector.jl")

# Constants
const LOG4JL_DEFAULT_MESSAGE = Messages.ParameterizedMessage
const ROOT_LOGGER_NAME = ""

function makemethods(fn::Symbol, lvl::Level.EventLevel)
    eval(Log4jl, quote
        $fn(l::AbstractLogger, marker::MARKER, msg, params...) = log(l, $lvl, marker, msg, params...)
        $fn(l::AbstractLogger, marker::Symbol, msg, params...) = log(l, $lvl, MARKER(marker), msg, params...)
        $fn(l::AbstractLogger, msg, params...)                 = log(l, $lvl, msg, params...)
    end)
end

# Logger methods
for (fn,lvl) in ((:trace, Level.TRACE),
                 (:debug, Level.DEBUG),
                 (:info,  Level.INFO),
                 (:warn,  Level.WARN),
                 (:error, Level.ERROR),
                 (:fatal, Level.FATAL))
    makemethods(fn, lvl)
end

"`logger` macro parameters parser"
function parseargs(params, cmname, defmsg=LOG4JL_DEFAULT_MESSAGE)
    config_eval = Nullable{Expr}()
    name = cmname
    msgfactory = :($defmsg)
    config_file = Nullable{AbstractString}()

    length(params) > 0 && for p in params
        trace(LOGGER, "Logger parameter: $p, $(typeof(p))")
        if isa(p, AbstractString)
            name = p
        elseif isa(p, Expr) && p.head == :block
            config_eval = Nullable(p)
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
2. `MSG=<message_type>`: a message type used in a configured logger
3. `URI=<config_location>`: a configuration location
4. `begin <configuration> end`: a configuration program (must return `Configuration` object)
"""
macro logger(params...)
    # get current module and its locations
    cm = current_module()
    cmname = string(cm)
    cmdir = moduledir(cm)

    # Parse arguments
    logname, msgfactory, config_file, config_eval = parseargs(params, cmname)

    # find context using a module name
    ctx = getcontext(cmname, cfgloc = config_file, cfgexp = config_eval)

    # return logger
    quote
        logger($ctx, $logname, $msgfactory)
    end
end

macro rootlogger(params...)
    :(@logger $ROOT_LOGGER_NAME $(params...))
end

""" This macro is used to define logger macros for the specified logger: @info, @error, etc.

Macro take a logger assignment expression and creates a variety of macros for the created logger.
```julia
    @Log4jl LOG = @logger # Create logger `LOG` and corresponding macros
    @info "AAA"           # All calls will be made with `LOG` logger
```
"""
macro Log4jl(expr)
    lvar = expr.args[1]
    rval = expr.args[2]
    mod = current_module()
    for fn in [:trace, :debug, :info, :warn, :error, :fatal]
        eval(mod, :( macro $fn(msg...)
            Expr(:call, esc($fn), $lvar, msg...)
        end))
    end
    :(const $(esc(lvar)) = $rval)
end

macro register(lvar)
    mod = current_module()
    for fn in [:trace, :debug, :info, :warn, :error, :fatal]
        eval(mod, :( macro $fn(msg...)
            Expr(:call, esc($fn), $lvar, msg...)
        end))
    end
    :()
end


"Return logging context by name"
function getcontext(ctxname::AbstractString;
                    cfgloc::Nullable{AbstractString}=Nullable{AbstractString}(),
                    cfgexp::Nullable{Expr}=Nullable{Expr}())

    debug(LOGGER, """Configuration file is $(get(cfgloc, "not provided"))""")

    # get context (and set configuration location if available)
    ctx = context(LOG4JL_CONTEXT_SELECTOR, ctxname, get(cfgloc, ""))

    # start context if necessary
    if ctx.state == LifeCycle.INITIALIZED
        # configuration defined as expression
        if !isnull(cfgexp)
            debug(LOGGER, "Evaluating configuration block")
            cfg = evalConfiguration(cfgexp)
            start(ctx, cfg)
        elseif !isnull(cfgloc)
            cfg = getconfig(get(cfgloc), ctxname)
            start(ctx, cfg)
        else
            start(ctx)
        end
    end

    return ctx
end

"Shutdown logging system by stopping all logger contexts"
function shutdown()
    for (ctxname, ctx) in Log4jl.contexts(Log4jl.LOG4JL_CONTEXT_SELECTOR)
        stop(ctx)
    end
end

function __init__()
    # Default line separator
    global const LOG4JL_LINE_SEPARATOR = "LOG4JL_LINE_SEPARATOR" in keys(ENV) ?
                                         convert(Vector{UInt8}, ENV["LOG4JL_LINE_SEPARATOR"]) :
                                         @windows? [0x0d, 0x0a] : [0x0a]
    eval(Layouts, parse("import ..Log4jl.LOG4JL_LINE_SEPARATOR"))

    # Default logger status level
    global const LOG4JL_DEFAULT_STATUS_LEVEL = "LOG4JL_DEFAULT_STATUS_LEVEL" in keys(ENV) ?
                                               get(getlevel(ENV["LOG4JL_DEFAULT_STATUS_LEVEL"]), Level.ERROR) :
                                               Level.ERROR

    # Default internal logger status level
    global const LOG4JL_INTERNAL_STATUS_LEVEL = "LOG4JL_INTERNAL_STATUS_LEVEL" in keys(ENV) ?
                                               get(getlevel(ENV["LOG4JL_INTERNAL_STATUS_LEVEL"]), Level.WARN) :
                                               Level.WARN

    # Default logger event generator
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
