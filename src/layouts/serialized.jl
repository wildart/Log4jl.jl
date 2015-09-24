""" Julia serialization format layout

Formats a `Event` object in its Julia serialized form.
"""
type SerializedLayout <: Layout
end

SerializedLayout(conf::Dict) = SerializedLayout()

# Interface implementation
header(lyt::SerializedLayout) = UInt8[]

footer(lyt::SerializedLayout) = UInt8[]

contenttype(lyt::SerializedLayout) = "application/octet-stream"

function serialize(lyt::SerializedLayout, evnt::Event)
    iob = IOBuffer()
    serialize(io, evnt)
    return takebuf_array(iob)
end