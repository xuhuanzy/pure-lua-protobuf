local protoOut = require("pb.protoOut")
local _pb_encode = require("pb.encode").encode
local TimerTest = require("test.testUtils").TimerTest

assert(
    protoOut:load [[
   syntax = "proto3";
   message Phone {
       string name        = 1;
       int64  phonenumber = 2;
   }
   message Person {
      string name     = 1;
      int32  age      = 2;
      string address  = 3;
      repeated Phone  contacts = 4;
      int32 defaulted_int = 10 [ default = 777 ];
   }
]]
)
local data = {
    name     = "ilse",
    --    age      = 18,
    test     = 1,
    contacts = {
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
    },
    contacts2 = {
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
        { name = "alice", phonenumber = 12312341234 },
    },
    -- a = function() end,
}

local bytes = assert(_pb_encode("Person", data))

local msgpackPack = require('msgpack.msgpack').pack
TimerTest("msgpack", "万", function()
    msgpackPack(data)
end)


TimerTest("pb", "万", function()
    _pb_encode("Person", data)
end)