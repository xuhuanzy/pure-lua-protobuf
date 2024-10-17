--#region 导入

local lpb_lstate = require("pb.state").lpb_lstate
local pb_field = require("pb.state").pb_field
local pb_fname = require("pb.state").pb_fname

local tryGetName = require("pb.names").tryGetName

local argcheck = require("pb.tool").argcheck
local checkTable = require("pb.tool").checkTable
local throw = require("pb.tool").throw

local pb_encode_sint32 = require("pb.tool").pb_encode_sint32
local expandsig32To64 = require("pb.tool").expandsig32To64
local pb_encode_sint64 = require("pb.tool").pb_encode_sint64
local lpb_tointegerx = require("pb.tool").lpb_tointegerx
local pb_encode_double = require("pb.tool").pb_encode_double
local pb_encode_float = require("pb.tool").pb_encode_float

local pb_addvarint32 = require("pb.bytes_operation").pb_addvarint32
local pb_addvarint64 = require("pb.bytes_operation").pb_addvarint64
local pb_addbytes = require("pb.bytes_operation").pb_addbytes
local pb_addfixed64 = require("pb.bytes_operation").pb_addfixed64
local pb_addfixed32 = require("pb.bytes_operation").pb_addfixed32
local pb_pair = require("pb.bytes_operation").pb_pair
local lpb_addlength = require("pb.bytes_operation").lpb_addlength

local pb_wtypebytype = require("pb.util").pb_wtypebytype
local lpb_toslice = require("pb.util").lpb_toslice
local pb_len = require("pb.util").pb_len
local pb_typename = require("pb.util").pb_typename
local lpb_expected = require("pb.util").lpb_expected
local NewProtobufSlice = require("pb.util").ProtobufSlice.new

local lpb_type = require("pb.search").lpb_type


local ConstantDefine = require "pb.ConstantDefine"
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
local PB_Tgroup = ConstantDefine.pb_FieldType.PB_Tgroup



local tableInsert = table.insert
local tableRemove = table.remove
local ipairs      = ipairs
local pairs       = pairs
local error       = error
local assert      = assert
local type        = type
local tonumber    = tonumber
local stringChar  = string.char
local tableUnpack = table.unpack
local rawget      = rawget
local rawset      = rawset

--#endregion

---@class Protobuf.Encode
local M           = {}

--#region 声明

---@class lpb_Env
---@field LS lpb_State
---@field b protobuf.Char[]
---@field s protobuf.Slice
---@field saveTable table 保存解码后的数据



--#endregion

local encode



--#region 字节操作


--#endregion



---@type {[pb_FieldType]: fun(env: lpb_Env, type: integer, value: any, exist: Protobuf._TempVar.Exist): integer}
local switchAddType
switchAddType = {
    [PB_Tbool] = function(env, type, value, exist)
        if exist then exist[1] = true end
        return pb_addvarint32(env.b, (not not value) and 1 or 0)
    end,

    [PB_Tdouble] = function(env, type, value, exist)
        local receivedValue = tonumber(value)
        if receivedValue then
            if exist then exist[1] = receivedValue ~= 0.0 end
            return pb_addfixed64(env.b, pb_encode_double(receivedValue))
        end
        return 0
    end,

    [PB_Tfloat] = function(env, type, value, exist)
        local receivedValue = tonumber(value)
        if receivedValue then
            if exist then exist[1] = receivedValue ~= 0.0 end
            return pb_addfixed32(env.b, pb_encode_float(receivedValue))
        end
        return 0
    end,

    [PB_Tfixed32] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addfixed32(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tsfixed32] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addfixed32(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tint32] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint64(env.b, expandsig32To64(receivedValue))
        end
        return 0
    end,

    [PB_Tuint32] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint32(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tsint32] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint32(env.b, pb_encode_sint32(receivedValue))
        end
        return 0
    end,

    [PB_Tfixed64] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addfixed64(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tsfixed64] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addfixed64(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tint64] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint64(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tuint64] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint64(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tsint64] = function(env, type, value, exist)
        local receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            if exist then exist[1] = (receivedValue ~= 0) end
            return pb_addvarint64(env.b, pb_encode_sint64(receivedValue))
        end
        return 0
    end,

    [PB_Tbytes] = function(env, type, value, exist)
        local receivedValue = lpb_toslice(value)
        if receivedValue.pos then
            if exist then exist[1] = (pb_len(receivedValue) > 0) end
            return pb_addbytes(env.b, receivedValue)
        end
        return 0
    end,

    [PB_Tstring] = function(env, type, value, exist)
        local receivedValue = lpb_toslice(value)
        if receivedValue.pos then
            if exist then exist[1] = (pb_len(receivedValue) > 0) end
            return pb_addbytes(env.b, receivedValue)
        end
        return 0
    end,
}



---@param env lpb_Env
---@param type integer
---@param value any
---@param exist? Protobuf._TempVar.Exist 是否存在
---@return integer
local function lpb_addtype(env, type, value, exist)
    return switchAddType[type](env, type, value, exist)
end

