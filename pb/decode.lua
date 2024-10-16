local util = require("pb.util")

local State = require("pb.state")
local pb_field = State.pb_field
local pb_fname = State.pb_fname
local pb_type = State.pb_type

local lpb_type = require("pb.search").lpb_type
local argcheck = require("pb.tool").argcheck
local pb_name = require("pb.name").pb_name

local BytesOperation = require("pb.BytesOperation")
local pb_pair = BytesOperation.pb_pair
local pb_readvarint32 = BytesOperation.pb_readvarint32
local pb_readvarint64 = BytesOperation.pb_readvarint64
local pb_skipvalue = BytesOperation.pb_skipvalue
local pb_readbytes = BytesOperation.pb_readbytes
local pb_gettag = BytesOperation.pb_gettag
local pb_gettype = BytesOperation.pb_gettype
local lpb_readbytes = BytesOperation.lpb_readbytes
local lpb_pushinteger = BytesOperation.lpb_pushinteger
local lpb_readtype = BytesOperation.lpb_readtype

local pb_wtypebytype = require("pb.util").pb_wtypebytype
local pb_wtypename = require("pb.util").pb_wtypename
local pb_typename = require("pb.util").pb_typename
local pb_pos = require("pb.util").pb_pos


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


---@class Protobuf.Decode
local M = {}

--提前声明

local lpb_fetchtable
local lpb_pushtypetable
local lpbD_message

---@param env lpb_Env
---@param field Protobuf.Field
---@param tag integer
local function lpbD_checktype(env, field, tag)
    if pb_wtypebytype(field.type_id) == pb_gettype(tag) then return end
    local s = env.s
    local pos = (s.pos - s.start) + 1
    local wtype = pb_wtypename(pb_wtypebytype(field.type_id))
    local type = pb_typename(field.type_id)
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



-- 获取默认字段的值
---@param env lpb_Env 环境
---@param field Protobuf.Field 字段
---@param isProto3 boolean 是否为proto3
---@return boolean success 是否成功
---@return any value 值
local function lpb_pushdeffield(env, field, isProto3)
    if field == nil then return false end
    local typeId = field.type_id
    local isUnsigned = false -- 是否为无符号整数
    local success = false
    local value = nil
    if typeId == PB_Tenum then
        local type = field.type
        if not type then return false end
        ---@diagnostic disable-next-line: cast-local-type
        field = pb_fname(type, field.default_value)
        if field then
            if env.LS.enum_as_value then
                value = lpb_pushinteger(field.number, true, env.LS.int64_mode)
            else
                value = field.name
            end
            success = true
        elseif isProto3 then
            ---@diagnostic disable-next-line: cast-local-type
            field = pb_field(type, 0)
            -- 默认值为`0`
            if field or env.LS.enum_as_value then
                value = 0
            else
                ---@cast field Protobuf.Field
                value = field.name
            end
            success = true
        end
    elseif typeId == PB_Tmessage then
        lpb_pushtypetable(env, field.type)
        success = true
    elseif typeId == PB_Tbytes or typeId == PB_Tstring then
        if field.default_value then
            value = field.default_value
        elseif isProto3 then
            value = ""
        end
        success = true
    elseif typeId == PB_Tbool then
        if field.default_value then
            if field.default_value == "true" then
                value = true
            elseif field.default_value == "false" then
                value = false
            end
        elseif isProto3 then
            value = false
        end
        success = true
    elseif typeId == PB_Tdouble or typeId == PB_Tfloat then
        if field.default_value then
            value = tonumber(field.default_value)
            if value == nil then return false end
        elseif isProto3 then
            value = 0.0
        end
        success = true
    elseif typeId == PB_Tuint64 or typeId == PB_Tfixed64 or typeId == PB_Tfixed32 or typeId == PB_Tuint32 then
        isUnsigned = true
    else
        if field.default_value then
            value = tointeger(field.default_value)
            if value == nil then return false end
            value = lpb_pushinteger(value, isUnsigned, env.LS.int64_mode)
        elseif isProto3 then
            value = 0
        end
        success = true
    end
    return success, value
end


---@param env lpb_Env 环境
---@param type Protobuf.Type 类型
---@param flags Protobuf.DefFlags 模式
---@param saveTable table 保存到的表
local function lpb_setdeffields(env, type, flags, saveTable)
    for _, field in pairs(type.field_tags) do
        local value = nil
        --  决定是否使用 `map_type` 或 `array_type`
        local fetchType = (field.type and field.type.is_map) and env.LS.map_type or env.LS.array_type
        local hasField = false
        if field.repeated then
            -- 检查 `repeated` 字段
            if (flags & USE_REPEAT) ~= 0 and (type.is_proto3 or env.LS.decode_default_array) then
                value = lpb_fetchtable(field, fetchType, saveTable) -- 获取或创建存储 `repeated` 字段的表
                hasField = true
            end
        else
            if field.oneof_idx == 0 then
                if field.type_id ~= PB_Tmessage then
                    hasField = (flags & USE_FIELD) ~= 0
                else
                    hasField = (flags & USE_MESSAGE) ~= 0 and env.LS.decode_default_message
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



