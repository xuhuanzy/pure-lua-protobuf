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
            nametable = {},
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