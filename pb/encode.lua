--#region 导入

local State = require("pb.state")
local decode = require("pb.decode")
local util = require("pb.util")

local pb_name = require("pb.name").pb_name
local Name_getName = require("pb.name").getName

local argcheck = require("pb.tool").argcheck
local pb_encode_sint32 = require("pb.tool").pb_encode_sint32
local expandsig32To64 = require("pb.tool").expandsig32To64
local pb_encode_sint64 = require("pb.tool").pb_encode_sint64
local lpb_tointegerx = require("pb.tool").lpb_tointegerx

local BytesOperation = require("pb.BytesOperation")
local pb_addvarint32 = BytesOperation.pb_addvarint32
local pb_addvarint64 = BytesOperation.pb_addvarint64


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

--#endregion

---@class Protobuf.Encode
local M = {}

--#region 声明

---@class lpb_Env
---@field LS lpb_State
---@field b Protobuf.Char[]
---@field s pb_Slice



--#endregion

local encode



--#region 字节操作


--#endregion

---@param field Protobuf.Field
---@param data any
local function checkTable(field, data)
    argcheck(
        type(data) == "table",
        "table expected at field '%s', got %s",
        field.name, type(data)
    )
end

-- 搜索类型
---@param LS lpb_State
---@param s pb_Slice
---@return Protobuf.Type?
local function lpb_type(LS, s)
    local t
    -- 0: `\0`   46: '.'
    if s.pos == nil or s._data[1] == 0 or s._data[1] == 46 then
        local nameEntry = pb_name(LS.state, s)
        if nameEntry then
            t = State.pb_type(LS.state, nameEntry.name)
        end
    else
        local copy = util.sliceCopy(s)
        -- `46` 等价于`string.byte(".")`
        tableInsert(copy._data, 1, 46)
        copy.end_pos = copy.end_pos + 1
        local nameEntry = pb_name(LS.state, copy)
        if nameEntry then
            t = State.pb_type(LS.state, nameEntry.name)
        end
    end
    return t
end



