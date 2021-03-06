# Log4jl - a versatile logging framework for Julia

[![Build Status](https://travis-ci.org/wildart/Log4jl.jl.svg?branch=master)](https://travis-ci.org/wildart/Log4jl.jl)[![Coverage Status](https://coveralls.io/repos/wildart/Log4jl.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/wildart/Log4jl.jl?branch=master)

**Log4jl** is a comprehensive and flexible logging framework for Julia programs.

## Usage

To create logger call `@Log4jl.logger` macro after importing `Log4jl` module.
This macro call initializes and configures the logging framework. Also it creates logger object which cab be used by any of logging functions or macros to perform logging operations.

```julia
using Log4jl

const logger = @Log4jl.logger

error(logger, "Error in my code")

# or

@Log4jl logger = @Log4jl.logger

@error "Error in my code"
```
See usage in [example/simple.jl](example/simple.jl).


## Logger

In order to create logger instance, call macro `@Log4jl.logger [<name>] [MSG=<message_type>] [URI=<config_location>] [begin <config_code_block> end]`. It accepts following parameters:

1. `name`: a string which specifies a logger name from a configuration
2. `MSG=<message_type>`: a message type used for configuring a logger
3. `URI=<config_location>`: a configuration location
4. `begin <configuration> end`: a configuration program block (must return `Configuration` object)


If the root logger is required use macro `Log4jl.rootlogger` with the same parameters as for `Log4jl.logger` with one exception: root logger does not have a name.

```julia
# get the root logger
const logger = @Log4jl.rootlogger

# get the configured logger by name (uses FQMN by default)
const logger = @Log4jl.logger

# get the configured logger by name explicitly
const logger = @Log4jl.logger "TestLogger"

# get the configured logger by name that will use parameterized messages
const logger = @Log4jl.logger "TestLogger" MSG=ParameterizedMessage

# get the configured logger by from file specified in the parameter
const logger = @Log4jl.logger URI="myconfig.xml"

# get the configured logger from a programmatic configuration
const logger = @Log4jl.logger begin
    Configuration("Custom",
        PROPERTIES(),
        APPENDERS(),
        LOGCONFIGS()
    )
end
```

## Configuration

The default configuration file is `log4jl.*`. An extension of the configuration file determines format in which configuration is described.

Configuration file should be located in:
- For stand-alone module: a directory where a source code file of the module is located.
- For package: a package root directory.

## Log4jl Internal Properties

Log4jl can be configured with properties which can be set through environmental variables.

| Property | Description | Default Value |
|----------|-------------|---------------|
|LOG4JL_LINE_SEPARATOR| Default new line separator sequence | [(0x0d - win) 0x0a] |
|LOG4JL_DEFAULT_STATUS_LEVEL| Default logger status level to use if not specified in configuration. | ERROR |
|LOG4JL_INTERNAL_STATUS_LEVEL| Default status level of internal `Log4jl` logging to use if not specified in configuration. | WARN |
|LOG4JL_LOG_EVENT| Type of the default logger event generator which converts messages into logging events. | Log4jlEvent |
|LOG4JL_CONTEXT_SELECTOR| Type of the default logger context selector. | ModuleContextSelector |

## Logging Separation

There are many well known use cases where applications may share an environment with other applications and each has a need to have its own, separate logging environment.

There are a few ways to archive logging separation using different `ContextSelector` implementations:

- `SingleContextSelector`: This selector creates a single `LoggerContext` using a single configuration that will be shared across all applications.

- `ModuleContextSelector`: This selector creates a one `LoggerContext` per module. This allows each module be configured to share the same configuration or can be individually configured. However, if configuration is not provided or has error then the parent module context is used for the current module. If there exist no parent module then new context is created with default configuration.

Context selection can be done by setting environment variable `LOG4JL_CONTEXT_SELECTOR` with a name of context selector type.

## Custom Log Levels
`Log4jl` supports custom log levels. Custom log levels can be defined in code or in configuration. To define a custom log level in code, use the `Level.add` function. This function creates a new level for the specified name and generates appropriate convenience functions. After a log level is defined you can log messages at this level by calling corresponding log function:

```julia
# This creates the "VERBOSE" level if it does not exist yet.
Log4jl.Level.add(:VERBOSE, 550)

# Create a logger
const logger = @logger

# Use the custom VERBOSE level
Log4jl.verbose(logger, "a verbose message")
```

When defining a custom log level, the intLevel parameter (550 in the example above) determines where the custom level exists in relation to the standard levels built-in to Log4jl. For reference, the table below shows the intLevel of the built-in log levels.

Standard log levels built-in to Log4jl

|Standard Level|intLevel|
|--------------|--------|
|OFF|0|
|FATAL|100|
|ERROR|200|
|WARN|300|
|INFO|400|
|DEBUG|500|
|TRACE|600|
|ALL|typemax(Int16)|

### Defining Custom Log Levels in Configuration

Custom log levels can also be defined in configuration. This is convenient for using a custom level in a logger filter or an appender filter. Similar to defining log levels in code, a custom level must be defined first, before it can be used. If a logger or appender is configured with an undefined level, that logger or appender will be invalid and will not process any log events.

The `customlevels` section of configuration element defines a custom levels. Internally it calls the same `Level.add` function discussed above.

|Parameter Name|   Type|    Description|
|--------------|-------|---------------|
|name|string|The name of the custom level. The convention is to use all upper-case names.|
|intLevel|integer|Determines where the custom level exists in relation to the standard levels built-in to Log4jl (see the table above).|

The following example shows a configuration that defines some custom log levels and uses a custom log level to filter log events sent to the console.
```yaml
configuration:
  status: trace
  name: YAMLTest
  customlevels:
    diag: 350
    verbose: 150

  appenders:
    ColorConsole:
      name: STDOUT

  loggers:
    logger:
      -
        name: X.Y
        level: diag
        appenderref:
          -
            ref: STDOUT
```

## Filters

Filters allow logged `Event`s to be evaluated to determine if or how they should be published. A `Filter` will be called on one of its `filter` methods and will return a `FilterResult`, which is an `Enum` that has one of 3 values:

- `ACCEPT`: no filters called, accept event
- `DENY`: ignore event, return to caller
- `NEUTRAL`: pass event to other filters

Filters may be configured in one of four locations:

- **Context-wide Filters** are configured directly in the configuration. Events that are rejected by these filters will not be passed to loggers for further processing. Once an event has been accepted by a context-wide filter it will not be evaluated by any other context-wide filters nor will the Logger's Level be used to filter the event. The event will be evaluated by logger and appender filters however.
- **Logger Filters** are configured on a specified `Logger`. These are evaluated after the context-wide filters and the log `Level` for the `Logger`. Events that are rejected by these filters will be discarded and the event will not be passed to a parent `Logger` regardless of the additivity setting.
- **Appender Reference Filters** are used to determine if a `Logger` should route the event to an appender.
- **Appender Filters** are used to determine if a specific `Appender` should handle the formatting and publication of the event.


## Dev Notes

### Architecture
[Log4jl](http://github.comwildart/Log4jl.jl) has similar architecture as [Apache Log4j 2](http://logging.apache.org/log4j/2.x/manual/architecture.html) framework.

- Loggers are wrappers around configuration
- Loggers would change behavior if configuration is changed
- Logger hierarchy based on hierarchy of configurations
- Global logger context keeps track of all loggers
- Root logger has no name and additivity, its default level is ERROR
- Logging functions support:
    - plaint text
    - markers
    - objects

### Constants

- `LOG4JL_CONFIG_DEFAULT_PREFIX`: prefix of the configuration file. Default value is 'log4jl'.
- `LOG4JL_CONFIG_EXTS`: Map of configuration file extensions.
- `LOG4JL_CONFIG_TYPES`: Map of configuration types.

### Implementation details
- 'isenabled' checks if logger allowed to process event at specified level

### Missing
- On-fly reconfiguration
- Multi-threading/processing support
- Lookups
- Configuration formats: JSON, XML, TOML
- Handle configuration recursion

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
3. Macro `Log4jl.logger` is called with(out) parameters
    1. Parameters parsed
    2. Context selector is used to create a logging context
    3. Configuration is created
        a. Programmatic configuration is evaluated
        b. Configuration file is located, loaded and parsed
    4. Logging context is initialized with the created configuration
    5. Logging context is started
        1. Shutdown hook is created.
    6. Configuration is started
        1. Configuration is setup (properties and appenders are created)
        2. Configuration is configured (loggers are created and referenced to appenders)
        3. All appenders are started
    7. Logging context used to create a logger wrapper
    8. Logger object is returned
4. Logger object is used in logging functions.

## Shutdown sequence

TODO: proper shutdown when `workspace` is called.