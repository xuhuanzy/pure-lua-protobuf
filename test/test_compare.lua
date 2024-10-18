local dump = require("tools.utility").dump
local TimerTest = require("test.testUtils").TimerTest
local load = require("protobuf").load
local toHex = require("protobuf").toHex
local loadfile = require("protobuf").loadfile
local toBytes = require("protobuf").toBytes
local _pb_encode = require("protobuf").encode
local _pb_decode = require("protobuf").decode

local LibDeflate = require("msgpack.LibDeflate")
local LCompressDeflate = LibDeflate.CompressDeflate
local LDecompressDeflate = LibDeflate.DecompressDeflate
local Base64Encode = require("msgpack.base64").encode
local Base64Decode = require("msgpack.base64").decode

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

local testCount = "万"

do
    local bytes = assert(_pb_encode("Person", data))
    TimerTest("pb encode", testCount, function()
        _pb_encode("Person", data)
    end)

    TimerTest("pb decode", testCount, function()
        _pb_decode("Person", bytes)
    end)

    TimerTest("pb encode & decode", testCount, function()
        _pb_decode("Person", _pb_encode("Person", data))
    end)

    local base64EncodeData = Base64Encode(_pb_encode("Person", data))
    print(#base64EncodeData, base64EncodeData)
    TimerTest("pb encode and base64", testCount, function()
        Base64Encode(_pb_encode("Person", data))
    end)
    TimerTest("pb decode and base64", testCount, function()
        _pb_decode("Person", Base64Decode(base64EncodeData))
    end)
end

do
    local msgpackPack = require('msgpack.msgpack').pack
    local msgpackUnpack = require('msgpack.msgpack').unpack



    local base64EncodeData = Base64Encode(msgpackPack(data))
    print(#base64EncodeData, base64EncodeData)
    TimerTest("msgpack encode and base64", testCount, function()
        Base64Encode(msgpackPack(data))
    end)
    TimerTest("msgpack decode and base64", testCount, function()
        msgpackUnpack(Base64Decode(base64EncodeData))
    end)


    local bytes = LCompressDeflate(LibDeflate, msgpackPack(data))
    TimerTest("msgpack encode and compress", testCount, function()
        LCompressDeflate(LibDeflate, msgpackPack(data))
    end)
    TimerTest("msgpack decode and decompress", testCount, function()
        msgpackUnpack(LDecompressDeflate(LibDeflate, bytes))
    end)
    TimerTest("msgpack compress and encode and decode", testCount, function()
        msgpackUnpack(LDecompressDeflate(LibDeflate, LCompressDeflate(LibDeflate, msgpackPack(data))))
    end)

    TimerTest("msgpack compress coding and base64", testCount, function()
        -- msgpack compress coding and base64
        msgpackUnpack(LDecompressDeflate(LibDeflate, Base64Decode(
            Base64Encode(LCompressDeflate(LibDeflate, msgpackPack(data)))
        )))
    end)
end