---@param env lpb_Env
---@param type integer
---@param value any
---@return integer
function M.lpb_addtype(env, type, value)
    local b = env.b
    local len = 0
    local has_data = false
    if type == PB_Tbool then
        BytesOperation.pb_addvarint32(b, (not not value) and 1 or 0)
    elseif type == PB_Tdouble then
        local v = tonumber(value)
        if v then
            len = BytesOperation.pb_addfixed64(b, v)
            has_data = v ~= 0.0
        end
    elseif type == PB_Tfloat then
        local v = tonumber(value)
        if v then
            len = BytesOperation.pb_addfixed32(b, v)
            has_data = v ~= 0.0
        end
    elseif type == PB_Tfixed32 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addfixed32(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tsfixed32 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addfixed32(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tint32 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint64(b, expandsig32To64(v))
            has_data = v ~= 0
        end
    elseif type == PB_Tuint32 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint32(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tsint32 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint32(b, pb_encode_sint32(v))
            has_data = v ~= 0
        end
    elseif type == PB_Tfixed64 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addfixed64(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tsfixed64 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addfixed64(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tint64 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint64(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tuint64 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint64(b, v)
            has_data = v ~= 0
        end
    elseif type == PB_Tsint64 then
        local v, success = lpb_tointegerx(value)
        if success then
            len = BytesOperation.pb_addvarint64(b, pb_encode_sint64(v))
            has_data = v ~= 0
        end
    elseif type == PB_Tbytes then
        local v = util.lpb_toslice(value)
        if v.pos then
            len = BytesOperation.pb_addbytes(b, v)
            has_data = util.pb_len(v) > 0
        end
    elseif type == PB_Tstring then
        local v = util.lpb_toslice(value)
        if v.pos then
            len = BytesOperation.pb_addbytes(b, v)
            has_data = util.pb_len(v) > 0
        end
    else
        error("unknown type " .. util.pb_typename(type))
    end
    return has_data and len or 0
end

---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
---@return integer
local function lpbE_enum(env, field, value)
    local luaType = type(value)

    if luaType == "number" then
        value = tonumber(value)
        ---@cast value number
        return pb_addvarint64(env.b, value)
    end
    ---@cast value any

    local ev = State.pb_fname(field.type, Name_getName(env.LS.state, util.pb_slice(value)))
    if ev then
        return pb_addvarint32(env.b, ev.number)
    end

    if luaType == "string" then
        local v, isInit = lpb_tointegerx(value)
        if not isInit then
            argcheck(false, "can not encode unknown enum '%s' at field '%s'", value, field.name)
        end
        ---@cast v number
        return pb_addvarint64(env.b, v)
    end
    argcheck(false, "number/string expected at field '%s', got %s", field.name, luaType)
    return 0
end


---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
---@return integer
local function lpbE_field(env, field, value)
    if field.type_id == PB_Tenum then
        return lpbE_enum(env, field, value)
    elseif field.type_id == PB_Tmessage then
        checkTable(field, value)
        pb_addvarint32(env.b, 0)
        local len = #env.b
        encode(env, field.type, value)
    else
        local len = M.lpb_addtype(env, field.type_id, value)
        argcheck(len > 0, "expected %s for field '%s', got %s", util.lpb_expected(field.type_id), field.name, type(value))
        return len
        ---@diagnostic disable-next-line: missing-return
    end
end

--[[
static void lpbE_tagfield(lpb_Env *e, const pb_Field *f, int ignorezero, int idx) {
    size_t hlen = lpb_checkmem(e->L, pb_addvarint32(e->b,
            pb_pair(f->number, pb_wtypebytype(f->type_id))));
    int exist;
    size_t ignoredlen = lpbE_field(e, f, &exist, idx);
    if (!e->LS->encode_default_values && !exist && ignorezero)
        e->b->size -= (unsigned)(ignoredlen + hlen);
}
 ]]
---@param env lpb_Env
---@param field Protobuf.Field
---@param value any
local function lpbE_tagfield(env, field, value)
    local hlen = pb_addvarint32(env.b, decode.pb_pair(field.number, decode.pb_wtypebytype(field.type_id)))
    local ignoredLen = lpbE_field(env, field, value)
end

-- 解析`map`类型(不是`Lua`的`table`类型而是`protobuf`的`map`类型)
---@param env lpb_Env
---@param field Protobuf.Field
---@param map table
local function lpbE_map(env, field, map)
    local kf = State.pb_field(field.type, 1)
    local vf = State.pb_field(field.type, 2)
    if not kf or not vf then
        return
    end
    checkTable(field, map)
    for key, value in pairs(map) do
        -- 写入字段编号与类型
        pb_addvarint32(env.b, decode.pb_pair(field.number, PB_TBYTES))
        -- 写入占位符
        pb_addvarint32(env.b, 0)
        -- 获取已写入长度
        local len = #env.b
        -- 写入键
        lpbE_tagfield(env, kf, key)
        -- 写入值
        lpbE_tagfield(env, vf, value)
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
    elseif not field.type or not field.type.is_dead then
        lpbE_tagfield(env, field, value)
    end
end

---@param env lpb_Env
---@param protobufType Protobuf.Type
---@param data table
encode = function(env, protobufType, data)
    for _, field in ipairs(protobufType.field_tags) do
        local value = rawget(data, field.name)
        lpb_encode_onefield(env, protobufType, value, field)
    end
end


---编码入口
---@param type string
---@param data table
function M.encode(type, data)
    local globalState = State.lpb_lstate()
    local protobufType = lpb_type(globalState, util.pb_slice(type))
    assert(protobufType, "unknown type: " .. type)
    ---@type lpb_Env
    local env = {
        LS = globalState,
        b = {},
        ---@diagnostic disable-next-line: missing-fields
        s = {},
    }
    encode(env, protobufType, data)
end

return M
