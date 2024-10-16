---@class Export.Protobuf.State
local M = {}


---@class lpb_State 全局状态, 允许配置
---@field state pb_State
---@field local_state pb_State
---@field cache pb_Cache
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
---@field encode_order boolean 编码顺序


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
            ---@diagnostic disable-next-line: missing-fields
            types = {},
            ---@diagnostic disable-next-line: missing-fields
            fieldpool = {},
            ---@diagnostic disable-next-line: missing-fields
            nametable = {
                count = 0,
                size = 0,
                hash = {},
            },
            ---@diagnostic disable-next-line: missing-fields
            typepool = {},
        }
        CurrentState.state = CurrentState.local_state
    end
    return CurrentState
end

-- 从数据库搜索类型
---@param state pb_State
---@param tname pb_Name
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
---@param name pb_Name?
---@return Protobuf.Field?
function M.pb_fname(protobufType, name)
    if not protobufType or not name then
        return nil
    end
    return protobufType.field_names[name]
end

return M
