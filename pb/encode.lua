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
local tableRemove = table.remove

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
---@param exist? Protobuf._TempVar.Exist 是否存在
---@return integer
function M.lpb_addtype(env, type, value, exist)
    local b = env.b
    local len = 0
    local receivedValue = nil
    local hasData = true
    local hasResult = false
    if type == PB_Tbool then
        len = BytesOperation.pb_addvarint32(b, (not not value) and 1 or 0)
        hasResult = true
    elseif type == PB_Tdouble then
        receivedValue = tonumber(value)
        if receivedValue then
            len = BytesOperation.pb_addfixed64(b, receivedValue)
            hasResult = true
            hasData = receivedValue ~= 0.0
        end
    elseif type == PB_Tfloat then
        receivedValue = tonumber(value)
        if receivedValue then
            len = BytesOperation.pb_addfixed32(b, receivedValue)
            hasResult = true
            hasData = receivedValue ~= 0.0
        end
    elseif type == PB_Tfixed32 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addfixed32(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tsfixed32 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addfixed32(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tint32 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint64(b, expandsig32To64(receivedValue))
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tuint32 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint32(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tsint32 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint32(b, pb_encode_sint32(receivedValue))
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tfixed64 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addfixed64(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tsfixed64 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addfixed64(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tint64 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint64(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tuint64 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint64(b, receivedValue)
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tsint64 then
        receivedValue, hasResult = lpb_tointegerx(value)
        if hasResult then
            len = BytesOperation.pb_addvarint64(b, pb_encode_sint64(receivedValue))
            hasData = receivedValue ~= 0
        end
    elseif type == PB_Tbytes or type == PB_Tstring then
        receivedValue = util.lpb_toslice(value)
        hasResult = receivedValue.pos ~= nil
        if hasResult then
            len = BytesOperation.pb_addbytes(b, receivedValue)
            hasData = util.pb_len(receivedValue) > 0
        end
    else
        error("unknown type " .. util.pb_typename(type))
    end
    if exist then exist[1] = (hasResult and hasData) end
    return hasResult and len or 0
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

    local ev = State.pb_fname(field.type, Name_getName(env.LS.state, util.pb_slice(value)))
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
        return BytesOperation.lpb_addlength(env.b, len, 1)
    else
        local len = M.lpb_addtype(env, field.type_id, value, exist)
        argcheck(len > 0, "expected %s for field '%s', got %s", util.lpb_expected(field.type_id), field.name, type(value))
        return len
        ---@diagnostic disable-next-line: missing-return
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
    local tagLength = pb_addvarint32(buffer, decode.pb_pair(field.number, decode.pb_wtypebytype(field.type_id)))
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
        lpbE_tagfield(env, kf, key, true)
        -- 写入值
        lpbE_tagfield(env, vf, value, true)
        -- 写入长度
        BytesOperation.lpb_addlength(env.b, len, 1)
    end
end


--[[ static void lpbE_repeated(lpb_Env *e, const pb_Field *f, int idx) {
    lua_State *L = e->L;
    pb_Buffer *b = e->b;
    int i;
    lpb_checktable(L, f, idx);

    if (f->packed) {
        unsigned len, bufflen = pb_bufflen(b);
        lpb_checkmem(L, pb_addvarint32(b, pb_pair(f->number, PB_TBYTES)));
        lpb_checkmem(L, pb_addvarint32(b, 0));
        len = pb_bufflen(b);
        for (i = 1; lua53_rawgeti(L, idx, i) != LUA_TNIL; ++i) {
            lpbE_field(e, f, NULL, -1);
            lua_pop(L, 1);
        }
        if (i == 1 && !e->LS->encode_default_values)
            pb_bufflen(b) = bufflen;
        else
            lpb_addlength(L, b, len, 1);
    } else {
        for (i = 1; lua53_rawgeti(L, idx, i) != LUA_TNIL; ++i) {
            lpbE_tagfield(e, f, 0, -1);
            lua_pop(L, 1);
        }
    }
    lua_pop(L, 1);
} ]]
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
        pb_addvarint32(env.b, decode.pb_pair(field.number, PB_TBYTES))
        pb_addvarint32(env.b, 0)
        local len = #env.b
        for _, value in ipairs(data) do
            lpbE_field(env, field, value, nil)
        end
        BytesOperation.lpb_addlength(env.b, len, 1)
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
    for _, field in ipairs(protobufType.field_tags) do
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
    return string.char(table.unpack(env.b))
end

return M
