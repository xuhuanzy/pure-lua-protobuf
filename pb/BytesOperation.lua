local pb_len = require("pb.util").pb_len

local tableInsert = table.insert

---@class Protobuf.BytesOperation
local M = {}

--#region 写入

---@param buff Protobuf.Char[]
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

---@param buff Protobuf.Char[]
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

---@param b Protobuf.Char[]
---@param n integer
---@return integer
local function pb_addvarint32(b, n)
    if not b then
        return 0
    end
    return pb_write32(b, n)
end

---@param b Protobuf.Char[]
---@param n integer
---@return integer
local function pb_addvarint64(b, n)
    if not b then return 0 end
    return pb_write64(b, n)
end



---@param b Protobuf.Char[]
---@param n integer
---@return integer
local function pb_addfixed32(b, n)
    local c = 0
    local writeIndex = #b + 1
    for i = 0, 3 do
        b[writeIndex + i] = n & 0xFF
        n = n >> 8
    end
    return 8
end


---@param b Protobuf.Char[]
---@param n integer
---@return integer
local function pb_addfixed64(b, n)
    local c = 0
    local writeIndex = #b + 1
    for i = 0, 7 do
        b[writeIndex + i] = n & 0xFF
        n = n >> 8
    end
    return 8
end

---@param b Protobuf.Char[]
---@param s pb_Slice
---@return integer
local function pb_addslice(b, s)
    local len = pb_len(s)
    local writeIndex = #b
    for i = 1, len do
        b[writeIndex + i] = s._data[s.pos + i - 1]
    end
    return len
end

---@param b Protobuf.Char[]
---@param s pb_Slice
---@return integer
local function pb_addbytes(b, s)
    local len = pb_len(s)
    local ret = pb_addvarint32(b, len)
    return ret + pb_addslice(b, s)
end

---@param targetCharArray Protobuf.Char[] 缓冲区
---@param beforeLength integer 前面的有效字节长度(包含预分配的长度)
---@param prealloc integer 预分配长度
---@return integer @返回`写入的长度` + `剩余有效字节的长度`
local function pb_addlength(targetCharArray, beforeLength, prealloc)
    local curLength = #targetCharArray
    if curLength < beforeLength then
        return 0
    end
    ---@type Protobuf.Char[]
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

    --[[
     -- 插入位置, 未 + 1
    local insertIndex = beforeLength - prealloc
    -- 插入到目标缓冲区
    for i = 1, ml do
        tableInsert(targetCharArray, insertIndex + i, newBuff[i])
    end
    ]]
    -- `curLength - beforeLength`: 剩余的有效字节长度
    return ml + (curLength - beforeLength)
end


---@param targetCharArray Protobuf.Char[] 缓冲区
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



--#endregion



--#region 导出

M.pb_addvarint32 = pb_addvarint32
M.pb_addvarint64 = pb_addvarint64
M.pb_addfixed32 = pb_addfixed32
M.pb_addfixed64 = pb_addfixed64
M.pb_addslice = pb_addslice
M.pb_addbytes = pb_addbytes
M.lpb_addlength = lpb_addlength

--#endregion
return M
