local dump = require("tools.utility").dump
local TimerTest = require("test.testUtils").TimerTest
local protoOut = require("pb.protoOut")
local pb = protoOut
local protoc = protoOut
local _pb_encode = require("pb.encode").encode
local _pb_decode = require("pb.decode").decode

local LibDeflate = require("msgpack.LibDeflate")
local LCompressDeflate = LibDeflate.CompressDeflate
local LDecompressDeflate = LibDeflate.DecompressDeflate

assert(protoc:load [[
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

do
    local bytes = assert(_pb_encode("Person", data))
    TimerTest("pb encode", "万", function()
        _pb_encode("Person", data)
    end)

    TimerTest("pb decode", "万", function()
        _pb_decode("Person", bytes)
    end)
end

do

    local msgpackPack = require('msgpack.msgpack').pack
    local msgpackUnpack = require('msgpack.msgpack').unpack

    local bytes = LCompressDeflate(LibDeflate, msgpackPack(data))
    TimerTest("msgpack encode", 1000, function()
        LCompressDeflate(LibDeflate, msgpackPack(data))
    end)
    TimerTest("msgpack decode", 1000, function()
        msgpackUnpack(LDecompressDeflate(LibDeflate, bytes))
    end)
end