local findField = require("protobuf.state").findField
local findName = require("protobuf.state").findName
local getConfig = require("protobuf.state").getConfig
local findInternalType = require("protobuf.state").findInternalType

local argcheck = require("protobuf.tool").argcheck


local pb_pair = require("protobuf.bytes_operation").pb_pair
local pb_readvarint32 = require("protobuf.bytes_operation").pb_readvarint32
local pb_readvarint64 = require("protobuf.bytes_operation").pb_readvarint64
local pb_skipvalue = require("protobuf.bytes_operation").pb_skipvalue
local pb_readbytes = require("protobuf.bytes_operation").pb_readbytes
local pb_gettag = require("protobuf.bytes_operation").pb_gettag
local pb_gettype = require("protobuf.bytes_operation").pb_gettype
local lpb_readbytes = require("protobuf.bytes_operation").lpb_readbytes
local lpb_pushinteger = require("protobuf.bytes_operation").lpb_pushinteger
local lpb_readtype = require("protobuf.bytes_operation").lpb_readtype

local pb_wtypebytype = require("protobuf.util").pb_wtypebytype
local pb_wtypename = require("protobuf.util").pb_wtypename
local pb_typename = require("protobuf.util").pb_typename
local pb_pos = require("protobuf.util").pb_pos
local NewProtobufSlice = require("protobuf.util").ProtobufSlice.new



local ConstantDefine = require("protobuf.ConstantDefine")
local PB_TBYTES = ConstantDefine.pb_WireType.PB_TBYTES

local PB_Tdouble = ConstantDefine.pb_FieldType.PB_Tdouble
local PB_Tfloat = ConstantDefine.pb_FieldType.PB_Tfloat
local PB_Tint64 = ConstantDefine.pb_FieldType.PB_Tint64
local PB_Tuint64 = ConstantDefine.pb_FieldType.PB_Tuint64
local PB_Tint32 = ConstantDefine.pb_FieldType.PB_Tint32
local PB_Tfixed64 = ConstantDefine.pb_FieldType.PB_Tfixed64
local PB_Tfixed32 = ConstantDefine.pb_FieldType.PB_Tfixed32
local PB_Tbool = ConstantDefine.pb_FieldType.PB_Tbool
local PB_Tstring = ConstantDefine.pb_FieldType.PB_Tstring
local PB_Tmessage = ConstantDefine.pb_FieldType.PB_Tmessage
local PB_Tbytes = ConstantDefine.pb_FieldType.PB_Tbytes
local PB_Tuint32 = ConstantDefine.pb_FieldType.PB_Tuint32
local PB_Tenum = ConstantDefine.pb_FieldType.PB_Tenum
local PB_Tsfixed32 = ConstantDefine.pb_FieldType.PB_Tsfixed32
local PB_Tsfixed64 = ConstantDefine.pb_FieldType.PB_Tsfixed64
local PB_Tsint32 = ConstantDefine.pb_FieldType.PB_Tsint32
local PB_Tsint64 = ConstantDefine.pb_FieldType.PB_Tsint64

-- 默认值, 会自动判断是否使用默认字段. </br>
-- 对于`proto3`, 默认复制默认值到解码目标表中来, 对于其他则忽略默认值设置
local LPB_DEFDEF = ConstantDefine.EncodeMode.LPB_DEFDEF
-- 将默认值表复制到解码目标表中来
local LPB_COPYDEF = ConstantDefine.EncodeMode.LPB_COPYDEF
-- 将默认值表作为解码目标表的元表使用
local LPB_METADEF = ConstantDefine.EncodeMode.LPB_METADEF
-- 忽略默认值
local LPB_NODEF = ConstantDefine.EncodeMode.LPB_NODEF

local USE_FIELD = ConstantDefine.DefFlags.USE_FIELD
local USE_REPEAT = ConstantDefine.DefFlags.USE_REPEAT
local USE_MESSAGE = ConstantDefine.DefFlags.USE_MESSAGE



local rawget = rawget
local rawset = rawset
local tointeger = math.tointeger
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable


---@class protobuf.Decode
local M = {}

--提前声明

local lpb_fetchtable
local lpb_pushtypetable
local lpbD_message

