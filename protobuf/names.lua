local getSliceString = require("protobuf.util").getSliceString

local type = type


---@alias protobuf.NameValue string

---@class protobuf.NameEntry
---@field refcount integer # 引用计数
---@field name protobuf.NameValue # 名称


---@class export.protobuf.Name
local Export = {}


---@param nameEntry protobuf.NameEntry
local function useName(nameEntry)
    if nameEntry then
        nameEntry.refcount = nameEntry.refcount + 1
    end
end


---@param state protobuf.TypeDatabase
---@param name string
---@return protobuf.NameEntry
local function newName(state, name)
    state.nametable[name] = {
        refcount = 0,
        name = name
    }
    return state.nametable[name]
end

---@param state protobuf.TypeDatabase
---@param name string
---@return protobuf.NameEntry
local function getNameEntry(state, name)
    return state.nametable[name]
end

---尝试获取名称, 如果名称不存在, 则创建名称
---@param state protobuf.TypeDatabase 状态
---@param s protobuf.Slice|string 字符串或切片
---@return protobuf.NameValue? @名称
function Export.tryGetName(state, s)
    if type(s) == "string" then
        return s
    else
        if not s.pos then return nil end
        return getSliceString(s) or ""
    end

    -- local name
    -- if type(s) == "string" then
    --     name = s
    -- else
    --     if not s.pos then return nil end
    --     name = getSliceString(s) or ""
    -- end

    -- local entry = getNameEntry(state, name)
    -- if not entry then
    --     entry = newName(state, name)
    -- end
    -- if entry then
    --     useName(entry)
    -- end
    -- return entry and entry.name or nil
end


return Export
