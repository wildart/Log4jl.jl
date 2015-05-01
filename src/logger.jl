type Logger
    name::String
    level::Level.EventLevel
    stream::IO

    Logger(
        name::String=string(current_module()),
        level::Level.EventLevel=Level.DEBUG,
        stream::IO=STDERR
    ) = new(name, level, STDERR)

end
function Base.show(io::IO, logger::Logger)
    print(io, "Logger(", join([logger.name, ", level=", string(logger.level)], ""), ")")
end
