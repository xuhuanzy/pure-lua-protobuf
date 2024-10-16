local decode = require "pb.decode"
local ConstantDefine = require "pb.ConstantDefine"

local BytesOperation = require("pb.BytesOperation")
local pb_pair = BytesOperation.pb_pair
local pb_readvarint32 = BytesOperation.pb_readvarint32
local pb_skipvalue = BytesOperation.pb_skipvalue
local pb_readbytes = BytesOperation.pb_readbytes


local PB_OK = ConstantDefine.PB_OK
local PB_ERROR = ConstantDefine.PB_ERROR
local PB_TBYTES = ConstantDefine.pb_WireType.PB_TBYTES
local PB_TVARINT = ConstantDefine.pb_WireType.PB_TVARINT
local PB_T64BIT = ConstantDefine.pb_WireType.PB_T64BIT
local PB_T32BIT = ConstantDefine.pb_WireType.PB_T32BIT
local PB_TGSTART = ConstantDefine.pb_WireType.PB_TGSTART

-- 模拟数组, 添加一个新的元素, 返回这个元素
---@param _table table
---@return table
local function pbL_add(_table)
    _table[#_table + 1] = {}
    return _table[#_table]
end

---@class PB.FieldDescriptor
local M = {}

---@class pbL_EnumValueInfo
---@field name pb_Slice
---@field number integer

---@class pbL_EnumInfo
---@field name pb_Slice
---@field value pbL_EnumValueInfo[]

---@class pbL_FieldInfo
---@field name pb_Slice
---@field type_name pb_Slice
---@field extendee pb_Slice
---@field default_value pb_Slice
---@field number integer
---@field label integer
---@field type integer
---@field oneof_index integer
---@field packed? boolean # 是否是`packed`类型, packed: 压缩


---@class pbL_TypeInfo
---@field name pb_Slice
---@field is_map boolean
---@field field pbL_FieldInfo[]
---@field extension pbL_FieldInfo[]
---@field enum_type pbL_EnumInfo[]
---@field nested_type pbL_TypeInfo[]
---@field oneof_decl pb_Slice[]

---@class pbL_FileInfo
---@field package pb_Slice
---@field syntax pb_Slice
---@field enum_type pbL_EnumInfo[]
---@field message_type pbL_TypeInfo[]
---@field extension pbL_FieldInfo[]

---@param _table pbL_FileInfo
local function try_init_pbL_FileInfo(_table)
    _table.enum_type = _table.enum_type or {}
    _table.message_type = _table.message_type or {}
    _table.extension = _table.extension or {}
    _table.package = _table.package or {}
    _table.syntax = _table.syntax or {}
end

---@param _table pbL_TypeInfo
---@return pbL_TypeInfo
local function try_init_pbL_TypeInfo(_table)
    _table.name = _table.name or {}
    _table.field = _table.field or {}
    _table.extension = _table.extension or {}
    _table.enum_type = _table.enum_type or {}
    _table.nested_type = _table.nested_type or {}
    _table.oneof_decl = _table.oneof_decl or {}
    return _table
end


---@param _table pbL_FieldInfo
---@return pbL_FieldInfo
local function try_init_pbL_FieldInfo(_table)
    _table.name = _table.name or {}
    _table.type_name = _table.type_name or {}
    _table.extendee = _table.extendee or {}
    _table.default_value = _table.default_value or {}

    return _table
end

---@param _table pbL_EnumInfo
---@return pbL_EnumInfo
local function try_init_pbL_EnumInfo(_table)
    _table.name = _table.name or {}
    _table.value = _table.value or {}
    return _table
end

---@param _table pbL_EnumValueInfo
local function try_init_pbL_EnumValueInfo(_table)
    _table.name = _table.name or {}
end

---@param L pb_Loader
---@param pv pb_Slice
---@return integer
local function pbL_readbytes(L, pv)
    local len = pb_readbytes(L.s, pv)
    if len == 0 then
        return PB_ERROR
    end
    return PB_OK
end

---@param L pb_Loader
---@return integer @是否成功
---@return integer? @读取到的值
local function pbL_readint32(L)
    local len, v = pb_readvarint32(L.s)
    if len == 0 then
        return PB_ERROR, nil
    end
    return PB_OK, v
end


---@param L pb_Loader
---@param pv pb_Slice
---@return integer
local function pbL_beginmsg(L, pv)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local v = {}

    local ret = pbL_readbytes(L, v)
    if ret ~= PB_OK then
        return ret
    end
    pv._data = L.s._data
    pv.pos = L.s.pos
    pv.start = L.s.start
    pv.end_pos = L.s.end_pos
    L.s = v
    return PB_OK
end

---@param L pb_Loader
---@param pv pb_Slice
local function pbL_endmsg(L, pv)
    L.s = pv
end

-- 字段选项
---@param L pb_Loader
---@param info pbL_FieldInfo
---@return integer
function M.pbL_FieldOptions(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    assert(pbL_beginmsg(L, s) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(2, PB_TVARINT) == tag then -- bool packed
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.packed = v ~= 0
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, s)
    return PB_OK;
end

-- 字段描述
---@param L pb_Loader
---@param info pbL_FieldInfo
---@return integer
function M.pbL_FieldDescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_FieldInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)
    info.packed = nil

    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(3, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.number = v
        elseif pb_pair(4, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.label = v
        elseif pb_pair(5, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.type = v
        elseif pb_pair(6, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.type_name) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.extendee) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.default_value) == PB_OK)
        elseif pb_pair(8, PB_TBYTES) == tag then
            -- 输出剩余长度
            assert(M.pbL_FieldOptions(L, info) == PB_OK)
        elseif pb_pair(9, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.oneof_index = v
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, s)
    return PB_OK;
end

-- 枚举值描述
---@param L pb_Loader
---@param info pbL_EnumValueInfo
---@return integer
local function pbL_EnumValueDescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_EnumValueInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TVARINT) == tag then -- int32 number
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.number = v
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, s)
    return PB_OK;
