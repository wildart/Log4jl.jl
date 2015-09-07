# Log4jl

[![Build Status](https://travis-ci.org/wildart/Log4jl.jl.svg?branch=master)](https://travis-ci.org/wildart/Log4jl.jl)

# Links
(http://logging.apache.org/log4j/2.x/manual/architecture.html)
(http://logging.apache.org/log4j/2.x/log4j-api/apidocs/index.html)
(http://grepcode.com/snapshot/repo1.maven.org/maven2/org.apache.logging.log4j/log4j-core/2.1/)
(http://grepcode.com/snapshot/repo1.maven.org/maven2/org.apache.logging.log4j/log4j-api/2.1/)

## Dev Notes

### Design
- Loggers are wrappers around configuration
- Loggers would change behavior if configuration is changed.
- Logger hierarchy based on hierarchy of configurations
- Global logger context keeps track of all loggers
- ERROR is default level of root logger
- Root logger has no name and additivity
- For custom formated messages, create two functions with the same name and following signatures:
  - <message_type_function>(msg::AbstractString, params...) => Message
  - <message_type_function>(msg::Any) => Message

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

### Use
- Formating.jl


### Configuration
```julia
using Log4jl

# default call
@Log4jl.configure

# Configuring a logger context with a programmatic configuration
@Log4jl.configure level=Log4jl.Level.DEBUG begin
    Configuration("Custom",
        PROPERTIES(),
        APPENDERS(),
        LOGCONFIGS()
    )
end
```
Macro `@Log4jl.configure` accepts keyword arguments and a programmatic configuration.

- There are following keyword arguments:
    - `config`: Location of the configuration file.
    - `level`: Logging status level
    - `event`: Defines event class

- A programmatic configuration can be defined in `begin...end` block that is passed as a last parameter.


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


## Loading sequence

1. `Log4jl` module is referenced
2. `Log4jl.__init__` is called
    1. Context selector initialized as `LOG4JL_CONTEXT_SELECTOR` constant from environment variable with the same name.
