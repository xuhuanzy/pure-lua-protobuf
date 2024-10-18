local loader = require("pb.loader")
local decode = require("pb.decode")
local util = require("pb.util")
local State = require("pb.state")

local TestGobalDefine = require("test.TestGobalDefine")


local ok, len = loader.Load(TestGobalDefine.descriptor_pb)
