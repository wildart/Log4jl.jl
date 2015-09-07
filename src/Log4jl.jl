module Log4jl

    export Level,
               Message, format, formatted, parameters
               #Logger, level,
               #Appender, name, layout, append!, @appender, @name

    include("utils.jl")
    include("types.jl")
    include("message.jl")
    include("event.jl")
    # include("layouts.jl")
    # include("appenders.jl")
    include("config.jl")
    try
        eval(:(using YAML))
        include("config/yaml.jl")
    catch
    end
    try
        eval(:(using JSON))
        include("config/json.jl")
    catch
    end
    try
        eval(:(using LightXML))
        include("config/xml.jl")
    catch
    end
    include("logger.jl")
    include("context.jl")

    function getLogger(name::AbstractString="",
                                    fqmn::AbstractString=string(current_module()),
                                    msgfact::MSGFACTORY=MSGFACTORY()
                                   )
        ctx = context(LOG4JL_CONTEXT_SELECTOR, fqmn)
        return ctx
        #return logger(ctx, name, msgfact)
    end
    getRootLogger() = getLogger()

    const DEFAULT_PREFIX = "log4jl"

    macro configure(body...)
        cm = current_module()
        cm_path = moduledir(cm)
        println("Log4jl-configure:", cm)
        println("Log4jl-configure:", cm_path)

        local config_file = ""
        local level = Level.ERROR
        local event = Log4jlEvent

        # parse macro parameters
        for expr in body
            if expr.head == :kw

            elseif expr.head == :block


                break # block should be the last parameter
            end

            println(expr.args)
        end

        #==
        1) Log4jl will look for "log4jl.yaml" or "log4jl.yml" if YAML module is loaded, and will attempt to load the configuration
        2) If a YAML file cannot be located, and if JSON module is loaded, attempt to load the configuration from "log4jl.json" or "log4jl.jsn" files
        3) If a JSON file cannot be located, and if XML module is loaded, attempt to load the configuration from "log4jl.xml" file
        4) If no configuration file could be located the default configuration will be used. This will cause logging output to go to the console.
        ==#
        config = if isdefined(:YAML)
            config_file = joinpath(cm_path, DEFAULT_PREFIX*".yaml")
            if !isfile(config_file)
                config_file = joinpath(cm_path, DEFAULT_PREFIX*".yml")
            end
            isfile(config_file) ? parse_yaml_config(config_file) : nothing
        elseif isdefined(:JSON)
            config_file = joinpath(cm_path, DEFAULT_PREFIX*".json")
            if !isfile(config_file)
                config_file = joinpath(cm_path, DEFAULT_PREFIX*".jsn")
            end
            isfile(config_file) ? parse_json_config(config_file) : nothing
        elseif isdefined(:LightXML)
            config_file = joinpath(cm_path, DEFAULT_PREFIX*".xml")
            isfile(config_file) ? parse_xml_config(config_file) : nothing
        end

        if config === nothing
            config = DefaultConfiguration
        end
        println(config)

        # initialize logger context
        # load configuration
        # create root logger
    end

    function __init__()
        # Default logger context selector
        if "LOG4JL_CONTEXT_SELECTOR" ∉ keys(ENV)
            ENV["LOG4JL_CONTEXT_SELECTOR"] = "Log4jl.ModuleContextSelector"
        end

        global const LOG4JL_CONTEXT_SELECTOR = eval(Expr(:call, parse(ENV["LOG4JL_CONTEXT_SELECTOR"] )))
    end

end
