local loader = require("protobuf.loader")
local decode = require("protobuf.decode")
local util = require("protobuf.util")
local State = require("protobuf.state")

local TestGobalDefine = require("test.TestGobalDefine")


local ok, len = loader.Load(TestGobalDefine.descriptor_pb)
