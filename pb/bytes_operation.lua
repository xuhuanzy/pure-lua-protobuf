--#region 导入区
local pb_len = require("pb.util").pb_len
local pb_pos = require("pb.util").pb_pos
local getSliceString = require("pb.util").getSliceString

local pb_decode_sint32 = require("pb.tool").pb_decode_sint32
local pb_decode_sint64 = require("pb.tool").pb_decode_sint64
local pb_decode_double = require("pb.tool").pb_decode_double
local pb_decode_float = require("pb.tool").pb_decode_float


local ConstantDefine = require("pb.ConstantDefine")

local PB_TBYTES = ConstantDefine.pb_WireType.PB_TBYTES
local PB_TVARINT = ConstantDefine.pb_WireType.PB_TVARINT
local PB_T64BIT = ConstantDefine.pb_WireType.PB_T64BIT
local PB_T32BIT = ConstantDefine.pb_WireType.PB_T32BIT
local PB_TGSTART = ConstantDefine.pb_WireType.PB_TGSTART
local PB_TGEND = ConstantDefine.pb_WireType.PB_TGEND
local PB_TWIRECOUNT = ConstantDefine.pb_WireType.PB_TWIRECOUNT

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


local LPB_NUMBER = ConstantDefine.Int64Mode.LPB_NUMBER
local LPB_HEXSTRING = ConstantDefine.Int64Mode.LPB_HEXSTRING
local LPB_STRING = ConstantDefine.Int64Mode.LPB_STRING

local PB_MAX_SIZET = ConstantDefine.PB_MAX_SIZET
local INT_MIN = ConstantDefine.INT_MIN
local UINT_MAX = ConstantDefine.UINT_MAX



local tableInsert = table.insert
local assert = assert
local type = type
local mathType = math.type
local stringPack = string.pack
local stringUnpack = string.unpack
local stringByte = string.byte
local ipairs = ipairs
local pairs = pairs

--#endregion


---@class protobuf.BytesOperation
local M = {}

--#region 写入

---@param buff protobuf.Char[]
---@param n integer
---@return integer @写入的字节数
local function pb_write32(buff, n)
    local c = 0
    local writeIndex = #buff + 1
    while n >= 0x80 do
        buff[writeIndex + c] = (n & 0x7F) | 0x80
        n = n >> 7
        c = c + 1
    end
    buff[writeIndex + c] = n
    return c + 1
end

---@param buff protobuf.Char[]
---@param n integer
---@return integer
local function pb_write64(buff, n)
    local c = 0
    local writeIndex = #buff + 1
    while n >= 0x80 do
        buff[writeIndex + c] = (n & 0x7F) | 0x80
        n = n >> 7
        c = c + 1
    end
    buff[writeIndex + c] = n
    return c + 1
end

---@param b protobuf.Char[]
---@param n integer
---@return integer
local function pb_addvarint32(b, n)
    if not b then return 0 end
    return pb_write32(b, n)
end

---@param b protobuf.Char[]
---@param n integer
---@return integer
local function pb_addvarint64(b, n)
    if not b then return 0 end
    return pb_write64(b, n)
end



---@param b protobuf.Char[]
---@param n integer
---@return integer
local function pb_addfixed32(b, n)
    local writeIndex = #b + 1
    for i = 0, 3 do
        b[writeIndex + i] = n & 0xFF
        n = n >> 8
    end
    return 8
end

---@param b protobuf.Char[]
---@param n integer
---@return integer
local function pb_addfixed64(b, n)
    local writeIndex = #b + 1
    for i = 0, 7 do
        b[writeIndex + i] = n & 0xFF
        n = n >> 8
    end
    return 8
end

---@param b protobuf.Char[]
---@param s protobuf.Slice
---@return integer
local function pb_addslice(b, s)
    local len = pb_len(s)
    local writeIndex = #b
    for i = 1, len do
        b[writeIndex + i] = s._data[s.pos + i - 1]
    end
    return len
end

-- 添加字节
---@param b protobuf.Char[]
---@param s protobuf.Slice
---@return integer
local function pb_addbytes(b, s)
    local len = pb_len(s)
    local ret = pb_addvarint32(b, len)
    return ret + pb_addslice(b, s)
end

