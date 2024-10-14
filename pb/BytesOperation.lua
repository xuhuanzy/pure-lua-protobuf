
local pb_len = require("pb.util").pb_len
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

--[[ PB_API size_t pb_addslice(pb_Buffer *b, pb_Slice s) {
    size_t len = pb_len(s);
    char *buff = pb_prepbuffsize(b, len);
    if (buff == NULL) return 0;
    memcpy(buff, s.p, len);
    pb_addsize(b, len);
    return len;
} ]]
---@param b Protobuf.Char[]
---@param s pb_Slice
---@return integer
local function pb_addslice(b, s)
    local len = pb_len(s)
    local writeIndex = #b + 1
    for i = 1, len do
        b[writeIndex + i] = s._data[s.pos + i - 1]
    end
    return len
end


--[[ PB_API size_t pb_addbytes(pb_Buffer *b, pb_Slice s) {
    size_t ret, len = pb_len(s);
    if (pb_prepbuffsize(b, len + 5) == NULL) return 0;
    ret = pb_addvarint32(b, (uint32_t) len);
    return ret + pb_addslice(b, s);
}
 ]]

---@param b Protobuf.Char[]
---@param s pb_Slice
---@return integer
local function pb_addbytes(b, s)
    local len = pb_len(s)
    local ret = pb_addvarint32(b, len)
    return ret + pb_addslice(b, s)
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

--#endregion
return M