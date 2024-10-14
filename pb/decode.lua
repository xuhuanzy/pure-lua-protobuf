local pb_types = require "pb.ConstantDefine"
local util = require("pb.util")

local stringChar = string.char
local tableUnpack = table.unpack
local tablePack = table.pack
local stringByte = string.byte

---@class PB.Decode
local M = {}

local PB_TBYTES = pb_types.pb_WireType.PB_TBYTES
local PB_TVARINT = pb_types.pb_WireType.PB_TVARINT
local PB_T64BIT = pb_types.pb_WireType.PB_T64BIT
local PB_T32BIT = pb_types.pb_WireType.PB_T32BIT
local PB_TGSTART = pb_types.pb_WireType.PB_TGSTART
local PB_TGEND = pb_types.pb_WireType.PB_TGEND
local PB_TWIRECOUNT = pb_types.pb_WireType.PB_TWIRECOUNT

local PB_Tdouble = pb_types.pb_FieldType.PB_Tdouble
local PB_Tfloat = pb_types.pb_FieldType.PB_Tfloat
local PB_Tint64 = pb_types.pb_FieldType.PB_Tint64
local PB_Tuint64 = pb_types.pb_FieldType.PB_Tuint64
local PB_Tint32 = pb_types.pb_FieldType.PB_Tint32
local PB_Tfixed64 = pb_types.pb_FieldType.PB_Tfixed64
local PB_Tfixed32 = pb_types.pb_FieldType.PB_Tfixed32
local PB_Tbool = pb_types.pb_FieldType.PB_Tbool
local PB_Tstring = pb_types.pb_FieldType.PB_Tstring
local PB_Tmessage = pb_types.pb_FieldType.PB_Tmessage
local PB_Tbytes = pb_types.pb_FieldType.PB_Tbytes
local PB_Tuint32 = pb_types.pb_FieldType.PB_Tuint32
local PB_Tenum = pb_types.pb_FieldType.PB_Tenum
local PB_Tsfixed32 = pb_types.pb_FieldType.PB_Tsfixed32
local PB_Tsfixed64 = pb_types.pb_FieldType.PB_Tsfixed64
local PB_Tsint32 = pb_types.pb_FieldType.PB_Tsint32
local PB_Tsint64 = pb_types.pb_FieldType.PB_Tsint64




---@alias Protobuf.Char integer

---@class pb_Slice
-- -@field data string? 数据
---@field _data Protobuf.Char[]
---@field pos? integer 当前位置
---@field start? integer 起始位置
---@field end_pos integer 结束位置

function M.pb_gettype(v)
    return (v) & 7
end

function M.pb_gettag(v)
    return (v) >> 3
end

function M.pb_pair(tag, type)
    return (tag) << 3 | ((type) & 7)
end



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

-- 慢速逐字节读取, 返回值为64位整数
---@param s pb_Slice
---@return integer @ 读取到的字节数
---@return integer? @ 读取到的值
local function pb_readvarint_slow(s)
    local pos = s.pos
    local n = 0
    local i = 0
    local ret_val = nil
    while (s.pos < s.end_pos and i < 10) do
        local b = s._data[pos]
        pos = pos + 1
        n = n | ((b & 0x7F) << (i * 7))
        i = i + 1
        if (b & 0x80) == 0 then -- 如果当前字节的最高位是 0，表示 varint 读取结束
            ret_val = n
            return i, ret_val
        end
    end
    s.pos = pos -- 如果读取失败，重置指针
    return 0, nil
end


-- 备用路径，逐字节读取 varint
---@param s pb_Slice
---@return integer @ 读取到的字节数
---@return integer? @ 读取到的值
local function pb_readvarint32_fallback(s)
    local pos = s.pos
    local o = pos
    local result = 0
    local shift = 0
    while (shift < 32 and pos < s.end_pos) do
        local byte = s._data[pos]
        pos = pos + 1
        result = result | ((byte & 0x7F) << shift) -- 合并低7位
        if (byte & 0x80) == 0 then                 -- 最高位为0，说明已经读完
            s.pos = pos
            return pos - o, result
        end
        shift = shift + 7 -- 每次读取7位，因此位移7
    end
    return 0, nil
end

-- 备用路径，逐字节读取 varint
---@param s pb_Slice
---@return integer @ 读取到的字节数
---@return integer? @ 读取到的值
local function pb_readvarint64_fallback(s)
    local pos = s.pos
    local o = pos
    local result = 0
    local shift = 0
    while true do
        local byte = s._data[pos]
        pos = pos + 1
        result = result | ((byte & 0x7F) << shift) -- 合并低7位
        if (byte & 0x80) == 0 then                 -- 最高位为0，说明已经读完
            break
        end
        shift = shift + 7 -- 每次读取7位，因此位移7
        if shift >= 64 then
            return 0, nil -- 避免溢出
        end
    end
    s.pos = pos
    return pos - o, result
