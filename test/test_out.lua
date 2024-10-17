local dump = require("tools.utility").dump
local loadFile = require("tools.utility").loadFile
local protoOut = require("pb.protoOut")
local pb = protoOut
local protoc = protoOut
local _pb_encode = require("pb.encode").encode
local _pb_decode = require("pb.decode").decode

-- 内存占用
local text, errMsg = loadFile("D:\\Workspace\\game\\y3\\tools\\lua-protobuf\\test.proto")
assert(protoc:load(text))


local data = {
    name     = "ilse",
    age      = 18,
    height   = 1.7,
    contacts = {
        { name = "alice", phonenumber = 12312341234 },
        { name = "bob",   phonenumber = 45645674567 },
    },
    attrs    = {
        ["123"] = "456",
        ["test"] = "7798",
    },
    email    = "12312341234@qq.com",
    phone    = "12312341234",
}

-- 将Lua表编码为二进制数据
local bytes = assert(_pb_encode("Person", data))
print(protoOut.toHex(bytes))
print(protoOut.toBytesDump(bytes))

local decodeData = _pb_decode("Person", bytes)
print(dump(decodeData))
