local tryGetName = require("pb.names").tryGetName
local getSliceString = require("pb.util").getSliceString

---@class Export.Protobuf.State
local M = {}


---@class lpb_State 全局状态, 允许配置
---@field state pb_State
---@field local_state pb_State
---@field array_type Protobuf.Type 数组类型
---@field map_type Protobuf.Type 映射类型
---@field defs_index integer 
---@field enc_hooks_index integer
---@field dec_hooks_index integer
---@field use_dec_hooks boolean 使用解码钩子
---@field use_enc_hooks boolean 使用编码钩子
---@field enum_as_value boolean 解码枚举时, `false`设置值为枚举名, `true`设置为枚举值数字
---@field encode_mode Protobuf.EncodeMode 编码模式
---@field int64_mode Protobuf.Int64Mode 64位整数模式
---@field encode_default_values boolean 默认值也参与编码
---@field decode_default_array boolean 对于数组，将空值解码为空表或`nil`(默认为`nil`)
---@field decode_default_message boolean 将空子消息解析成默认值表


---@type lpb_State 当前的状态, 允许切换
local CurrentState = nil

---@type pb_State  全局数据库状态
M.GlobalState = nil

-- 获取当前状态
---@return lpb_State
function M.lpb_lstate()
    if not CurrentState then
        ---@diagnostic disable-next-line: missing-fields
        CurrentState = {
            encode_mode = 0,
        }
        ---@diagnostic disable-next-line: missing-fields
        CurrentState.array_type = {
            is_dead = true,
        }
        ---@diagnostic disable-next-line: missing-fields
        CurrentState.map_type = {
            is_dead = true,
        }
        CurrentState.defs_index = -2      -- LUA_NOREF
        CurrentState.enc_hooks_index = -2 -- LUA_NOREF
        CurrentState.dec_hooks_index = -2 -- LUA_NOREF
        CurrentState.local_state = {
            types = {},
            nametable = {},
        }
        CurrentState.state = CurrentState.local_state
    end
    return CurrentState
end

-- 从数据库搜索类型
---@param state pb_State
---@param tname protobuf.NameValue
---@return Protobuf.Type?
function M.pb_type(state, tname)
    if not state or not tname then
        return nil
    end
    local _type = state.types[tname]
    if _type and (not _type.is_dead) then
        return _type
    end
    return nil
end
local pb_type = M.pb_type

-- 从类型中搜索字段
---@param protobufType Protobuf.Type
---@param number integer
---@return Protobuf.Field?
function M.pb_field(protobufType, number)
    if not protobufType then
        return nil
    end
    return protobufType.field_tags[number]
end

---@param protobufType Protobuf.Type
---@param name protobuf.NameValue?
---@return Protobuf.Field?
function M.pb_fname(protobufType, name)
    if not protobufType or not name then
        return nil
    end
    return protobufType.field_names[name]
end

-- 搜索类型
---@param LS lpb_State
---@param s protobuf.Slice
---@return Protobuf.Type?
function M.lpb_type(LS, s)
    -- 0: `\0`   46: '.'
    if s._data[1] == 46 or s.pos == nil or s._data[1] == 0 then
        local name = tryGetName(LS.state, s)
        if name then
            return pb_type(LS.state, name)
        end
    else
        local name = tryGetName(LS.state, "." .. getSliceString(s))
        if name then
            return pb_type(LS.state, name)
        end
    end
end

return M