end

---@param s pb_Slice
---@return integer @读取到的字节数
---@return integer? @读取到的值
function M.pb_readvarint32(s)
    ---@type integer?
    local ret_val = nil
    local ret_num = 0

    --  检查是否已经到达切片的末尾
    if s.pos >= s.end_pos then
        return 0
    end
    -- 如果最高位为0，说明该字节是最后一个字节，直接返回
    if (s._data[s.pos] & 0x80) == 0 then
        ret_val = s._data[s.pos]
        s.pos = s.pos + 1
        return 1, ret_val
    end
    if util.pb_len(s) >= 10 or (s._data[s.end_pos] & 0x80) == 0 then
        return pb_readvarint32_fallback(s)
    end

    -- 否则使用慢速路径读取, 返回值为64位整数
    ret_num, ret_val = pb_readvarint_slow(s)
    if ret_num ~= 0 then
        ret_val = ret_val & 0xFFFFFFFF -- 转为32位整数
    end
    return ret_num, ret_val
end

---@param s pb_Slice
---@return integer @读取到的字节数
---@return integer? @读取到的值
function M.pb_readvarint64(s)
    --  检查是否已经到达切片的末尾
    if s.pos >= s.end_pos then
        return 0
    end
    ---@type integer?
    local ret_val = nil
    -- 如果最高位为0，说明该字节是最后一个字节，直接返回
    if (s._data[s.pos] & 0x80) == 0 then
        ret_val = s._data[s.pos]
        s.pos = s.pos + 1
        return 1, ret_val
    end
    if util.pb_len(s) >= 10 or (s._data[s.end_pos] & 0x80) == 0 then
        return pb_readvarint64_fallback(s)
    end
    return pb_readvarint_slow(s)
end

---@param s pb_Slice
---@param pv pb_Slice
---@return integer
function M.pb_readbytes(s, pv)
    local pos = s.pos
    -- 1. 读取 varint 编码的长度值
    local len, value = M.pb_readvarint64(s)
    if len == 0 or util.pb_len(s) < value then
        s.pos = pos
        return 0
    end
    -- 2. 如果长度足够，设置 pv 的 start, pos, 和 end_pos
    pv._data = s._data
    pv.pos = s.pos
    pv.start = s.start
    pv.end_pos = s.pos + value

    s.pos = pv.end_pos
    return s.pos - pos
end

---@param s pb_Slice
---@return integer
local function pb_skipvarint(s)
    local pos = s.pos
    local op = pos
    while pos < s.end_pos and (s._data[pos] & 0x80) ~= 0 do
        pos = pos + 1
    end
    if pos >= s.end_pos then
        return 0
    end
    pos = pos + 1
    s.pos = pos
    return pos - op
end

---@param s pb_Slice
---@param len integer
---@return integer
local function pb_skipslice(s, len)
    if s.pos + len > s.end_pos then return 0 end
    s.pos = s.pos + len
    return len
end

---@param s pb_Slice
---@param tag integer
---@param pv pb_Slice
---@return integer
local function pb_readgroup(s, tag, pv)
    local pos = s.pos
    assert(M.pb_gettype(tag) == PB_TGSTART)
    while true do
        local count, newtag = M.pb_readvarint32(s)
        if count == 0 then break end ---@cast newtag integer
        if M.pb_gettype(newtag) == PB_TGEND then
            if M.pb_gettag(newtag) ~= M.pb_gettag(tag) then break end
            pv._data = s._data
            pv.pos = s.pos
            pv.start = s.start
            pv.end_pos = s.pos - count
            return s.pos - pos
        end
        if M.pb_skipvalue(s, newtag) == 0 then break end
    end
    s.pos = pos
    return 0
end

---@param s pb_Slice
---@return integer
local function pb_skipbytes(s)
    local pos = s.pos
    local len, value = M.pb_readvarint64(s)
    if len == 0 then
        return 0
    end
    if util.pb_len(s) < value then
        s.pos = pos
        return 0
    end
    s.pos = s.pos + value
    return s.pos - pos
end

---@param s pb_Slice
---@param tag integer
---@return integer
function M.pb_skipvalue(s, tag)
    local pos = s.pos
    local ret = 0
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local data = {}
    local switchTag = M.pb_gettype(tag)
    --TODO 处理其他类型
    if switchTag == PB_TVARINT then
        ret = pb_skipvarint(s)
    elseif switchTag == PB_T64BIT then
        ret = pb_skipslice(s, 8)
    elseif switchTag == PB_TBYTES then
        ret = pb_skipbytes(s)
    elseif switchTag == PB_T32BIT then
        ret = pb_skipslice(s, 4)
    elseif switchTag == PB_TGSTART then
        ret = pb_readgroup(s, tag, data)
    end
    if ret == 0 then
        s.pos = pos
    end
    return ret
end

return M
