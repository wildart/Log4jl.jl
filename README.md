# Log4jl - a logging framework for Julia

[![Build Status](https://travis-ci.org/wildart/Log4jl.jl.svg?branch=master)](https://travis-ci.org/wildart/Log4jl.jl)[![Coverage Status](https://coveralls.io/repos/wildart/Log4jl.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/wildart/Log4jl.jl?branch=master)

**Log4jl** is a comprehensive and flexible logging framework for Julia programs.

## Usage

A configuration macro `@Log4jl.configure` must be called after importing `Log4jl` module.
Macro call initializes and configures the logging framework. Next, you can create loggers by calling `Log4jl.getLogger` function, and use any of logging functions or macros to perform logging operations.


```julia
using Log4jl
@Log4jl.configure
const logger = Log4jl.getLogger()

error(logger, "Error in my code")

# or

@error "Error in my code"
```

See usage in [example/simple.jl](example/simple.jl).

**Note:** If you use logging macros, make sure that constant `logger` exists in your current module.

## Dev Notes

### Architecture
[Log4jl](http://github.comwildart/Log4jl.jl) has similar architecture as [Apache Log4j 2](http://logging.apache.org/log4j/2.x/manual/architecture.html) framework.

- Loggers are wrappers around configuration
- Loggers would change behavior if configuration is changed
- Logger hierarchy based on hierarchy of configurations
- Global logger context keeps track of all loggers
- Root logger has no name and additivity, its default level is ERROR

### Implementation details
- 'isenabled' checks if logger allowed to process event at specified level

### Missing
- Object life cycle
- On-fly reconfiguration
- Multi-threading support
- Custom log levels
- Filters
    - Accept: no filters called, accept event
    - Deny: ignore event, return to caller
    - Neutral: pass event to other filters
- Lookups
- Markers
- Appended additivity: event processed by logger and all its ancestors.
- Configuration formats: JSON, XML, YAML, DSL (macro based)
- Handle configuration recursion

### Useful packages
- Formating.jl


### Configuration

First, logging infrastructure should be configured. Use `@Log4jl.configure [<config_file> | begin<prog_config>end]`  macro call to run `Log4jl` configuration. This should be the first call after referencing the package.

```julia
using Log4jl

# Configuration will be loaded from default file,
# otherwise default will be used.
@Log4jl.configure

# or

# Configuration will be loaded from file specified in the parameter
@Log4jl.configure "myconfig.xml"

# or

# Configuring a logger context with a programmatic configuration
@Log4jl.configure begin
    Configuration("Custom",
        PROPERTIES(),
        APPENDERS(),
        LOGCONFIGS()
    )
end
```
Macro `@Log4jl.configure` optionally accepts one parameter which could be

- A a configuration file name as a string, or
- A programmatic configuration that defined in `begin...end` block.

The default configuration file is `log4jl.*`. An extension of the configuration file determines format in which configuration is described. Currently supported formats YAML, JSON, XML.

Configuration file should be located in:
- For stand-alone module: a directory where a source code file of the module is located.
- For package: a package root directory.



### Logger

In order to create logger, call macro `@Log4jl.logger [<name>] [<message_type>]`.

```julia
# get the root logger
@Log4jl.rootlogger

# get the configured logger by name (used module name by default)
@Log4jl.logger

# get the configured logger by name explicitly
@Log4jl.logger "TestLogger"

# get the configured logger by name that will use parameterized messages
@Log4jl.logger "TestLogger" ParameterizedMessage
```

Macro `@Log4jl.logger` creates logger instance in current module. The macro accepts following parameters:

1. `name`: a logger name as string from the configuration
2. `message_type`: a message type used in a configured logger

If the root logger is required use macro `@Log4jl.rootlogger`.

### Message

- For custom formated messages, create two functions with the same name and following signatures:
    - <message_type_function>(msg::AbstractString, params...) => Message
    - <message_type_function>(msg::Any) => Message

## Loading sequence

1. Module `Log4jl` is referenced
2. Function `Log4jl.__init__` is called
    1. A logger context selector is initialized as object and assigned to global constant `LOG4JL_CONTEXT_SELECTOR` from an environment variable with the same name. Default context selector type is `Log4jl.ModuleContextSelector`.
    2. Default status level is initialized as `LOG4JL_DEFAULT_STATUS_LEVEL` global constant from an environment variable with the same name.  Default status level is `Log4jl.Level.ERROR`.
    3. A logger event type is is initialized as `LOG4JL_LOG_EVENT` global constant from an environment variable with the same name. Default logger event type is `Log4jl.Log4jlEvent`.
3. Macro `Log4jl.configure` is called with(out) parameters
    1. Configuration is created
        a. Programmatic configuration is evaluated
        b. Configuration file is located, loaded and parsed
    2. Logging context is created for current module using `LOG4JL_CONTEXT_SELECTOR`
    3. Logging context is initialized with the created configuration


