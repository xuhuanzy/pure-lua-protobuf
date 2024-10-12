local fileDescriptor = require("pb.fileDescriptor")

local TestGobalDefine = require "test.TestGobalDefine"

---@class pb_Loader
---@field s pb_Slice
---@field b pb_Buffer
---@field is_proto3 boolean


local M = {}

---@param s pb_Slice
function M.pb_load(s)
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
end




return M
