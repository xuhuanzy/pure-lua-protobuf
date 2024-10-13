local fileDescriptor = require("pb.fileDescriptor")
local decode = require("pb.decode")
local PbName = require("pb.name")
local PbTypes = require "pb.types"

local PB_OK = PbTypes.PB_OK
local PB_ERROR = PbTypes.PB_ERROR

local pb_slice = decode.pb_slice

local TestGobalDefine = require "test.TestGobalDefine"

---@class pb_Loader
---@field s pb_Slice
---@field b pb_Buffer
---@field is_proto3 boolean

---@class PB.Loader
local M = {}


---@param state pb_State
---@param s pb_Slice
---@return pb_Name?
local function pbL_prefixname(state, s)
    local copy = decode.sliceCopy(s)
    -- `46` 等价于`string.byte(".")`
    table.insert(copy._data, 1, 46)
    copy.end_pos = copy.end_pos + 1
    return PbName.pb_newname(state, copy)
end

--[[ static int pbL_loadEnum(pb_State *S, pbL_EnumInfo *info, pb_Loader *L) {
    size_t i, count, curr;
    pb_Name *name;
    pb_Type *t;
    pbC(pbL_prefixname(S, info->name, &curr, L, &name));
    pbCM(t = pb_newtype(S, name));
    t->is_enum = 1;
    for (i = 0, count = pbL_count(info->value); i < count; ++i) {
        pbL_EnumValueInfo *ev = &info->value[i];
        pbCE(pb_newfield(S, t, pb_newname(S, ev->name, NULL), ev->number));
    }
    L->b.size = (unsigned) curr;
    return PB_OK;
} ]]
---@param state pb_State
---@param info pbL_EnumInfo
---@param L pb_Loader
local function pbL_loadEnum(state, info, L)
end

---@param state pb_State
---@param info pbL_FileInfo[]
---@param L pb_Loader
local function loadDescriptorFiles(state, info, L)
    local jcount, curr = 0, 0;
    local syntax = PbName.pb_newname(state, pb_slice("proto3"))
    assert(syntax, "syntax error")

    --[[     for (i = 0, count = pbL_count(info); i < count; ++i) {
        if (info[i].package.p)
            pbC(pbL_prefixname(S, info[i].package, &curr, L, NULL));
        L->is_proto3 = (pb_name(S, info[i].syntax, NULL) == syntax);
        for (j = 0, jcount = pbL_count(info[i].enum_type); j < jcount; ++j)
            pbC(pbL_loadEnum(S, &info[i].enum_type[j], L));
        for (j = 0, jcount = pbL_count(info[i].message_type); j < jcount; ++j)
            pbC(pbL_loadType(S, &info[i].message_type[j], L));
        for (j = 0, jcount = pbL_count(info[i].extension); j < jcount; ++j)
            pbC(pbL_loadField(S, &info[i].extension[j], L, NULL));
        L->b.size = (unsigned) curr;
    }
    return PB_OK; ]]
    for i, fileInfo in ipairs(info) do
        if fileInfo.package.pos then
            pbL_prefixname(state, fileInfo.package)
        end
        L.is_proto3 = (PbName.pb_name(state, fileInfo.syntax) == syntax)
        for j, enumTypeInfo in ipairs(fileInfo.enum_type) do
            pbL_loadEnum(state, enumTypeInfo, L)
        end

    end
end



---@param state pb_State
---@param s pb_Slice
function M.pb_load(state, s)
    ---@type pbL_FileInfo[]
    local files = {}
    ---@type pb_Loader
    local L = {
        ---@diagnostic disable-next-line: missing-fields
        b = {},
        s = s,
        is_proto3 = false
    }
    fileDescriptor.pbL_FileDescriptorSet(L, files)
    loadDescriptorFiles(state, files, L)
end

return M
