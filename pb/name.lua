local decode = require("pb.decode")
local pb_len = decode.pb_len

local PB_MAX_SIZET = (0xFFFFFFFF - 100)
local PB_MAX_HASHSIZE = (0xFFFFFFFF - 100)
local PB_MIN_STRTABLE_SIZE = 16
local PB_MIN_HASHTABLE_SIZE = 8
local PB_HASHLIMIT = 5

---@param s pb_Slice
local function pbN_calchash(s)
    local len = pb_len(s)
--[[     size_t len = pb_len(s);
    unsigned h = (unsigned) len;
    size_t step = (len >> PB_HASHLIMIT) + 1;
    for (; len >= step; len -= step)
        h ^= ((h << 5) + (h >> 2) + (unsigned char) (s.p[len - 1]));
    return h; ]]
    local h = len
    local step = (len >> PB_HASHLIMIT) + 1
    while len >= step do
        h = h ^ ((h << 5) + (h >> 2) + s.data[len - 1])
        len = len - step
    end

    return h
end

---@param state pb_State
---@param s pb_Slice
---@return pb_Name?
local function pb_newname(state, s)
    if not s.pos then
        return nil
    end
end


return {
    pb_newname = pb_newname
}
