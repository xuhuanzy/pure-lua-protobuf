---@class Export.Protobuf.State
local M = {}

---@class lpb_State 全局状态, 允许配置
---@field state pb_State
---@field local_state pb_State
---@field cache pb_Cache
---@field array_type Protobuf.Type
---@field map_type Protobuf.Type
---@field defs_index integer
---@field enc_hooks_index integer
---@field dec_hooks_index integer
---@field use_dec_hooks boolean
---@field use_enc_hooks boolean
---@field enum_as_value boolean
---@field encode_mode integer
---@field int64_mode integer
---@field encode_default_values boolean
---@field decode_default_array boolean
---@field decode_default_message boolean
---@field encode_order boolean


---@type lpb_State 当前的状态, 允许切换
local CurrentState = nil

---@type pb_State  全局数据库状态
M.GlobalState = nil

-- 获取当前状态
---@return lpb_State
function M.lpb_lstate()
    if not CurrentState then
        ---@diagnostic disable-next-line: missing-fields
        CurrentState = {}
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


---@param protobufType Protobuf.Type
---@param number integer
---@return Protobuf.Field?
function M.pb_field(protobufType, number)
    if not protobufType then
        return nil
    end
    return protobufType.field_tags[number]
end

--[[ 
PB_API const pb_Field *pb_fname(const pb_Type *t, const pb_Name *name) {
    pb_FieldEntry *fe = NULL;
    if (t != NULL && name != NULL)
        fe = (pb_FieldEntry *) pb_gettable(&t->field_names, (pb_Key) name);
    return fe ? fe->value : NULL;
} ]]

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