---@param env protobuf.CodingEnv
---@param field protobuf.Field
---@param tag integer
local function lpbD_checktype(env, field, tag)
    if pb_wtypebytype(field.typeId) == pb_gettype(tag) then return end
    local slice = env.slice
    local pos = (slice.pos - slice.start) + 1
    local wtype = pb_wtypename(pb_wtypebytype(field.typeId))
    local type = pb_typename(field.typeId)
    local got = pb_wtypename(pb_gettype(tag))
    local msg = string.format("type mismatch for %s%sfield '%s' at offset %d, %s expected for type %s, got %s",
        field.packed and "packed " or "",
        field.repeated and "repeated " or "",
        field.name,
        pos,
        wtype,
        type,
        got
    )
    error(msg, 0)
end


---@param env protobuf.CodingEnv 环境
---@param field protobuf.Field 字段
---@param isProto3 boolean 是否为proto3
---@param isUnsigned boolean 是否为无符号整数
---@return any value 值
local function pushDefultFieldNumber(env, field, isProto3, isUnsigned)
    local value = nil
    if field.defaultValue then
        value = tointeger(field.defaultValue)
        if value == nil then return value end
        value = lpb_pushinteger(value, isUnsigned, env.LS.int64Mode)
    elseif isProto3 then
        value = 0
    end
    return value
end


---@type {[protobuf.FieldType]: fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)}
local switchPushDefaultField
switchPushDefaultField = {
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tbytes] = function(env, field, isProto3)
        if field.defaultValue then
            return true, field.defaultValue
        elseif isProto3 then
            return true, ""
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tstring] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tbytes](env, field, isProto3)
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tint32] = function(env, field, isProto3)
        local value = pushDefultFieldNumber(env, field, isProto3, false)
        if value then
            return true, value
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tint64] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tint32](env, field, isProto3)
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tbool] = function(env, field, isProto3)
        if field.defaultValue then
            local boolValue = field.defaultValue == "true"
            return true, boolValue
        elseif isProto3 then
            return true, false
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tdouble] = function(env, field, isProto3)
        if field.defaultValue then
            local value = tonumber(field.defaultValue)
            if value then
                return true, value
            end
        elseif isProto3 then
            return true, 0.0
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tfloat] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tdouble](env, field, isProto3)
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tenum] = function(env, field, isProto3)
        local type = field.type
        if not type then return false end
        local enumField = findName(type, field.defaultValue)
        if enumField then
            local value
            if env.LS.enumAsValue then
                value = lpb_pushinteger(enumField.number, true, env.LS.int64Mode)
            else
                value = enumField.name
            end
            return true, value
        elseif isProto3 then
            enumField = findField(type, 0)
            if enumField == nil or env.LS.enumAsValue then
                return true, 0
            else
                return true, enumField.name
            end
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tmessage] = function(env, field, isProto3)
        lpb_pushtypetable(env, field.type)
        return true
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tuint32] = function(env, field, isProto3)
        local value = pushDefultFieldNumber(env, field, isProto3, true)
        if value then
            return true, value
        end
        return false
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tuint64] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tuint32](env, field, isProto3)
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tfixed32] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tuint32](env, field, isProto3)
    end,
    ---@overload fun(env: protobuf.CodingEnv, field: protobuf.Field, isProto3: boolean): (boolean, any)
    [PB_Tfixed64] = function(env, field, isProto3)
        return switchPushDefaultField[PB_Tuint64](env, field, isProto3)
    end,
}


-- 获取默认字段的值
---@param env protobuf.CodingEnv 环境
---@param field protobuf.Field 字段
---@param isProto3 boolean 是否为proto3
---@return boolean success 是否成功
---@return any value 值
---@nodiscard
local function lpb_pushdeffield(env, field, isProto3)
    if field == nil then return false end
    return switchPushDefaultField[field.typeId](env, field, isProto3)
end


