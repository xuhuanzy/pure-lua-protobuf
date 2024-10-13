-- 定义一个包含 Wire Type 的表
local PB_WIRE_TYPES = {
    { id = "VARINT", name = "varint", fmt = 'v' },
    { id = "64BIT",  name = "64bit",  fmt = 'q' },
    { id = "BYTES",  name = "bytes",  fmt = 's' },
    { id = "GSTART", name = "gstart", fmt = '!' },
    { id = "GEND",   name = "gend",   fmt = '!' },
    { id = "32BIT",  name = "32bit",  fmt = 'd' }
}

---@class pb_WireType
---@field PB_TVARINT integer
---@field PB_T64BIT integer
---@field PB_TBYTES integer
---@field PB_TGSTART integer
---@field PB_TGEND integer
---@field PB_T32BIT integer
---@field PB_TWIRECOUNT integer
local pb_WireType = {
}
do
    local index = 0
    for i, v in ipairs(PB_WIRE_TYPES) do
        pb_WireType["PB_T" .. v.id] = index
        index = index + 1
    end
    pb_WireType.PB_TWIRECOUNT = index
end

-- 定义一个包含 Field Type 的表
local PB_FIELD_TYPES = {
    { name = "double",   type = "double",   fmt = 'F' },
    { name = "float",    type = "float",    fmt = 'f' },
    { name = "int64",    type = "int64",    fmt = 'I' },
    { name = "uint64",   type = "uint64",   fmt = 'U' },
    { name = "int32",    type = "int32",    fmt = 'i' },
    { name = "fixed64",  type = "fixed64",  fmt = 'X' },
    { name = "fixed32",  type = "fixed32",  fmt = 'x' },
    { name = "bool",     type = "bool",     fmt = 'b' },
    { name = "string",   type = "string",   fmt = 't' },
    { name = "group",    type = "group",    fmt = 'g' },
    { name = "message",  type = "message",  fmt = 'S' },
    { name = "bytes",    type = "bytes",    fmt = 's' },
    { name = "uint32",   type = "uint32",   fmt = 'u' },
    { name = "enum",     type = "enum",     fmt = 'v' },
    { name = "sfixed32", type = "sfixed32", fmt = 'y' },
    { name = "sfixed64", type = "sfixed64", fmt = 'Y' },
    { name = "sint32",   type = "sint32",   fmt = 'j' },
    { name = "sint64",   type = "sint64",   fmt = 'J' }
}

---@class pb_FieldType
---@field PB_TNONE integer
---@field PB_Tdouble integer
---@field PB_Tfloat integer
---@field PB_Tint64 integer
---@field PB_Tuint64 integer
---@field PB_Tint32 integer
---@field PB_Tfixed64 integer
---@field PB_Tfixed32 integer
---@field PB_Tbool integer
---@field PB_Tstring integer
---@field PB_Tgroup integer
---@field PB_Tmessage integer
---@field PB_Tbytes integer
---@field PB_Tuint32 integer
---@field PB_Tenum integer
---@field PB_Tsfixed32 integer
---@field PB_Tsfixed64 integer
---@field PB_Tsint32 integer
---@field PB_Tsint64 integer
---@field PB_TYPECOUNT integer
local pb_FieldType = {}
do
    local index = 0

    pb_FieldType.PB_TNONE = index
    index = index + 1
    for i, v in ipairs(PB_FIELD_TYPES) do
        pb_FieldType["PB_T" .. v.name] = index
        index = index + 1
    end
    pb_FieldType.PB_TYPECOUNT = index
end


---@class Protobuf.ConstantDefine
return {
    pb_WireType = pb_WireType,
    pb_FieldType = pb_FieldType,
    PB_OK = 0,
    PB_ERROR = 1,
}
