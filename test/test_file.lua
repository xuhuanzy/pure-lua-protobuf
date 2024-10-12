local loader = require("pb.loader")
local decode = require("pb.decode")
local TestGobalDefine = require("test.TestGobalDefine")

loader.pb_load(decode.pb_slice(TestGobalDefine.descriptor_pb))
