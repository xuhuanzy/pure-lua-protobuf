local tryGetName = require("pb.names").tryGetName
local getSliceString = require("pb.util").getSliceString

local pb_type = require("pb.state").pb_type


---@class Protobuf.Search
local M = {}


-- 搜索类型
---@param LS lpb_State
---@param s protobuf.Slice
---@return Protobuf.Type?
function M.lpb_type(LS, s)
    -- 0: `\0`   46: '.'
    if s._data[1] == 46 or s.pos == nil or s._data[1] == 0 then
        local name = tryGetName(LS.state, s)
        if name then
            return pb_type(LS.state, name)
        end
    else
        local name = tryGetName(LS.state, "." .. getSliceString(s))
        if name then
            return pb_type(LS.state, name)
        end
    end
end

return M
