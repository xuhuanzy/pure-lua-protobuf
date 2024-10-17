local fileDescriptor = require("pb.file_descriptor")

local State = require("pb.state")

local pb_addslice = require("pb.bytes_operation").pb_addslice

local ProtobufType = require "pb.type".ProtobufType
local ProtobufField = require "pb.field".ProtobufField

local ConstantDefine = require "pb.ConstantDefine"
local PB_Tmessage = ConstantDefine.pb_FieldType.PB_Tmessage
local PB_Tenum = ConstantDefine.pb_FieldType.PB_Tenum

local charArrayToString = require("pb.util").charArrayToString
local NewProtobufSlice = require("pb.util").ProtobufSlice.new


local tryGetName = require("pb.names").tryGetName

local tableInsert = table.insert


---@class pb_Loader
---@field s protobuf.Slice 需要处理的数据
---@field is_proto3 boolean 是否是proto3
---@field b protobuf.Char[] 自己的数据

---@class PB.Loader
local M = {}


---@param state pb_State
---@param s protobuf.Slice
---@param loader pb_Loader
---@param isoOut boolean
---@return protobuf.NameValue? name 名称
---@return integer curPos 当前位置
local function pbL_prefixname(state, s, loader, isoOut)
    local curPos = #loader.b
    -- `46` 等价于`string.byte(".")`
    loader.b[#loader.b + 1] = 46
    pb_addslice(loader.b, s)
    if not isoOut then
        return nil, curPos
    end
    return tryGetName(state, charArrayToString(loader.b)), curPos
end



---@param state pb_State
---@param tname? protobuf.NameValue
---@return Protobuf.Type?
local function pb_newtype(state, tname)
    if not tname then return nil end
    if not state.types[tname] then
        state.types[tname] = ProtobufType.new(tname)
    end
    local t = state.types[tname]
    t.is_dead = false
    return t
end

---@param state pb_State
---@param type Protobuf.Type
---@param tname? protobuf.NameValue
---@param number integer
---@return Protobuf.Field?
local function pb_newfield(state, type, tname, number)
    if not tname then return nil end
    local nf = type.field_names[tname]
    local tf = type.field_tags[number]
    if nf and tf and nf == tf then
        print(string.format("pb_newfield pb_delname: %s number: %d", tname, number))
        --TODO 删除默认值
        return nf
    end
    local f = ProtobufField.new(tname, type, number)
    -- 字段数量统计增加
    type.field_count = type.field_count + 1
    -- 清除字段排序
    type.field_sort = nil
    -- 设置字段
    type.field_names[tname] = f
    type.field_tags[number] = f
    return f
end

---@param state pb_State
---@param info pbL_EnumInfo
---@param L pb_Loader
local function pbL_loadEnum(state, info, L)
    local prefixname, curPos = pbL_prefixname(state, info.name, L, true)
    assert(prefixname, "name error")
    local t = pb_newtype(state, prefixname)
    assert(t, "newtype error")
    t.is_enum = true
    for i, enumTypeInfo in ipairs(info.value) do
        local name = tryGetName(state, enumTypeInfo.name)
        assert(name, "nameEntry error")
        pb_newfield(state, t, name, enumTypeInfo.number)
    end
    --删除后面的名称
    for i = curPos + 1, #L.b do
        L.b[i] = nil
    end
end


---@param state pb_State
---@param info pbL_FieldInfo
---@param L pb_Loader
---@param type Protobuf.Type?
local function pbL_loadField(state, info, L, type)
    local ft
    if info.type == PB_Tmessage or info.type == PB_Tenum then
        ft = pb_newtype(state, tryGetName(state, info.type_name))
    end
    ---@cast ft Protobuf.Type

    if not type then
        type = pb_newtype(state, tryGetName(state, info.extendee))
    end
    ---@cast type Protobuf.Type
    local f = pb_newfield(state, type, tryGetName(state, info.name), info.number)
    assert(f)
    f.default_value = tryGetName(state, info.default_value)
    f.type = ft
    f.oneof_idx = info.oneof_index
    if f.oneof_idx and f.oneof_idx ~= 0 then
        type.oneof_field = type.oneof_field + 1
    end
    f.type_id = info.type
    f.repeated = info.label == 3
    if info.packed ~= nil then
        f.packed = info.packed
    else
        f.packed = L.is_proto3 and f.repeated
    end
    if f.type_id >= 9 and f.type_id <= 12 then
        f.packed = false
    end
    f.scalar = (f.type == nil)
end



---@param state pb_State
---@param info pbL_TypeInfo
---@param L pb_Loader
local function pbL_loadType(state, info, L)
    local prefixname, curPos = pbL_prefixname(state, info.name, L, true)
    local t = pb_newtype(state, prefixname)
    assert(t)
    t.is_map = info.is_map
    t.is_proto3 = L.is_proto3
    for i, oneofDecl in ipairs(info.oneof_decl) do
        local e = t.oneof_index[i] or {}
        ---@diagnostic disable-next-line: assign-type-mismatch
        e.name = tryGetName(state, oneofDecl)
        e.index = i
        t.oneof_index[i] = e
    end
    for _, field in ipairs(info.field) do
        pbL_loadField(state, field, L, t)
    end
    for _, extension in ipairs(info.extension) do
        pbL_loadField(state, extension, L, nil)
    end
    for _, enumTypeInfo in ipairs(info.enum_type) do
        pbL_loadEnum(state, enumTypeInfo, L)
    end
    for _, nestedTypeInfo in ipairs(info.nested_type) do
        pbL_loadType(state, nestedTypeInfo, L)
    end
    t.oneof_count = #info.oneof_decl
    --删除后面的名称
    for i = curPos + 1, #L.b do
        L.b[i] = nil
    end
end

---@param state pb_State
---@param info pbL_FileInfo[]
---@param L pb_Loader
local function loadDescriptorFiles(state, info, L)
    local proto3Name = tryGetName(state, "proto3")
    local _, curPos = 0, 0
    assert(proto3Name, "syntax error")
    for _, fileInfo in ipairs(info) do
        if fileInfo.package.pos then
            _, curPos = pbL_prefixname(state, fileInfo.package, L, false)
        end
        local syntaxName = tryGetName(state, fileInfo.syntax)
        L.is_proto3 = (syntaxName and syntaxName == proto3Name or false)
        for j, enumTypeInfo in ipairs(fileInfo.enum_type) do
            pbL_loadEnum(state, enumTypeInfo, L)
        end
        for j, messageTypeInfo in ipairs(fileInfo.message_type) do
            pbL_loadType(state, messageTypeInfo, L)
        end
        for j, extension in ipairs(fileInfo.extension) do
            pbL_loadField(state, extension, L, nil)
        end
        --删除后面的名称
        for j = curPos + 1, #L.b do
            L.b[j] = nil
        end
    end
end



---@param state pb_State
---@param s protobuf.Slice
local function pb_load(state, s)
    ---@type pbL_FileInfo[]
    local files = {}
    ---@type pb_Loader
    local L = {
        b = {},
        s = s,
        is_proto3 = false
    }
    fileDescriptor.pbL_FileDescriptorSet(L, files)
    loadDescriptorFiles(state, files, L)
end

---@param data any
---@return boolean @是否成功
---@return integer @当前数据位置
function M.Load(data)
    local state = State.lpb_lstate()
    local s = NewProtobufSlice(data)
    pb_load(state.local_state, s)
    State.GlobalState = state.local_state
    return true, s.pos - s.start + 1
end

return M