---@param targetCharArray protobuf.Char[] 缓冲区
---@param beforeLength integer 前面的有效字节长度(包含预分配的长度)
---@param prealloc integer 预分配长度
---@return integer @返回`写入的长度` + `剩余有效字节的长度`
local function pb_addlength(targetCharArray, beforeLength, prealloc)
    local curLength = #targetCharArray
    if curLength < beforeLength then
        return 0
    end
    ---@type protobuf.Char[]
    local newBuff = {}
    local ml = pb_write64(newBuff, curLength - beforeLength)
    assert(ml >= prealloc) -- 预分配长度必须小于等于ml
    -- 先替换预分配的内容
    local count = 1
    for _ = 1, prealloc do
        targetCharArray[beforeLength - (count - 1)] = newBuff[count]
        count = count + 1
    end
    -- 再插入剩余的内容
    local insertIndexCount = 1
    for i = count, ml do
        tableInsert(targetCharArray, beforeLength + insertIndexCount, newBuff[i])
        insertIndexCount = insertIndexCount + 1
    end

    -- `curLength - beforeLength`: 剩余的有效字节长度
    return ml + (curLength - beforeLength)
end


---@param targetCharArray protobuf.Char[] 缓冲区
---@param beforeLength integer 前面的有效字节长度
---@param prealloc integer 预分配长度
---@return integer @返回`写入的长度` + `剩余有效字节的长度`
local function lpb_addlength(targetCharArray, beforeLength, prealloc)
    local wlen = pb_addlength(targetCharArray, beforeLength, prealloc)
    if wlen == 0 or wlen == nil then
        error("encode bytes fail")
    end
    return wlen
end

--#endregion



--#region 读取

-- 提前声明

local pb_skipvalue


---@param v integer
---@return integer
local function pb_gettype(v)
    return (v) & 7
end

---@param v integer
---@return integer
local function pb_gettag(v)
    return (v) >> 3
end

---生成`tag`
---@param tag integer
---@param type integer
---@return integer
local function pb_pair(tag, type)
    return (tag) << 3 | ((type) & 7)
end



-- 慢速逐字节读取, 返回值为64位整数
---@param s protobuf.Slice
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
---@param s protobuf.Slice
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
---@param s protobuf.Slice
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

---@param s protobuf.Slice
---@return integer @读取到的字节数
---@return integer? @读取到的值
local function pb_readvarint32(s)
    --  检查是否已经到达切片的末尾
    if s.pos >= s.end_pos then
        return 0
    end
    ---@type integer?
    local ret_val = nil
    local ret_num = 0

    local _data = s._data

    -- 如果最高位为0，说明该字节是最后一个字节，直接返回
    if (_data[s.pos] & 0x80) == 0 then
        ret_val = _data[s.pos]
        s.pos = s.pos + 1
        return 1, ret_val
    end
    if pb_len(s) >= 10 or (_data[s.end_pos] & 0x80) == 0 then
        return pb_readvarint32_fallback(s)
    end

    -- 否则使用慢速路径读取, 返回值为64位整数
    ret_num, ret_val = pb_readvarint_slow(s)
    if ret_num ~= 0 then
        ret_val = ret_val & 0xFFFFFFFF -- 转为32位整数
    end
    return ret_num, ret_val
end

---@param s protobuf.Slice
---@return integer @读取到的字节数
---@return integer? @读取到的值
local function pb_readvarint64(s)
    --  检查是否已经到达切片的末尾
    if s.pos >= s.end_pos then
        return 0
    end
    ---@type integer?
    local ret_val = nil
    local _data = s._data
    -- 如果最高位为0，说明该字节是最后一个字节，直接返回
    if (_data[s.pos] & 0x80) == 0 then
        ret_val = _data[s.pos]
        s.pos = s.pos + 1
        return 1, ret_val
    end
    if pb_len(s) >= 10 or (_data[s.end_pos - 1] & 0x80) == 0 then
        return pb_readvarint64_fallback(s)
    end
    return pb_readvarint_slow(s)
end


---@param s protobuf.Slice
---@return integer len 读取到的字节数
---@return integer? value 读取到的值
local function pb_readfixed32(s)
    local pos = s.pos
    if pos + 4 > s.end_pos then
        return 0
    end
    local _data = s._data
    local n = 0
    for i = 3, 0, -1 do
        n = n << 8
        n = n | (_data[pos + i] & 0xFF)
    end
    s.pos = pos + 4
    return 4, n
