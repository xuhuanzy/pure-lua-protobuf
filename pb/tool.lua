local type = type
local stringPack = string.pack
local stringUnpack = string.unpack
local tostring = tostring
local tonumber = tonumber


-- 工具类, 不依赖 protobuf 的定义
---@class Export.Protobuf.Tool
local Tool = {}


-- 定义一个类(简单定义)
---@generic T: string
---@param name  `T`
---@param t? table
---@return T
function Tool.meta(name, t)
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
function Tool.defaultTable(t, k, def)
    local v = t[k]
    if not v then
        v = def or {}
        t[k] = v
    end
    return v
end

--#region 类型检查

-- 抛出错误
---@param fmt string 格式化字符串
---@param ... any 参数
function Tool.throw(fmt, ...)
    error(string.format(fmt, ...))
end

---检查参数
---@param cond boolean 条件
---@param fmt string 格式化字符串
---@param ... any 参数
local function argcheck(cond, fmt, ...)
    if not cond then
        error(string.format(fmt, ...))
    end
end
Tool.argcheck = argcheck

-- 检查值是否为表
---@param field Protobuf.Field 字段, 用于定位
---@param data any 值
function Tool.checkTable(field, data)
    argcheck(
        type(data) == "table",
        "table expected at field '%s', got %s",
        field.name, type(data)
    )
end

--#endregion

--#region 数值操作

-- 转换为32位整数
---@param n number
---@return integer
function Tool.toInt32(n)
    n = n & 0xFFFFFFFF         -- 保留低 32 位
    if n >= 0x80000000 then
        return n - 0x100000000 -- 处理负数的情况
    else
        return n
    end
end

-- 将32位无符号整数转换为64位有符号整数
---@param n integer
---@return integer
function Tool.expandsig32To64(n)
    n = n & 0xFFFFFFFF -- 确保是32位整数
    -- 0x80000000: 1 << 31
    return (n ~ 0x80000000) - 0x80000000
end

-- ZigZag 编码
---@param value integer
---@return integer
function Tool.pb_encode_sint32(value)
    return ((value << 1) ~ -((value < 0) and 1 or 0)) & 0xFFFFFFFF
end

-- ZigZag 解码
---@param value integer
---@return integer
function Tool.pb_decode_sint32(value)
    return (value >> 1) ~ -(value & 1) & 0xFFFFFFFF
end

-- ZigZag 编码
---@param value integer
---@return integer
function Tool.pb_encode_sint64(value)
    return ((value << 1) ~ -((value < 0) and 1 or 0))
end

-- ZigZag 解码
---@param value integer
---@return integer
function Tool.pb_decode_sint64(value)
    return (value >> 1) ~ -(value & 1)
end

function Tool.pb_encode_double(value)
    return stringUnpack("I8", stringPack("d", value))
end

---@param value integer
---@return number
function Tool.pb_decode_double(value)
    ---@diagnostic disable-next-line: redundant-return-value
    return stringUnpack("d", stringPack("I8", value))
end

function Tool.pb_encode_float(value)
    return stringUnpack("I4", stringPack("f", value))
end

---@param value integer
---@return number
function Tool.pb_decode_float(value)
    ---@diagnostic disable-next-line: redundant-return-value
    return stringUnpack("f", stringPack("I4", value))
end


--#endregion


--#region 字符操作

-- 将字符转换为对应的十六进制值
---@param ch string
---@return number
local function hexchar(ch)
    if ch == '0' then
        return 0
    elseif ch == '1' then
        return 1
    elseif ch == '2' then
        return 2
    elseif ch == '3' then
        return 3
    elseif ch == '4' then
        return 4
    elseif ch == '5' then
        return 5
    elseif ch == '6' then
        return 6
    elseif ch == '7' then
        return 7
    elseif ch == '8' then
        return 8
    elseif ch == '9' then
        return 9
    elseif ch == 'A' then
        return 10
    elseif ch == 'B' then
        return 11
    elseif ch == 'C' then
        return 12
    elseif ch == 'D' then
        return 13
    elseif ch == 'E' then
        return 14
    elseif ch == 'F' then
        return 15
    elseif ch == 'a' then
        return 10
    elseif ch == 'b' then
        return 11
    elseif ch == 'c' then
        return 12
    elseif ch == 'd' then
        return 13
    elseif ch == 'e' then
        return 14
    elseif ch == 'f' then
        return 15
    else
        return -1
    end
end

---@param s any 要转换的字符串或数字
---@return number @转换后的整数
---@return boolean @是否转换成功
-- 将字符串或数字转换为整数
function Tool.lpb_tointegerx(s)
    local neg = false -- 是否为负数
    local v = tonumber(s)
    if v ~= nil then
        return v, true
    end
    s = tostring(s)
    if s == nil then
        return 0, false
    end
    v = 0
    -- 处理前缀符号
    local i = 1
    while s:sub(i, i) == '#' or s:sub(i, i) == '+' or s:sub(i, i) == '-' do
        if s:sub(i, i) == '-' then
            neg = not neg
        end
        i = i + 1
    end

    -- 处理十六进制数
    if s:sub(i, i + 1) == "0x" or s:sub(i, i + 1) == "0X" then
        i = i + 2
        while i <= #s do
            local n = hexchar(s:sub(i, i))
            if n < 0 then break end
            v = v * 16 + n
            i = i + 1
        end
    else
        -- 处理十进制数
        while i <= #s do
            local n = hexchar(s:sub(i, i))
            if n < 0 or n > 9 then break end
            v = v * 10 + n
            i = i + 1
        end
    end
    -- 检查是否完全解析了字符串
    if i <= #s then
        return 0, false
    end
    -- 返回结果，如果是负数则返回相应的负值
    return neg and (~v) + 1 or v, true
end

--#endregion

return Tool
