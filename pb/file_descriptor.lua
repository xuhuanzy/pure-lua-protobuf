local ConstantDefine = require "pb.ConstantDefine"


local BytesOperation = require("pb.bytes_operation")
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

---@class protobuf.FieldDescriptor
local M = {}

---@class protobuf.Loader.EnumValueInfo
---@field name protobuf.Slice
---@field number integer

---@class protobuf.Loader.EnumInfo
---@field name protobuf.Slice
---@field value protobuf.Loader.EnumValueInfo[]

---@class protobuf.Loader.FieldInfo
---@field name protobuf.Slice
---@field typeName protobuf.Slice
---@field extendee protobuf.Slice
---@field defaultValue protobuf.Slice
---@field number integer
---@field label integer
---@field type integer
---@field oneofIndex integer
---@field packed? boolean # 是否是`packed`类型, packed: 压缩

---@class protobuf.Loader.TypeInfo
---@field name protobuf.Slice
---@field isMap boolean
---@field field protobuf.Loader.FieldInfo[]
---@field extension protobuf.Loader.FieldInfo[]
---@field enumType protobuf.Loader.EnumInfo[]
---@field nestedType protobuf.Loader.TypeInfo[]
---@field oneofDecl protobuf.Slice[]

---@class protobuf.Loader.FileInfo
---@field package protobuf.Slice
---@field syntax protobuf.Slice
---@field enumType protobuf.Loader.EnumInfo[]
---@field messageType protobuf.Loader.TypeInfo[]
---@field extension protobuf.Loader.FieldInfo[]

---@param _table protobuf.Loader.FileInfo
local function try_init_pbL_FileInfo(_table)
    _table.enumType = _table.enumType or {}
    _table.messageType = _table.messageType or {}
    _table.extension = _table.extension or {}
    _table.package = _table.package or {}
    _table.syntax = _table.syntax or {}
end

---@param _table protobuf.Loader.TypeInfo
---@return protobuf.Loader.TypeInfo
local function try_init_pbL_TypeInfo(_table)
    _table.name = _table.name or {}
    _table.field = _table.field or {}
    _table.extension = _table.extension or {}
    _table.enumType = _table.enumType or {}
    _table.nestedType = _table.nestedType or {}
    _table.oneofDecl = _table.oneofDecl or {}
    return _table
end


---@param _table protobuf.Loader.FieldInfo
---@return protobuf.Loader.FieldInfo
local function try_init_pbL_FieldInfo(_table)
    _table.name = _table.name or {}
    _table.typeName = _table.typeName or {}  
    _table.extendee = _table.extendee or {}
    _table.defaultValue = _table.defaultValue or {} 
    _table.oneofIndex = _table.oneofIndex or 0 
    return _table
end

---@param _table protobuf.Loader.EnumInfo
---@return protobuf.Loader.EnumInfo
local function try_init_pbL_EnumInfo(_table)
    _table.name = _table.name or {}
    _table.value = _table.value or {}
    return _table
end

---@param _table protobuf.Loader.EnumValueInfo
local function try_init_pbL_EnumValueInfo(_table)
    _table.name = _table.name or {}
end

---@param L protobuf.Loader
---@param pv protobuf.Slice
---@return integer
local function pbL_readbytes(L, pv)
    local len = pb_readbytes(L.slice, pv)
    if len == 0 then
        return PB_ERROR
    end
    return PB_OK
end

---@param L protobuf.Loader
---@return integer @是否成功
---@return integer? @读取到的值
local function pbL_readint32(L)
    local len, v = pb_readvarint32(L.slice)
    if len == 0 then
        return PB_ERROR, nil
    end
    return PB_OK, v
end


---@param L protobuf.Loader
---@param pv protobuf.Slice
---@return integer
local function pbL_beginmsg(L, pv)
    local oldSlice = L.slice

    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice
    local ret = pbL_readbytes(L, targetSlice)
    if ret ~= PB_OK then
        return ret
    end
    pv._data = oldSlice._data
    pv.pos = oldSlice.pos
    pv.start = oldSlice.start
    pv.end_pos = oldSlice.end_pos
    L.slice = targetSlice
    return PB_OK
end

---@param L protobuf.Loader
---@param pv protobuf.Slice
local function pbL_endmsg(L, pv)
    L.slice = pv
end

