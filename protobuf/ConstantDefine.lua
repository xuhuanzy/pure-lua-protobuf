---@class protobuf.ConstantDefine
local M = {}

-- 定义一个包含 Wire Type 的表
local PB_WIRE_TYPES = {
    { id = "VARINT", name = "varint", fmt = 'v' },
    { id = "64BIT",  name = "64bit",  fmt = 'q' },
    { id = "BYTES",  name = "bytes",  fmt = 's' },
    { id = "GSTART", name = "gstart", fmt = '!' },
    { id = "GEND",   name = "gend",   fmt = '!' },
    { id = "32BIT",  name = "32bit",  fmt = 'd' }
}

-- 用于描述字段在字节流中的编码类型
---@class protobuf.WireType
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
local PB_TYPES = {
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
-- 应用层数据类型, 表示消息中每个字段的逻辑数据类型, 会映射到`WireType`
---@class protobuf.FieldType
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
    for i, v in ipairs(PB_TYPES) do
        pb_FieldType["PB_T" .. v.name] = index
        index = index + 1
    end
    pb_FieldType.PB_TYPECOUNT = index
end


-- 编码模式
---@enum protobuf.EncodeMode
local EncodeMode = {
    -- 默认值, 会自动判断是否使用默认字段. </br>
    -- 对于`proto3`, 默认复制默认值到解码目标表中来, 对于其他则忽略默认值设置
    LPB_DEFDEF = 0,
    -- 将默认值表复制到解码目标表中来
    LPB_COPYDEF = 1,
    -- 将默认值表作为解码目标表的元表使用
    LPB_METADEF = 2,
    -- 忽略默认值
    LPB_NODEF = 3,
}

---@enum protobuf.DefFlags
local DefFlags = {
    -- 使用字段
    USE_FIELD = 1,
    -- 使用重复字段
    USE_REPEAT = 2,
    -- 使用消息类型
    USE_MESSAGE = 4,
}

-- 64位整数模式
---@enum protobuf.Int64Mode
local Int64Mode = {
    -- 如果值的大小小于`uint32`允许的最大值，则存储整数，否则存储Lua浮点数类型或者64位整数.
    LPB_NUMBER = 0,
    -- 同`LPB_NUMBER`, 但返回一个前缀"#"的字符串以避免精度损失
    LPB_STRING = 1,
    -- 同`LPB_NUMBER`, 但返回一个前缀"#"+16进制的字符串
    LPB_HEXSTRING = 2,
}

M.INT_MIN = (-2147483647 - 1)
M.UINT_MAX = 0xffffffff
M.PB_MAX_SIZET = 0xFFFFFFFF - 100

M.pb_WireType = pb_WireType
M.pb_FieldType = pb_FieldType
M.EncodeMode = EncodeMode
M.DefFlags = DefFlags
M.Int64Mode = Int64Mode
M.PB_OK = 0
M.PB_ERROR = 1



return M
