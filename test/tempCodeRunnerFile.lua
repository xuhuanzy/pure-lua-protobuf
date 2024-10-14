
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