-- 字段选项
---@param L protobuf.Loader
---@param info protobuf.Loader.FieldInfo
---@return integer
function M.pbL_FieldOptions(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(2, PB_TVARINT) == tag then -- bool packed
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.packed = v ~= 0
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 字段描述
---@param L protobuf.Loader
---@param info protobuf.Loader.FieldInfo
---@return integer
function M.pbL_FieldDescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice
    try_init_pbL_FieldInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)
    info.packed = nil

    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
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
            assert(pbL_readbytes(L, info.typeName) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.extendee) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.defaultValue) == PB_OK)
        elseif pb_pair(8, PB_TBYTES) == tag then
            -- 输出剩余长度
            assert(M.pbL_FieldOptions(L, info) == PB_OK)
        elseif pb_pair(9, PB_TVARINT) == tag then
            local ret, _ = pbL_readint32(L)
            assert(ret == PB_OK)
            info.oneofIndex = info.oneofIndex + 1
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 枚举值描述
---@param L protobuf.Loader
---@param info protobuf.Loader.EnumValueInfo
---@return integer
local function pbL_EnumValueDescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_EnumValueInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TVARINT) == tag then -- int32 number
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.number = v
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 枚举描述
---@param L protobuf.Loader
---@param info protobuf.Loader.EnumInfo
---@return integer
function M.pbL_EnumDescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_EnumInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then -- EnumValueDescriptorProto value
            assert(pbL_EnumValueDescriptorProto(L, pbL_add(info.value)) == PB_OK)
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 枚举描述
---@param L protobuf.Loader
---@param info protobuf.Loader.TypeInfo
---@return integer
function M.pbL_MessageOptions(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(7, PB_TVARINT) == tag then
            local ret, v = pbL_readint32(L)
            assert(ret == PB_OK) ---@cast v integer
            info.isMap = v ~= 0
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 枚举描述
---@param L protobuf.Loader
---@param info protobuf.Loader.TypeInfo
---@return integer
function M.pbL_OneofDescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)

    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, pbL_add(info.oneofDecl)) == PB_OK)
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end

    pbL_endmsg(L, targetSlice)
    return PB_OK;
end

-- 描述符
---@param L protobuf.Loader
---@param info protobuf.Loader.TypeInfo
---@return integer
function M.pbL_DescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_TypeInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then     -- string name
            assert(pbL_readbytes(L, info.name) == PB_OK)
        elseif pb_pair(2, PB_TBYTES) == tag then -- FieldDescriptorProto field
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.field)) == PB_OK)
        elseif pb_pair(6, PB_TBYTES) == tag then -- FieldDescriptorProto extension
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.extension)) == PB_OK)
        elseif pb_pair(3, PB_TBYTES) == tag then -- DescriptorProto nested_type
            assert(M.pbL_DescriptorProto(L, pbL_add(info.nestedType)) == PB_OK)
        elseif pb_pair(4, PB_TBYTES) == tag then -- EnumDescriptorProto enum_type
            assert(M.pbL_EnumDescriptorProto(L, pbL_add(info.enumType)) == PB_OK)
        elseif pb_pair(8, PB_TBYTES) == tag then -- OneofDescriptorProto oneof_decl
            assert(M.pbL_OneofDescriptorProto(L, info) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then -- MessageOptions options
            assert(M.pbL_MessageOptions(L, info) == PB_OK)
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, targetSlice)
    return PB_OK
end

-- 文件描述
---@param L protobuf.Loader
---@param info protobuf.Loader.FileInfo
---@return integer
function M.pbL_FileDescriptorProto(L, info)
    ---@diagnostic disable-next-line: missing-fields
    local targetSlice = {} ---@type protobuf.Slice

    try_init_pbL_FileInfo(info)
    assert(pbL_beginmsg(L, targetSlice) == PB_OK)
    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(2, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.package) == PB_OK)
        elseif pb_pair(4, PB_TBYTES) == tag then
            assert(M.pbL_DescriptorProto(L, pbL_add(info.messageType)) == PB_OK)
        elseif pb_pair(5, PB_TBYTES) == tag then
            assert(M.pbL_EnumDescriptorProto(L, pbL_add(info.enumType)) == PB_OK)
        elseif pb_pair(7, PB_TBYTES) == tag then
            assert(M.pbL_FieldDescriptorProto(L, pbL_add(info.extension)) == PB_OK)
        elseif pb_pair(12, PB_TBYTES) == tag then
            assert(pbL_readbytes(L, info.syntax) == PB_OK)
        else
            if pb_skipvalue(L.slice, tag) == 0 then return PB_ERROR end
        end
    end
    pbL_endmsg(L, targetSlice)
    return PB_OK
end

---@param L protobuf.Loader
---@param files protobuf.Loader.FileInfo[]
---@return integer
function M.pbL_FileDescriptorSet(L, files)
    while true do
        local len, tag = pb_readvarint32(L.slice) ---@cast tag integer
        if len == 0 then break end
        if pb_pair(1, PB_TBYTES) == tag then
            assert(M.pbL_FileDescriptorProto(L, pbL_add(files)) == PB_OK)
        else
            assert(pb_skipvalue(L.slice, tag) == PB_OK)
        end
    end
    return PB_OK
end

return M