end

-- 枚举描述
---@param L pb_Loader
---@param info pbL_EnumInfo
---@return integer
function M.pbL_EnumDescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_EnumInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then -- EnumValueDescriptorProto value
            assert(pbL_EnumValueDescriptorProto(L, pbL_add(info.value)) == PB_OK)
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, s)
    return PB_OK;
end

-- 枚举描述
---@param L pb_Loader
---@param info pbL_TypeInfo
---@return integer
function M.pbL_MessageOptions(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(7, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.is_map = v ~= 0
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, s)
    return PB_OK;
end

-- 枚举描述
---@param L pb_Loader
---@param info pbL_TypeInfo
---@return integer
function M.pbL_OneofDescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, pbL_add(info.oneof_decl)) == PB_OK)
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, s)
    return PB_OK;
end

-- 描述符
---@param L pb_Loader
---@param info pbL_TypeInfo
---@return integer
function M.pbL_DescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then     -- string name
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then -- FieldDescriptorProto field
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.field)) == PB_OK)
        elseif pb_pair(6, PB_TBYTES) == tag then -- FieldDescriptorProto extension
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.extension)) == PB_OK)
        elseif pb_pair(3, PB_TBYTES) == tag then -- DescriptorProto nested_type
            assert(M.pbL_DescriptorProto(L, pbL_add(info.nested_type)) == PB_OK)
        elseif pb_pair(4, PB_TBYTES) == tag then -- EnumDescriptorProto enum_type
            assert(M.pbL_EnumDescriptorProto(L, pbL_add(info.enum_type)) == PB_OK)
        elseif pb_pair(8, PB_TBYTES) == tag then -- OneofDescriptorProto oneof_decl
            assert(M.pbL_OneofDescriptorProto(L, info) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then -- MessageOptions options
            assert(M.pbL_MessageOptions(L, info) == PB_OK)
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, s)
    return PB_OK
end

-- 文件描述
---@param L pb_Loader
---@param info pbL_FileInfo
---@return integer
function M.pbL_FileDescriptorProto(L, info)
    ---@type pb_Slice
    ---@diagnostic disable-next-line: missing-fields
    local s = {}
    try_init_pbL_FileInfo(info)
    assert(pbL_beginmsg(L, s) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(2, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.package) == PB_OK)
        elseif pb_pair(4, PB_TBYTES) == tag then
            assert(M.pbL_DescriptorProto(L, pbL_add(info.message_type)) == PB_OK)
        elseif pb_pair(5, PB_TBYTES) == tag then
            assert(M.pbL_EnumDescriptorProto(L, pbL_add(info.enum_type)) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.extension)) == PB_OK)
        elseif pb_pair(12, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.syntax) == PB_OK)
        else
            if pb_skipvalue(L.s, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, s)
    return PB_OK
end

---@param L pb_Loader
---@param files pbL_FileInfo[]
---@return integer
function M.pbL_FileDescriptorSet(L, files)
    while true do
        local len, tag = pb_readvarint32(L.s) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(M.pbL_FileDescriptorProto(L, pbL_add(files)) == PB_OK)
        else
            assert(pb_skipvalue(L.s, tag) == PB_OK)
        end
    end
    return PB_OK
end

return M