end


---@param s protobuf.Slice
---@return integer len 读取到的字节数
---@return integer? value 读取到的值
local function pb_readfixed64(s)
    local pos = s.pos
    if pos + 8 > s.end_pos then
        return 0
    end
    local n = 0
    local _data = s._data
    for i = 7, 0, -1 do
        n = n << 8
        n = n | (_data[pos + i] & 0xFF)
    end
    s.pos = pos + 8
    return 8, n
end



---@param s protobuf.Slice
---@param pv protobuf.Slice
---@return integer
local function pb_readbytes(s, pv)
    local pos = s.pos
    -- 1. 读取 varint 编码的长度值
    local len, value = pb_readvarint64(s)
    if len == 0 or pb_len(s) < value then
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

---@param s protobuf.Slice
---@return integer
local function pb_skipvarint(s)
    local pos = s.pos
    local op = pos
    local _data = s._data
    while pos < s.end_pos and (_data[pos] & 0x80) ~= 0 do
        pos = pos + 1
    end
    if pos >= s.end_pos then
        return 0
    end
    pos = pos + 1
    s.pos = pos
    return pos - op
end

---@param s protobuf.Slice
---@param len integer
---@return integer
local function pb_skipslice(s, len)
    if s.pos + len > s.end_pos then return 0 end
    s.pos = s.pos + len
    return len
end

---@param s protobuf.Slice
---@return integer
local function pb_skipbytes(s)
    local pos = s.pos
    local len, value = pb_readvarint64(s)
    if len == 0 then
        return 0
    end
    if pb_len(s) < value then
        s.pos = pos
        return 0
    end
    s.pos = s.pos + value
    return s.pos - pos
end


---@param s protobuf.Slice
---@param tag integer
---@param target protobuf.Slice
---@return integer
local function pb_readgroup(s, tag, target)
    local pos = s.pos
    assert(pb_gettype(tag) == PB_TGSTART)
    while true do
        local count, newtag = pb_readvarint32(s)
        if count == 0 then break end ---@cast newtag integer
        if pb_gettype(newtag) == PB_TGEND then
            if pb_gettag(newtag) ~= pb_gettag(tag) then break end
            target._data = s._data
            target.pos = s.pos
            target.start = s.start
            target.end_pos = s.pos - count
            return s.pos - pos
        end
        if pb_skipvalue(s, newtag) == 0 then break end
    end
    s.pos = pos
    return 0
end


---@param s protobuf.Slice
---@param tag integer
---@return integer
pb_skipvalue = function(s, tag)
    local pos = s.pos
    local ret = 0

    local switchTag = pb_gettype(tag)
    if switchTag == PB_TVARINT then
        ret = pb_skipvarint(s)
    elseif switchTag == PB_T64BIT then
        ret = pb_skipslice(s, 8)
    elseif switchTag == PB_TBYTES then
        ret = pb_skipbytes(s)
    elseif switchTag == PB_T32BIT then
        ret = pb_skipslice(s, 4)
    elseif switchTag == PB_TGSTART then
        ---@diagnostic disable-next-line: missing-fields
        local data = {} ---@type protobuf.Slice
        ret = pb_readgroup(s, tag, data)
    end
    if ret == 0 then
        s.pos = pos
    end
    return ret
end


-- 读取指定长度的字节，并返回读取到的字节数
---@param s protobuf.Slice
---@param len integer
---@param targetSlice protobuf.Slice
---@return integer @读取到的字节数
local function pb_readslice(s, len, targetSlice)
    if pb_len(s) < len then
        return 0
    end
    targetSlice._data = s._data
    targetSlice.start = s.start
    targetSlice.pos = s.pos
    targetSlice.end_pos = s.pos + len
    s.pos = targetSlice.end_pos
    return len
end


---@param s protobuf.Slice
---@param targetSlice protobuf.Slice
local function lpb_readbytes(s, targetSlice)
    local readLen, len = pb_readvarint64(s)
    if readLen == 0 or len > PB_MAX_SIZET then
        error("invalid bytes length: " .. len .. " (at offset " .. (pb_pos(s) + 1) .. ")")
        return
    end
    ---@cast len integer
    if pb_readslice(s, len, targetSlice) == 0 and len ~= 0 then
        error("unfinished bytes (len " .. len .. " at offset " .. (pb_pos(s) + 1) .. ")")
        return
    end
