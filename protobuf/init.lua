---@class protobuf.Export
local M = {}

M.setOption = require("protobuf.state").setOption
M.encode = require("protobuf.encode").encode
M.decode = require("protobuf.decode").decode
M.toHex = require("protobuf.parser").toHex
M.toBytes = require("protobuf.parser").toBytes
M.new = require("protobuf.parser").new

local parser = require("protobuf.parser")
-- 加载文件描述符
---@param data string 数据
---@param name? string 名称
---@return boolean @是否成功
---@return integer @当前数据位置
M.load = function(data, name)
    return parser:load(data, name)
end

-- 从文件加载文件描述符
---@param fn string 文件名
---@return boolean @是否成功
---@return integer @当前数据位置
M.loadfile = function(fn)
    return parser:loadfile(fn)
end


return M
