
local function meta(name, t)
    t         = t or {}
    t.__name  = name
    t.__index = t
    return t
end


return {
    meta = meta
}