---@param env protobuf.CodingEnv 环境
---@param type protobuf.Type 类型
---@param flags protobuf.DefFlags 模式
---@param saveTable table 保存到的表
local function lpb_setdeffields(env, type, flags, saveTable)
    for _, field in pairs(type.field_tags) do
        local value = nil
        --  决定是否使用 `map_type` 或 `array_type`
        local fetchType = (field.type and field.type.isMap) and env.LS.mapType or env.LS.arrayType
        local hasField = false
        if field.repeated then
            -- 检查 `repeated` 字段
            if (flags & USE_REPEAT) ~= 0 and (type.is_proto3 or env.LS.decodeDefaultArray) then
                value = lpb_fetchtable(field, fetchType, saveTable) -- 获取或创建存储 `repeated` 字段的表
                hasField = true
            end
        else
            if field.oneofIdx == 0 then
                if field.typeId ~= PB_Tmessage then
                    hasField = (flags & USE_FIELD) ~= 0
                else
                    hasField = (flags & USE_MESSAGE) ~= 0 and env.LS.decodeDefaultMessage
                end
                if hasField then
                    hasField, value = lpb_pushdeffield(env, field, type.is_proto3)
                end
            end
        end
        if hasField then
            saveTable[field.name] = value
        end
    end
end

-- 获取指定类型默认的元表, 如果未设置, 则设置默认值
---@param env protobuf.CodingEnv
---@param type protobuf.Type
---@return table
local function getDefaultMetaTable(env, type)
    local defaultMetaTable = env.LS.defaultMetaTable
    if not defaultMetaTable[type] then
        defaultMetaTable[type] = {}
        lpb_setdeffields(env, type, USE_FIELD, defaultMetaTable[type])
    end
    return defaultMetaTable[type]
end


---@param env protobuf.CodingEnv
---@param type protobuf.Type
---@return table
lpb_pushtypetable = function(env, type)
    local LS = env.LS
    local newTable = {}
    local mode = LS.encodeMode -- 获取当前编码模式
    if type.is_proto3 and mode == LPB_DEFDEF then
        mode = LPB_COPYDEF
    end
    if mode == LPB_COPYDEF then
        lpb_setdeffields(env, type, (USE_FIELD | USE_REPEAT | USE_MESSAGE), newTable)
    elseif mode == LPB_METADEF then
        lpb_setdeffields(env, type, (USE_REPEAT | USE_MESSAGE), newTable)
        setmetatable(newTable, getDefaultMetaTable(env, type))
    else
        if LS.decodeDefaultArray or LS.decodeDefaultMessage then
            lpb_setdeffields(env, type, (USE_REPEAT | USE_MESSAGE), newTable)
        end
    end
    return newTable
end

---@param field protobuf.Field
---@param type protobuf.Type
---@param data table 数据
---@return table
lpb_fetchtable = function(field, type, data)
    local _value = data[field.name]
    if _value == nil then
        _value = {}
        data[field.name] = _value
    end
    if type.is_dead then return _value end
    --TODO 实现`array_type`的元表设置?
    return _value
end


---@param env protobuf.CodingEnv
---@param field protobuf.Field
---@return any value 值
---@nodiscard
local function lpbD_rawfield(env, field)
    local _newField = nil
    local value = nil
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    if field.typeId == PB_Tenum then
        local len, tag = pb_readvarint64(env.slice) ---@cast tag integer
        if len == 0 then
            error("invalid varint value at offset " .. (pb_pos(env.slice) + 1), 0)
        end
        if not env.LS.enumAsValue then
            _newField = findField(field.type, tag)
        end
        if _newField then
            value = _newField.name
        else
            value = lpb_pushinteger(tag, true, env.LS.int64Mode)
        end
    elseif field.typeId == PB_Tmessage then
        lpb_readbytes(env.slice, targetSlice);
        if field.type == nil or field.type.is_dead then
            value = nil
        else
            value = lpb_pushtypetable(env, field.type)
            local oldSlice = env.slice
            env.slice = targetSlice
            lpbD_message(env, field.type, value)
            env.slice = oldSlice
        end
    else
        value = lpb_readtype(env, field.typeId, env.slice)
    end
    return value
end


---@param env protobuf.CodingEnv 环境
---@param field protobuf.Field 字段
---@param tag integer 标签
---@return any value 值
---@nodiscard
local function lpbD_field(env, field, tag)
    lpbD_checktype(env, field, tag)
    return lpbD_rawfield(env, field)
end

