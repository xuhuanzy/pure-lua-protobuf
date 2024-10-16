
local State = require("pb.state")

local pb_name = require("pb.name").pb_name
local sliceCopy = require("pb.util").sliceCopy

local tableInsert = table.insert
local tableRemove = table.remove
local ipairs = ipairs
local pairs = pairs
local error = error
local assert = assert
local type = type
local tonumber = tonumber

---@class Protobuf.Search
local M = {}



-- 搜索类型
---@param LS lpb_State
---@param s pb_Slice
---@return Protobuf.Type?
function M.lpb_type(LS, s)
    local t
    -- 0: `\0`   46: '.'
    if s.pos == nil or s._data[1] == 0 or s._data[1] == 46 then
        local nameEntry = pb_name(LS.state, s)
        if nameEntry then
            t = State.pb_type(LS.state, nameEntry.name)
        end
    else
        local copy = sliceCopy(s)
        -- `46` 等价于`string.byte(".")`
        tableInsert(copy._data, 1, 46)
        copy.end_pos = copy.end_pos + 1
        local nameEntry = pb_name(LS.state, copy)
        if nameEntry then
            t = State.pb_type(LS.state, nameEntry.name)
        end
    end
    return t
end

return M