---@param env lpb_Env
---@param type Protobuf.Type
---@return table
lpb_pushtypetable = function(env, type)
    local LS = env.LS
    local newTable = {}
    local mode = LS.encode_mode -- 获取当前编码模式
    if type.is_proto3 and mode == LPB_DEFDEF then
        mode = LPB_COPYDEF
    end
    if mode == LPB_COPYDEF then
        lpb_setdeffields(env, type, (USE_FIELD | USE_REPEAT | USE_MESSAGE), newTable)
    elseif mode == LPB_METADEF then
        lpb_setdeffields(env, type, (USE_REPEAT | USE_MESSAGE), newTable)
        --TODO 需要设置元表
    else
        if LS.decode_default_array or LS.decode_default_message then
            lpb_setdeffields(env, type, (USE_REPEAT | USE_MESSAGE), newTable)
        end
    end
    return newTable
end

---@param field Protobuf.Field
---@param type Protobuf.Type
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


---@param env lpb_Env
---@param field Protobuf.Field
---@param saveTable table
---@return any value 值
---@nodiscard
local function lpbD_rawfield(env, field, saveTable)
    local _newField = nil
    local value = nil
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {}
    if field.type_id == PB_Tenum then
        local len, tag = pb_readvarint64(env.s) ---@cast tag integer
        if len == 0 then
            error("invalid varint value at offset " .. (pb_pos(env.s) + 1), 0)
        end
        if not env.LS.enum_as_value then
            _newField = pb_field(field.type, tag)
        end
        if _newField then
            value = _newField.name
        else
            value = lpb_pushinteger(tag, true, env.LS.int64_mode)
        end
    elseif field.type_id == PB_Tmessage then
        lpb_readbytes(env.s, targetSlice);
        if field.type == nil or field.type.is_dead then
            value = nil
        else
            value = lpb_pushtypetable(env, field.type)
            local oldSlice = env.s
            env.s = targetSlice
            lpbD_message(env, field.type, value)
            env.s = oldSlice
        end
    else
        value = lpb_readtype(env, field.type_id, env.s)
    end
    return value
end


---@param env lpb_Env 环境
---@param field Protobuf.Field 字段
---@param tag integer 标签
---@param saveTable table 数据
---@return any value 值
---@nodiscard
local function lpbD_field(env, field, tag, saveTable)
    lpbD_checktype(env, field, tag)
    return lpbD_rawfield(env, field, saveTable)
end



---@param env lpb_Env 环境
---@param field Protobuf.Field 字段
---@param tag integer 标签
---@param saveTable table 数据
local function lpbD_repeated(env, field, tag, saveTable)
    local value
    -- 检查tag是否为非 BYTES 类型，或者字段类型是非 packed 编码的 BYTES 类型
    if pb_gettype(tag) ~= PB_TBYTES or (not field.packed and pb_wtypebytype(field.type_id) == PB_TBYTES) then
        value = lpbD_field(env, field, tag, saveTable)
        saveTable[#saveTable + 1] = value
    else
        local len = #saveTable
        ---@type pb_Slice
        ---@diagnostic disable-next-line: missing-fields
        local targetSlice = {}
        local oldSlice = env.s
        lpb_readbytes(env.s, targetSlice)
        while targetSlice.pos < targetSlice.end_pos do
            env.s = targetSlice
            value = lpbD_rawfield(env, field, saveTable)
            env.s = oldSlice
            len = len + 1
            saveTable[len] = value
        end
    end
end



---@param env lpb_Env 环境
---@param protobufType Protobuf.Type 类型
---@param saveTable table 保存到的表
lpbD_message = function(env, protobufType, saveTable)
    local s = env.s
    while true do
        local len, tag = pb_readvarint32(s) ---@cast tag integer
        if len == 0 then break end
        local field = State.pb_field(protobufType, pb_gettag(tag))
        if field == nil then
            pb_skipvalue(s, tag)
        elseif field.type and field.type.is_map then
        elseif field.repeated then
            local _newSaveTable = lpb_fetchtable(field, env.LS.array_type, saveTable)
            lpbD_repeated(env, field, tag, _newSaveTable)
        else
            local key = field.name
            if field.oneof_idx and field.oneof_idx ~= 0 then
                local oneof_key = protobufType.oneof_index[field.oneof_idx].name
                rawset(saveTable, oneof_key, key)
            end
            local value = lpbD_field(env, field, tag, saveTable)
            rawset(saveTable, key, value)
        end
    end
end


-- 解码
---@param type string 需要解码的类型名
---@param data string 需要解码的二进制数据
---@param saveTable? table 如果不为空，则将解码后的数据保存到该表中
---@return any
function M.decode(type, data, saveTable)
    local globalState = State.lpb_lstate()
    local protobufType = lpb_type(globalState, util.pb_slice(type))
    argcheck(protobufType ~= nil, "type '%s' does not exists", type)
    ---@cast protobufType Protobuf.Type
    ---@type lpb_Env
    local env = {
        LS = globalState,
        b = {},
        s = util.pb_slice(data),
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
