local protoOut = require("pb.protoOut")
local _pb_encode = require("pb.encode").encode

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
       { name = "bob",   phonenumber = 45645674567 }
    }
 }
 
 -- 将Lua表编码为二进制数据
 local bytes = assert(_pb_encode("Person", data))
 print(protoOut.toHex(bytes))