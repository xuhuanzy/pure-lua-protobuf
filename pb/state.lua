---@class lpb_State 全局状态, 允许配置
---@field state pb_State
---@field local_state pb_State
---@field cache pb_Cache
---@field buffer pb_Buffer
---@field array_type pb_Type
---@field map_type pb_Type
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


---@type lpb_State 当前的全局状态, 允许切换
local CurrentState = nil

-- 获取当前状态
---@return lpb_State
local function lpb_lstate()
    if not CurrentState then
        ---@diagnostic disable-next-line: missing-fields
        CurrentState = {}
        ---@diagnostic disable-next-line: missing-fields
        CurrentState.array_type = {
            is_dead = 1,
        }
        ---@diagnostic disable-next-line: missing-fields
        CurrentState.map_type = {
            is_dead = 1,
        }
        CurrentState.defs_index = -2      -- LUA_NOREF
        CurrentState.enc_hooks_index = -2 -- LUA_NOREF
        CurrentState.dec_hooks_index = -2 -- LUA_NOREF
        CurrentState.local_state = {
            ---@diagnostic disable-next-line: missing-fields
            types = {
                hash = {},
            },
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

return {
    lpb_lstate = lpb_lstate
}