local ConstantDefine = require("pb.ConstantDefine")

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


---@param s string?
---@return pb_Slice
function M.pb_slice(s)
    if s then
        return M.pb_lslice(s, #s)
    else
        return M.pb_lslice(nil, 0)
    end
end

---@param s? string|Protobuf.Char[]
---@param len integer
---@return pb_Slice
function M.pb_lslice(s, len)
    ---@type pb_Slice
    return {
        ---@diagnostic disable-next-line: assign-type-mismatch
        _data = s and (
            type(s) == "string" and {stringByte(s, 1, len)} or s
        ),
        pos = s and 1 or nil,
        start = s and 1 or nil,
        end_pos = len + 1
    }
end

---@param s pb_Slice
---@return integer
function M.pb_len(s)
    return s.end_pos - s.pos
end


---@param s pb_Slice
---@return integer
function M.pb_pos(s)
    return s.pos - s.start
end

-- 获取字符串
---@param s pb_Slice
---@return string?
function M.getSliceString(s)
    return s._data and stringChar(tableUnpack(s._data, s.pos, s.end_pos - 1))
end

-- 复制`Slice`, 返回`.pos`到`.end_pos`的数据
---@param s pb_Slice
---@return pb_Slice
function M.sliceCopy(s)
    local newData = tablePack(tableUnpack(s._data, s.pos, s.end_pos - 1))
    return M.pb_lslice(newData, M.pb_len(s))
end


---@param value any
---@return pb_Slice
function M.lpb_toslice(value)
    if type(value) == "string" then
        return M.pb_lslice(value, #value)
    end
    return M.pb_slice(nil)
end

-- 将应用层数据类型映射到`WireType`
---@param type integer
---@return integer
function M.pb_wtypebytype(type)
    if type == PB_Tdouble then
        return PB_T64BIT
    elseif type == PB_Tfloat then
        return PB_T32BIT
    elseif type == PB_Tint64 then
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
