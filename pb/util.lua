local ConstantDefine = require("pb.ConstantDefine")

local tool = require "pb.tool"
local meta = tool.meta
local setmetatable = setmetatable

local tablePack = table.pack
local tableUnpack = table.unpack
local stringByte = string.byte
local stringChar = string.char
local type = type


local PB_Tdouble = ConstantDefine.pb_FieldType.PB_Tdouble
local PB_Tfloat = ConstantDefine.pb_FieldType.PB_Tfloat
local PB_Tint64 = ConstantDefine.pb_FieldType.PB_Tint64
local PB_Tuint64 = ConstantDefine.pb_FieldType.PB_Tuint64
local PB_Tint32 = ConstantDefine.pb_FieldType.PB_Tint32
local PB_Tfixed64 = ConstantDefine.pb_FieldType.PB_Tfixed64
local PB_Tfixed32 = ConstantDefine.pb_FieldType.PB_Tfixed32
local PB_Tbool = ConstantDefine.pb_FieldType.PB_Tbool
local PB_Tstring = ConstantDefine.pb_FieldType.PB_Tstring
local PB_Tmessage = ConstantDefine.pb_FieldType.PB_Tmessage
local PB_Tbytes = ConstantDefine.pb_FieldType.PB_Tbytes
local PB_Tuint32 = ConstantDefine.pb_FieldType.PB_Tuint32
local PB_Tenum = ConstantDefine.pb_FieldType.PB_Tenum
local PB_Tsfixed32 = ConstantDefine.pb_FieldType.PB_Tsfixed32
local PB_Tsfixed64 = ConstantDefine.pb_FieldType.PB_Tsfixed64
local PB_Tsint32 = ConstantDefine.pb_FieldType.PB_Tsint32
local PB_Tsint64 = ConstantDefine.pb_FieldType.PB_Tsint64
local PB_Tgroup = ConstantDefine.pb_FieldType.PB_Tgroup

local PB_TBYTES = ConstantDefine.pb_WireType.PB_TBYTES
local PB_TVARINT = ConstantDefine.pb_WireType.PB_TVARINT
local PB_T64BIT = ConstantDefine.pb_WireType.PB_T64BIT
local PB_T32BIT = ConstantDefine.pb_WireType.PB_T32BIT
local PB_TGSTART = ConstantDefine.pb_WireType.PB_TGSTART
local PB_TGEND = ConstantDefine.pb_WireType.PB_TGEND
local PB_TWIRECOUNT = ConstantDefine.pb_WireType.PB_TWIRECOUNT


-- protobuf 工具类
---@class Export.Protobuf.Util
local M = {}


--#region Slice


-- 切片
---@class protobuf.Slice
---@field _data protobuf.Char[]
---@field pos? integer 当前位置
---@field start? integer 起始位置
---@field end_pos? integer 结束位置
---@field stringValue string? 字符串值缓存. 如果该值不为空, 则其他值不应该发生改变
local ProtobufSlice = meta("protobuf.Slice")

---@param data? string|protobuf.Char[]
---@param len? integer
---@return protobuf.Slice
function ProtobufSlice.new(data, len)
    len = len or data and #data or 0
    ---@type protobuf.Slice
    local self = {
        ---@diagnostic disable-next-line: assign-type-mismatch
        _data = data and (
            type(data) == "string" and { stringByte(data, 1, len) } or data
        ),
        start = data and 1 or nil,
        pos = data and 1 or nil,
        end_pos = len + 1,
        stringValue = nil,
    }
    return setmetatable(self, ProtobufSlice)
end

M.ProtobufSlice = ProtobufSlice

--#endregion


---@param s protobuf.Slice
---@return integer
local function pb_len(s)
    return s.end_pos - s.pos
end
M.pb_len = pb_len


---@param s protobuf.Slice
---@return integer
function M.pb_pos(s)
    return s.pos - s.start
end

-- 获取字符串
---@param s protobuf.Slice
---@return string?
function M.getSliceString(s)
    if not s._data then return nil end
    s.stringValue = s.stringValue or stringChar(tableUnpack(s._data, s.pos, s.end_pos - 1))
    return s.stringValue
end

