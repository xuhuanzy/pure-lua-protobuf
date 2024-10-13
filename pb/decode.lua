local pb_types = require "pb.types"

local stringChar = string.char
local tableUnpack= table.unpack
local tablePack = table.pack
local stringByte = string.byte

---@class PB.Decode
local M = {}

local PB_TBYTES = pb_types.pb_WireType.PB_TBYTES
local PB_TVARINT = pb_types.pb_WireType.PB_TVARINT
local PB_T64BIT = pb_types.pb_WireType.PB_T64BIT
local PB_T32BIT = pb_types.pb_WireType.PB_T32BIT
local PB_TGSTART = pb_types.pb_WireType.PB_TGSTART

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
            type(s) == "string" and tablePack(stringByte(s, 1, len)) or s
        ),
        pos = s and 1 or nil,
        start = s and 1 or nil,
        end_pos = len + 1
    }
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

---@param s pb_Slice
---@return integer
function M.pb_len(s)
    return s.end_pos - s.pos
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
        local byte =s._data[pos]
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
    if M.pb_len(s) >= 10 or (s._data[s.end_pos] & 0x80) == 0 then
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
    if M.pb_len(s) >= 10 or (s._data[s.end_pos] & 0x80) == 0 then
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
    if len == 0 or M.pb_len(s) < value then
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
---@return integer
local function pb_skipbytes(s)
    local pos = s.pos
    local len, value = M.pb_readvarint64(s)
    if len == 0 then
        return 0
    end
    if M.pb_len(s) < value then
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
    elseif switchTag == PB_TBYTES then
        ret = pb_skipbytes(s)
    elseif switchTag == PB_T32BIT then
    elseif switchTag == PB_TGSTART then
    end

    if ret == 0 then
        s.pos = pos
    end
    return ret
end

return M