---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
---@param exist? Protobuf._TempVar.Exist 是否存在
---@return integer len 写入的字节长度
local function lpbE_enum(env, field, value, exist)
    local luaType = type(value)

    if luaType == "number" then
        value = tonumber(value)
        ---@cast value number
        if exist then
            exist[1] = value ~= 0
        end
        return pb_addvarint64(env.b, value)
    end
    ---@cast value any

    local ev = pb_fname(field.type, tryGetName(env.LS.state, value))
    if ev then
        if exist then
            exist[1] = ev.number ~= 0
        end
        return pb_addvarint32(env.b, ev.number)
    end

    if luaType == "string" then
        local v, isInit = lpb_tointegerx(value)
        if not isInit then
            argcheck(false, "can not encode unknown enum '%s' at field '%s'", value, field.name)
        end
        ---@cast v number
        if exist then exist[1] = v ~= 0 end
        return pb_addvarint64(env.b, v)
    end
    argcheck(false, "number/string expected at field '%s', got %s", field.name, luaType)
    return 0
end


---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
---@param exist? Protobuf._TempVar.Exist 是否存在
---@return integer length 写入的字节长度
local function lpbE_field(env, field, value, exist)
    if field.type_id == PB_Tenum then
        return lpbE_enum(env, field, value, exist)
    elseif field.type_id == PB_Tmessage then
        checkTable(field, value)
        pb_addvarint32(env.b, 0)
        local len = #env.b
        encode(env, field.type, value)
        if exist then
            exist[1] = len < #env.b
        end
        return lpb_addlength(env.b, len, 1)
    else
        local len = lpb_addtype(env, field.type_id, value, exist)
        if not (len > 0) then
            throw("expected %s for field '%s', got %s", lpb_expected(field.type_id), field.name, type(value))
        end
        return len
    end
end

---@class Protobuf._TempVar.Exist
---@field [1] boolean 是否存在

---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
---@param ignoreZero boolean 是否忽略值为零的字段
local function lpbE_tagfield(env, field, value, ignoreZero)
    local buffer = env.b
    ---@type Protobuf._TempVar.Exist
    local exist = { false }
    local tagLength = pb_addvarint32(buffer, pb_pair(field.number, pb_wtypebytype(field.type_id)))
    -- 编码, 然后返回编码的字节数
    local ignoredLen = lpbE_field(env, field, value, exist)
    -- 不使用默认值, 并且不存在, 并且忽略零值
    if not env.LS.encode_default_values and not exist[1] and ignoreZero then
        -- 需要`+1`, 否则会删掉目标更早的字节(因为lua的下标从1开始)
        local removeStartIndex = #buffer - (tagLength + ignoredLen) + 1
        -- 该字段应该被忽略
        -- 删除编码的字节
        for i = #buffer, removeStartIndex, -1 do
            tableRemove(buffer, i)
        end
    end
end



-- 解析`map`类型(不是`Lua`的`table`类型而是`protobuf`的`map`类型)
---@param env lpb_Env
---@param field Protobuf.Field
---@param map table
local function lpbE_map(env, field, map)
    local kf = pb_field(field.type, 1)
    local vf = pb_field(field.type, 2)
    if not kf or not vf then
        return
    end
    checkTable(field, map)
    for key, value in pairs(map) do
        -- 写入字段编号与类型
        pb_addvarint32(env.b, pb_pair(field.number, PB_TBYTES))
        -- 写入占位符
        pb_addvarint32(env.b, 0)
        -- 获取已写入长度
        local len = #env.b
        -- 写入键
        lpbE_tagfield(env, kf, key, true)
        -- 写入值
        lpbE_tagfield(env, vf, value, true)
        -- 写入长度
        lpb_addlength(env.b, len, 1)
    end
end

---@param env lpb_Env
---@param field Protobuf.Field
---@param data any
local function lpbE_repeated(env, field, data)
    checkTable(field, data)
    if field.packed then
        -- 如果数据为空, 并且不编码默认值, 则不写入数据
        if #data == 0 and not env.LS.encode_default_values then
            return
        end
        pb_addvarint32(env.b, pb_pair(field.number, PB_TBYTES))
        pb_addvarint32(env.b, 0)
        local len = #env.b
        for _, value in ipairs(data) do
            lpbE_field(env, field, value, nil)
        end
        lpb_addlength(env.b, len, 1)
    else
        for _, value in ipairs(data) do
            lpbE_tagfield(env, field, value, false)
        end
    end
end

---@param env lpb_Env
---@param protobufType Protobuf.Type
---@param value any
---@param field Protobuf.Field
local function lpb_encode_onefield(env, protobufType, value, field)
    if field.type and field.type.is_map then
        lpbE_map(env, field, value)
    elseif field.repeated then
        lpbE_repeated(env, field, value)
    elseif not field.type or not field.type.is_dead then
        lpbE_tagfield(env, field, value,
            protobufType.is_proto3 and (field.oneof_idx and field.oneof_idx >= 1) and field.type_id ~= PB_Tmessage
        )
    end
end

---@param env lpb_Env
---@param protobufType Protobuf.Type
---@param data table
encode = function(env, protobufType, data)
    for _, field in pairs(protobufType.field_tags) do
        local value = rawget(data, field.name)
        if value then
            lpb_encode_onefield(env, protobufType, value, field)
        end
    end
end


---编码入口
---@param type string
---@param data table
---@return string
function M.encode(type, data)
    local globalState = lpb_lstate()
    local protobufType = lpb_type(globalState, NewProtobufSlice(type))
    if not protobufType then
        error("unknown type: " .. type)
    end
    ---@type lpb_Env
    local env = {
        LS = globalState,
        b = {},
        ---@diagnostic disable-next-line: missing-fields
        s = {},
        ---@diagnostic disable-next-line: assign-type-mismatch
        saveTable = nil
    }
    encode(env, protobufType, data)
    return stringChar(tableUnpack(env.b))
end

return M