---@param value any
---@return protobuf.Slice
function M.lpb_toslice(value)
    if type(value) == "string" then
        return ProtobufSlice.new(value, #value)
    end
    return ProtobufSlice.new(nil, 0)
end

-- 字节数组转换为`string`
---@param charArray protobuf.Char[]
---@return string
function M.charArrayToString(charArray)
    return stringChar(tableUnpack(charArray))
end

-- 将应用层数据类型映射到`WireType`
---@param type integer
---@return integer
function M.pb_wtypebytype(type)
    if type == PB_Tint64 then
        return PB_TVARINT
    elseif type == PB_Tuint64 then
        return PB_TVARINT
    elseif type == PB_Tint32 then
        return PB_TVARINT
    elseif type == PB_Tfixed64 then
        return PB_T64BIT
    elseif type == PB_Tfixed32 then
        return PB_T32BIT
    elseif type == PB_Tbool then
        return PB_TVARINT
    elseif type == PB_Tstring then
        return PB_TBYTES
    elseif type == PB_Tmessage then
        return PB_TBYTES
    elseif type == PB_Tbytes then
        return PB_TBYTES
    elseif type == PB_Tuint32 then
        return PB_TVARINT
    elseif type == PB_Tdouble then
        return PB_T64BIT
    elseif type == PB_Tfloat then
        return PB_T32BIT
    elseif type == PB_Tenum then
        return PB_TVARINT
    elseif type == PB_Tsfixed32 then
        return PB_T32BIT
    elseif type == PB_Tsfixed64 then
        return PB_T64BIT
    elseif type == PB_Tsint32 then
        return PB_TVARINT
    elseif type == PB_Tsint64 then
        return PB_TVARINT
    else
        return PB_TWIRECOUNT
    end
end

-- 获取基础类型名称
---@param type integer
---@return string
function M.pb_typename(type)
    if type == PB_Tdouble then
        return "double"
    elseif type == PB_Tfloat then
        return "float"
    elseif type == PB_Tint64 then
        return "int64"
    elseif type == PB_Tuint64 then
        return "uint64"
    elseif type == PB_Tint32 then
        return "int32"
    elseif type == PB_Tfixed64 then
        return "fixed64"
    elseif type == PB_Tfixed32 then
        return "fixed32"
    elseif type == PB_Tbool then
        return "bool"
    elseif type == PB_Tstring then
        return "string"
    elseif type == PB_Tgroup then
        return "group"
    elseif type == PB_Tmessage then
        return "message"
    elseif type == PB_Tbytes then
        return "bytes"
    elseif type == PB_Tuint32 then
        return "uint32"
    elseif type == PB_Tenum then
        return "enum"
    elseif type == PB_Tsfixed32 then
        return "sfixed32"
    elseif type == PB_Tsfixed64 then
        return "sfixed64"
    elseif type == PB_Tsint32 then
        return "sint32"
    elseif type == PB_Tsint64 then
        return "sint64"
    else
        return "<unknown>"
    end
end

-- 获取期望的类型
---@param type integer
---@return string
function M.lpb_expected(type)
    if type == PB_Tbool or type == PB_Tdouble or type == PB_Tfloat or type == PB_Tfixed32 or type == PB_Tsfixed32 or type == PB_Tint32 or type == PB_Tuint32 or type == PB_Tsint32 or type == PB_Tfixed64 or type == PB_Tsfixed64 or type == PB_Tint64 or type == PB_Tuint64 or type == PB_Tsint64 or type == PB_Tenum then
        return "number/'#number'"
    elseif type == PB_Tbytes or type == PB_Tstring or type == PB_Tmessage then
        return "string"
    else
        return "unknown"
    end
end

-- 获取`WireType`的名称
---@param wiretype integer
---@return string
function M.pb_wtypename(wiretype)
    if wiretype == PB_TVARINT then
        return "varint"
    elseif wiretype == PB_T64BIT then
        return "64bit"
    elseif wiretype == PB_TBYTES then
        return "bytes"
    elseif wiretype == PB_TGSTART then
        return "gstart"
    elseif wiretype == PB_TGEND then
        return "gend"
    elseif wiretype == PB_T32BIT then
        return "32bit"
    else
        return "unknown"
    end
end

return M
