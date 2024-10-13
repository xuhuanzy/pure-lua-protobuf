
-- 定义一个类(简单定义)
---@generic T: string
---@param name  `T`
---@param t? table
---@return T
local function meta(name, t)
    t         = t or {}
    t.__name  = name
    t.__index = t
    return t
end

-- 取指定key的值(该值为表), 如果key不存在, 则设置为空表
---@param t table
---@param k string|integer
---@param def? table
---@return table
local function defaultTable(t, k, def)
    local v = t[k]
    if not v then
       v = def or {}
       t[k] = v
    end
    return v
 end

return {
    meta = meta,
    defaultTable = defaultTable
}
