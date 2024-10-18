local fileDescriptor = require("protobuf.file_descriptor")

local ProtobufState = require("protobuf.state")

local pb_addslice = require("protobuf.bytes_operation").pb_addslice

local ProtobufType = require("protobuf.type")
local ProtobufField = require("protobuf.field")

local ConstantDefine = require("protobuf.ConstantDefine")
local PB_Tmessage = ConstantDefine.pb_FieldType.PB_Tmessage
local PB_Tenum = ConstantDefine.pb_FieldType.PB_Tenum

local charArrayToString = require("protobuf.util").charArrayToString
local NewProtobufSlice = require("protobuf.util").ProtobufSlice.new


local tryGetName = require("protobuf.names").tryGetName

local tableInsert = table.insert
local ipairs = ipairs

---@class protobuf.Loader
---@field slice protobuf.Slice 需要被处理的数据
---@field isProto3 boolean 是否是proto3
---@field buffer protobuf.Char[] 自己的数据


---@class PB.Loader
local M = {}


---@param state protobuf.TypeDatabase
---@param s protobuf.Slice
---@param loader protobuf.Loader
---@param isoOut boolean
---@return protobuf.NameValue? name 名称
---@return integer curPos 当前位置
local function pbL_prefixname(state, s, loader, isoOut)
    local curPos = #loader.buffer
    -- `46` 等价于`string.byte(".")`
    loader.buffer[#loader.buffer + 1] = 46
    pb_addslice(loader.buffer, s)
    if not isoOut then
        return nil, curPos
    end
    return tryGetName(state, charArrayToString(loader.buffer)), curPos
end



---@param state protobuf.TypeDatabase
---@param tname? protobuf.NameValue
---@return protobuf.Type?
local function pb_newtype(state, tname)
    if not tname then return nil end
    if not state.types[tname] then
        state.types[tname] = ProtobufType.new(tname)
    end
    local t = state.types[tname]
    t.is_dead = false
    return t
end

---@param state protobuf.TypeDatabase
---@param type protobuf.Type
---@param tname? protobuf.NameValue
---@param number integer
---@return protobuf.Field?
local function pb_newfield(state, type, tname, number)
    if not tname then return nil end
    local nf = type.field_names[tname]
    local tf = type.field_tags[number]
    if nf and tf and nf == tf then
        nf.defaultValue = nil
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

---@param state protobuf.TypeDatabase
---@param info protobuf.Loader.EnumInfo
---@param L protobuf.Loader
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
    for i = curPos + 1, #L.buffer do
        L.buffer[i] = nil
    end
end


---@param state protobuf.TypeDatabase
---@param info protobuf.Loader.FieldInfo
---@param L protobuf.Loader
---@param type protobuf.Type?
local function pbL_loadField(state, info, L, type)
    local ft
    if info.type == PB_Tmessage or info.type == PB_Tenum then
        ft = pb_newtype(state, tryGetName(state, info.typeName))
    end
    ---@cast ft protobuf.Type

    if not type then
        type = pb_newtype(state, tryGetName(state, info.extendee))
    end
    ---@cast type protobuf.Type
    local f = pb_newfield(state, type, tryGetName(state, info.name), info.number)
    assert(f)
    f.defaultValue = tryGetName(state, info.defaultValue)
    f.type = ft
    f.oneofIdx = info.oneofIndex
    if f.oneofIdx and f.oneofIdx ~= 0 then
        type.oneof_field = type.oneof_field + 1
    end
    f.typeId = info.type
    f.repeated = info.label == 3
    if info.packed ~= nil then
        f.packed = info.packed
    else
        f.packed = L.isProto3 and f.repeated
    end
    if f.typeId >= 9 and f.typeId <= 12 then
        f.packed = false
    end
    f.scalar = (f.type == nil)
end



---@param state protobuf.TypeDatabase
---@param info protobuf.Loader.TypeInfo
---@param L protobuf.Loader
local function pbL_loadType(state, info, L)
    local prefixname, curPos = pbL_prefixname(state, info.name, L, true)
    local t = pb_newtype(state, prefixname)
    assert(t) 
    t.isMap = info.isMap
    t.is_proto3 = L.isProto3
    for i, oneofDecl in ipairs(info.oneofDecl) do
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
    for _, enumTypeInfo in ipairs(info.enumType) do
        pbL_loadEnum(state, enumTypeInfo, L)
    end
    for _, nestedTypeInfo in ipairs(info.nestedType) do
        pbL_loadType(state, nestedTypeInfo, L)
    end
    t.oneof_count = #info.oneofDecl
    --删除后面的名称
    for i = curPos + 1, #L.buffer do
        L.buffer[i] = nil
    end
end

---@param state protobuf.TypeDatabase
---@param info protobuf.Loader.FileInfo[]
---@param L protobuf.Loader
local function loadDescriptorFiles(state, info, L)
    local proto3Name = tryGetName(state, "proto3")
    local _, curPos = 0, 0
    assert(proto3Name, "syntax error")
    for _, fileInfo in ipairs(info) do
        if fileInfo.package.pos then
            _, curPos = pbL_prefixname(state, fileInfo.package, L, false)
        end
        local syntaxName = tryGetName(state, fileInfo.syntax)
        L.isProto3 = (syntaxName and syntaxName == proto3Name or false)
        for j, enumTypeInfo in ipairs(fileInfo.enumType) do
            pbL_loadEnum(state, enumTypeInfo, L)
        end
        for j, messageTypeInfo in ipairs(fileInfo.messageType) do
            pbL_loadType(state, messageTypeInfo, L)
        end
        for j, extension in ipairs(fileInfo.extension) do
            pbL_loadField(state, extension, L, nil)
        end
        --删除后面的名称
        for j = curPos + 1, #L.buffer do
            L.buffer[j] = nil
        end
    end
end



---@param state protobuf.TypeDatabase
---@param s protobuf.Slice
local function pb_load(state, s)
    ---@type protobuf.Loader.FileInfo[]
    local files = {}
    ---@type protobuf.Loader
    local L = {
        buffer = {},
        slice = s,
        isProto3 = false
    }
    fileDescriptor.pbL_FileDescriptorSet(L, files)
    loadDescriptorFiles(state, files, L)
end

---@param data any
---@return boolean @是否成功
---@return integer @当前数据位置
function M.Load(data)
    local config = ProtobufState.getConfig()
    local s = NewProtobufSlice(data)
    pb_load(config.localDb, s)
    ProtobufState.GlobalDb = config.localDb
    return true, s.pos - s.start + 1
end

return M
