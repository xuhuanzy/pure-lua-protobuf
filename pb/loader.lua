local fileDescriptor = require("pb.fileDescriptor")
local decode = require("pb.decode")

local pb_slice = decode.pb_slice

local TestGobalDefine = require "test.TestGobalDefine"

---@class pb_Loader
---@field s pb_Slice
---@field b pb_Buffer
---@field is_proto3 boolean

---@class PB.Loader
local M = {}


---@param state pb_State
---@param info pbL_FileInfo
---@param L pb_Loader
local function loadDescriptorFiles(state, info, L)
    local i, count, j, jcount, curr = 0, 0, 0, 0, 0;
    local s =pb_slice("proto3")
end



---@param state pb_State
---@param s pb_Slice
function M.pb_load(state, s)
    ---@type pbL_FileInfo
    ---@diagnostic disable-next-line: missing-fields
    local files = {
        enum_type = {},
        message_type = {},
        extension = {},
        ---@diagnostic disable-next-line: missing-fields
        package = {},
        ---@diagnostic disable-next-line: missing-fields
        syntax = {}
    }
    ---@type pb_Loader
    local L = {
        ---@diagnostic disable-next-line: missing-fields
        b = {},
        s = s,
        is_proto3 = false
    }
    fileDescriptor.pbL_FileDescriptorSet(L, files)
    loadDescriptorFiles(state, files, L)
end

return M
