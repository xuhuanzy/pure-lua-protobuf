
local TimerTest = require("test.testUtils").TimerTest
local load = require("protobuf").load
local toHex = require("protobuf").toHex
local loadfile = require("protobuf").loadfile
local toBytes = require("protobuf").toBytes
local _pb_encode = require("protobuf").encode
local _pb_decode = require("protobuf").decode

assert(load [[
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
    double  height = 5;
    int32 defaulted_int = 10  [ default = 777 ];
    string defaulted_string = 11 [ default = "hello" ];
    int64 defaulted_int64 = 12 [ default = 954854164694 ];

    oneof notice_way{
        string email = 22;
        string phone = 23;
    };
}
]])
local data = {
    name     = "ilse",
    age      = 18,
    height   = 1.7,
    contacts = {
        { name = "alice", phonenumber = 12312341234 },
        { name = "bob",   phonenumber = 45645674567 },
    },
    sports   = {
    },
    email    = "12312341234@qq.com",
    phone    = "12312341234",
}

local bytes = assert(_pb_encode("Person", data))

local testCount = "十万"

TimerTest("pb encode", testCount, function()
    _pb_encode("Person", data)
end)

TimerTest("pb decode", testCount, function()
    _pb_decode("Person", bytes)
end)

TimerTest("pb encode & decode", testCount, function()
    _pb_decode("Person", _pb_encode("Person", data))
end)


local msgpackPack = require('msgpack.msgpack').pack
local bytes = msgpackPack(data)
TimerTest("msgpack encode", testCount, function()
    msgpackPack(data)
end)

local msgpackUnpack = require('msgpack.msgpack').unpack
TimerTest("msgpack decode", testCount, function()
    msgpackUnpack(bytes)
end)

TimerTest("msgpack encode & decode", testCount, function()
    msgpackUnpack(msgpackPack(data))
end)