---@param env protobuf.CodingEnv 环境
---@param field protobuf.Field 字段
---@param saveTable table 数据
local function lpbD_map(env, field, saveTable)
    local oldSlice = env.slice
    local len, tag
    local mask = 0
    ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
    local targetSlice = { _data = nil, start = nil, pos = nil, end_pos = nil } ---@type protobuf.Slice
    lpb_readbytes(oldSlice, targetSlice)
    local success, k, v
    -- 本循环仅会取出一对键值对
    while true do
        len, tag = pb_readvarint32(targetSlice) ---@cast tag integer
        if len == 0 then break end
        local n = pb_gettag(tag)
        if n == 1 or n == 2 then
            mask = mask | n
            env.slice = targetSlice
            local value = lpbD_field(
                env,
                ---@diagnostic disable-next-line: param-type-mismatch
                findField(field.type, n),
                tag
            )
            env.slice = oldSlice
            if n == 1 then
                k = value
            else
                v = value
            end
        end
    end
    -- 如果键不存在，则添加默认键
    if not (mask & 1) then
        success, k = lpb_pushdeffield(
            env,
            ---@diagnostic disable-next-line: param-type-mismatch
            findField(field.type, 1),
            true
        )
        if success then
            mask = mask | 1
        end
    end
    -- 如果值不存在，则添加默认值
    if not (mask & 2) then
        success, v = lpb_pushdeffield(
            env,
            ---@diagnostic disable-next-line: param-type-mismatch
            findField(field.type, 2),
            true
        )
        if success then
            mask = mask | 2
        end
    end
    -- 如果键和值都存在，则添加到表中
    if mask == 3 then
        rawset(saveTable, k, v)
    end
end

---@param env protobuf.CodingEnv 环境
---@param field protobuf.Field 字段
---@param tag integer 标签
---@param saveTable table 数据
local function lpbD_repeated(env, field, tag, saveTable)
    -- 检查tag是否为非 BYTES 类型，或者字段类型是非 packed 编码的 BYTES 类型
    if pb_gettype(tag) ~= PB_TBYTES or (not field.packed and pb_wtypebytype(field.typeId) == PB_TBYTES) then
        saveTable[#saveTable + 1] = lpbD_field(env, field, tag)
    else
        local len = #saveTable
        ---@diagnostic disable-next-line: missing-fields, assign-type-mismatch
        local targetSlice = { _data = nil, start = nil, pos = nil, end_pos = nil } ---@type protobuf.Slice
        local oldSlice = env.slice
        lpb_readbytes(env.slice, targetSlice)
        while targetSlice.pos < targetSlice.end_pos do
            env.slice = targetSlice
            saveTable[len + 1] = lpbD_rawfield(env, field)
            len = len + 1
        end
        env.slice = oldSlice
    end
end



---@param env protobuf.CodingEnv 环境
---@param protobufType protobuf.Type 类型
---@param saveTable table 保存到的表
lpbD_message = function(env, protobufType, saveTable)
    local s = env.slice
    local len, tag
    while true do
        len, tag = pb_readvarint32(s) ---@cast tag integer
        if len == 0 then break end
        local field = findField(protobufType, pb_gettag(tag))
        if field == nil then
            pb_skipvalue(s, tag)
        elseif field.type and field.type.isMap then
            lpbD_checktype(env, field, tag)
            lpbD_map(env, field, lpb_fetchtable(field, env.LS.mapType, saveTable))
        elseif field.repeated then
            lpbD_repeated(env, field, tag, lpb_fetchtable(field, env.LS.arrayType, saveTable))
        else
            if field.oneofIdx and field.oneofIdx ~= 0 then
                -- 设置oneof字段, oneof名称: 填入的目标字段名(不是值)
                rawset(saveTable, protobufType.oneof_index[field.oneofIdx].name, field.name)
            end
            rawset(saveTable, field.name, lpbD_field(env, field, tag))
        end
    end
end


-- 解码
---@param type string 需要解码的类型名
---@param data string 需要解码的二进制数据
---@param saveTable? table 如果不为空，则将解码后的数据保存到该表中
---@return any
function M.decode(type, data, saveTable)
    local globalState = getConfig()
    local protobufType = findInternalType(globalState, NewProtobufSlice(type))
    argcheck(protobufType ~= nil, "type '%s' does not exists", type)
    ---@cast protobufType protobuf.Type
    ---@type protobuf.CodingEnv
    local env = {
        LS = globalState,
        buffer = {},
        slice = NewProtobufSlice(data),
        ---@diagnostic disable-next-line: assign-type-mismatch
        saveTable = saveTable
    }
    
    if not env.saveTable then
        env.saveTable = lpb_pushtypetable(env, protobufType)
    end
    lpbD_message(env, protobufType, env.saveTable)
    return env.saveTable
end

return M
