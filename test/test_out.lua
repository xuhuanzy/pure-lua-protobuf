local dump = require("tools.utility").dump
local load = require("protobuf").load
local toHex = require("protobuf").toHex
local loadfile = require("protobuf").loadfile
local toBytes = require("protobuf").toBytes
local _pb_encode = require("protobuf").encode
local _pb_decode = require("protobuf").decode


-- 内存占用
-- local text, errMsg = loadFile("D:\\Workspace\\game\\y3\\tools\\lua-protobuf\\test.proto")
-- assert(text, errMsg)
assert(loadfile("D:\\Workspace\\game\\y3\\tools\\lua-protobuf\\test.proto"))



local data = {
    name     = "ilse",
    age      = 18,
    height   = 1.7,
    contacts = {
        { name = "alice", phonenumber = 12312341234 },
        { name = "bob",   phonenumber = 45645674567 },
    },
    attrs    = {
        ["123"] = "456"
    },
    email    = "12312341234@qq.com",
    phone    = "12312341234",
    color    =  1,
}

-- 将Lua表编码为二进制数据
local bytes = assert(_pb_encode("Person", data))
print(toHex(bytes))
print(toBytes(bytes))

local decodeData = _pb_decode("Person", bytes)
print(dump(decodeData))
