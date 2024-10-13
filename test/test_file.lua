local loader = require("pb.loader")
local decode = require("pb.decode")
local PB_state = require("pb.state")
local TestGobalDefine = require("test.TestGobalDefine")
local state = PB_state.lpb_lstate()

loader.pb_load(state.local_state, decode.pb_slice(TestGobalDefine.descriptor_pb))
loader.pb_load(state.local_state, decode.pb_slice(TestGobalDefine.descriptor_pb))
