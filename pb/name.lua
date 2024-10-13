local decode = require("pb.decode")
local pb_len = decode.pb_len
local getSliceString = decode.getSliceString

local PB_MAX_SIZET = (0xFFFFFFFF - 100)
local PB_MAX_HASHSIZE = (0xFFFFFFFF - 100)
local PB_MIN_STRTABLE_SIZE = 16
local PB_MIN_HASHTABLE_SIZE = 8
local PB_HASHLIMIT = 5

---@class Export.Protobuf.Name
local Export = {}


---@param name pb_NameEntry
---@return pb_Name
local function pb_usename(name)
    if name then
        name.refcount = name.refcount + 1
    end
    return name.name
end

-- 计算哈希
---@param s pb_Slice
---@return integer
local function pbN_calchash(s)
    local len = pb_len(s)
    local h = len
    local lastIndex = s.end_pos
    local step = (len >> PB_HASHLIMIT) + 1
    while len >= step do
        h = h ~ ((h << 5) + (h >> 2) + s._data[lastIndex - 1]) & 0xFFFFFFFF
        lastIndex = lastIndex - step
        len = len - step
    end
    return h
end


-- ---@param t1 pb_Slice
-- ---@param t2 pb_Slice
-- ---@return boolean
-- local function slice_equal(t1, t2)
--     if t1.pos ~= t2.pos then
--         return false
--     end
--     if t1.end_pos ~= t2.end_pos then
--         return false
--     end
--     local t1_data = t1._data
--     local t2_data = t2._data
--     for i = t1.pos, t1.end_pos - 1 do
--         if t1_data[i] ~= t2_data[i] then
--             return false
--         end
--     end

--     return true
-- end

---@param t1 pb_Slice
---@param name string
---@return boolean
local function _equalName(t1, name)
    if getSliceString(t1) ~= name then
        return false
    end
    return true
end

---@param state pb_State
---@param s pb_Slice
---@param hash integer
---@return pb_NameEntry?
local function pbN_getname(state, s, hash)
    local nt = state.nametable
    local len = pb_len(s)
    if nt.hash then
        local entry = nt.hash[hash & (nt.size - 1)]
        while entry do
            if entry.hash == hash and entry.length == len and _equalName(s, entry.name) then
                return entry
            end
            entry = entry.next
        end
    end
    return nil
end

---@param state pb_State
---@param size integer
---@return boolean
local function pbN_resize(state, size)
    local nt = state.nametable
    local newsize = PB_MIN_STRTABLE_SIZE
    while newsize < PB_MAX_HASHSIZE and newsize < size do
        newsize = newsize << 1
    end
    if newsize < size then
        return false
    end
    ---@type pb_NameEntry[]
    local hash = {}
    for i = 1, nt.size, 1 do
        local entry = nt.hash[i]
        while entry do
            local next = entry.next
            -- 计算新哈希桶位置
            local newHashIndex = entry.hash & (newsize - 1)
            -- 获取新哈希桶链表头
            local newh = hash[newHashIndex]
            -- 先更新当前 entry 的 next 指针
            entry.next = newh
            -- 再插入到新哈希桶的头部
            hash[newHashIndex] = entry
            -- 移动到下一个 entry
            entry = next
        end
    end
    -- 将新的哈希表赋值给 nametable
    nt.hash = hash
    nt.size = newsize
    return true
end

---@param state pb_State
---@param s pb_Slice
---@param hash integer
---@return pb_NameEntry?
local function pbN_newname(state, s, hash)
    local nt = state.nametable
    local len = pb_len(s)
    if nt.count >= nt.size and not pbN_resize(state, nt.size * 2) then
        return nil
    end
    local hashIndex = hash & (nt.size - 1)
    ---@type pb_NameEntry
    local newobj = {
        next =  nt.hash[hashIndex],
        length = len,
        refcount = 0,
        hash = hash,
        name = getSliceString(s) or ""
    }
    nt.hash[hashIndex] = newobj
    nt.count = nt.count + 1
    return newobj
end

---export
---@param state pb_State
---@param s pb_Slice
---@return pb_NameEntry?
function Export.pb_newname(state, s)
    if not s.pos then
        return nil
    end
    local hash = pbN_calchash(s)
    local entry = pbN_getname(state, s, hash)
    if not entry then
        entry = pbN_newname(state, s, hash)
    end
    if entry then
        pb_usename(entry)
    end

    return entry
end

---export
---@param state pb_State
---@param s pb_Slice
---@return pb_Name?
function Export.getNewName(state, s)
    local entry = Export.pb_newname(state, s)
    return entry and entry.name or nil
end


---export
---@param state pb_State
---@param s pb_Slice
---@return pb_NameEntry?
function Export.pb_name(state, s)
    if not state or not s.pos then
        return nil
    end
    local entry = pbN_getname(state, s, pbN_calchash(s))
    return entry
end



return Export
