local loader = require("pb.loader")
local decode = require("pb.decode")
local util = require("pb.util")
local State = require("pb.state")

local TestGobalDefine = require("test.TestGobalDefine")
-- local state = State.lpb_lstate()

-- loader.pb_load(state.local_state, util.pb_slice(TestGobalDefine.descriptor_pb))
-- loader.pb_load(state.local_state, util.pb_slice(TestGobalDefine.descriptor_pb))

local ok, len = loader.Load(TestGobalDefine.descriptor_pb)