end


-- 获取要设置的整数
---@param value integer 值
---@param isUnsigned boolean 是否为无符号整数
---@param mode integer 模式
---@return integer value 值
local function lpb_pushinteger(value, isUnsigned, mode)
    if mode ~= LPB_NUMBER and ((isUnsigned and value < 0) or value < INT_MIN or value > UINT_MAX) then
        --TODO 编码为字符串
        return value
    else
        return value
    end
end

---@type {[protobuf.FieldType]: fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
local switchReadType
-- 读取类型转为读表形式
switchReadType = {
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tbool] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return value ~= 0
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tenum] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return value
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tint32] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tuint32] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, true, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tsint32] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(pb_decode_sint32(value), false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tint64] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tuint64] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, true, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tsint64] = function(env, s)
        local len, value = pb_readvarint64(s) ---@cast value integer
        if len == 0 then error("invalid varint value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(pb_decode_sint64(value), false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tfloat] = function(env, s)
        local len, value = pb_readfixed32(s) ---@cast value integer
        if len == 0 then error("invalid fixed32 value at offset " .. (pb_pos(s) + 1)) end
        return pb_decode_float(value)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tfixed32] = function(env, s)
        local len, value = pb_readfixed32(s) ---@cast value integer
        if len == 0 then error("invalid fixed32 value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, true, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tsfixed32] = function(env, s)
        local len, value = pb_readfixed32(s) ---@cast value integer
        if len == 0 then error("invalid fixed32 value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tdouble] = function(env, s)
        local len, value = pb_readfixed64(s) ---@cast value integer
        if len == 0 then error("invalid fixed64 value at offset " .. (pb_pos(s) + 1)) end
        return pb_decode_double(value)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tfixed64] = function(env, s)
        local len, value = pb_readfixed64(s) ---@cast value integer
        if len == 0 then error("invalid fixed64 value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, true, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tsfixed64] = function(env, s)
        local len, value = pb_readfixed64(s) ---@cast value integer
        if len == 0 then error("invalid fixed64 value at offset " .. (pb_pos(s) + 1)) end
        return lpb_pushinteger(value, false, env.LS.int64Mode)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tbytes] = function(env, s)
        ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
        local targetSlice = { _data = nil, start = nil, pos = nil, end_pos = nil } ---@type protobuf.Slice
        lpb_readbytes(s, targetSlice)
        return getSliceString(targetSlice)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tstring] = function(env, s)
        ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
        local targetSlice = { _data = nil, start = nil, pos = nil, end_pos = nil } ---@type protobuf.Slice
        lpb_readbytes(s, targetSlice)
        return getSliceString(targetSlice)
    end,
    ---@type fun(env: protobuf.CodingEnv, s: protobuf.Slice): number|string|boolean|nil}
    [PB_Tmessage] = function(env, s)
        ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
        local targetSlice = { _data = nil, start = nil, pos = nil, end_pos = nil } ---@type protobuf.Slice
        lpb_readbytes(s, targetSlice)
        return getSliceString(targetSlice)
    end,
}


---@param env protobuf.CodingEnv
---@param fieldType integer
---@param s protobuf.Slice
---@return number|string|boolean|nil value 读取到的值
local function lpb_readtype(env, fieldType, s)
    return switchReadType[fieldType](env, s)
end


--#endregion



--#region 导出

M.pb_addvarint32 = pb_addvarint32
M.pb_addvarint64 = pb_addvarint64
M.pb_addfixed32 = pb_addfixed32
M.pb_addfixed64 = pb_addfixed64
M.pb_addslice = pb_addslice
M.pb_addbytes = pb_addbytes
M.lpb_addlength = lpb_addlength


M.pb_pair = pb_pair
M.pb_readvarint32 = pb_readvarint32
M.pb_readvarint64 = pb_readvarint64
M.pb_skipvalue = pb_skipvalue
M.pb_readbytes = pb_readbytes
M.pb_gettag = pb_gettag
M.pb_gettype = pb_gettype
M.lpb_readbytes = lpb_readbytes
M.lpb_pushinteger = lpb_pushinteger
M.lpb_readtype = lpb_readtype


--#endregion
return M
