local tryGetName = require("protobuf.names").tryGetName
local getSliceString = require("protobuf.util").getSliceString
local ConstantDefine = require("protobuf.ConstantDefine")

---@class export.protobuf.State
local M = {}


-- 全局配置
---@class protobuf.GlobalConfig
---@field db protobuf.TypeDatabase 正在使用的类型数据库
---@field localDb protobuf.TypeDatabase 局部类型数据库
---@field arrayType protobuf.Type 数组类型
---@field mapType protobuf.Type 映射类型
---@field defaultMetaTable {[protobuf.Type]: table} {类型: 对应的元表}
---@field useDecodeHooks boolean 使用解码钩子
---@field useEncodeHooks boolean 使用编码钩子
---@field enumAsValue boolean 解码枚举时, `false`设置值为枚举名, `true`设置为枚举值数字
---@field decodeMode protobuf.DecodeMode 解码模式
---@field int64Mode protobuf.Int64Mode 64位整数模式
---@field encodeDefaultValues boolean 默认值也参与编码
---@field decodeDefaultArray boolean 对于数组, 将空值解码为空表或`nil`(默认为`nil`)
---@field decodeDefaultMessage boolean 将空子消息解析成默认值表

-- 类型数据库
---@class protobuf.TypeDatabase
---@field nametable { [protobuf.NameValue]: protobuf.NameEntry } @名称表, 未使用
---@field types { [protobuf.NameValue]: protobuf.Type } @类型表

---@type protobuf.GlobalConfig  当前配置
local CurrentConfig = nil

---@type protobuf.TypeDatabase 全局数据库, 会在`Loader`中自动设置
M.GlobalDb = nil

-- 获取配置
---@return protobuf.GlobalConfig
function M.getConfig()
    if not CurrentConfig then
        ---@type protobuf.GlobalConfig
        CurrentConfig = {
            decodeMode = ConstantDefine.DecodeMode.LPB_DEFDEF,
            defaultMetaTable = {},
            ---@diagnostic disable-next-line: missing-fields
            arrayType = {
                is_dead = true,
            },
            ---@diagnostic disable-next-line: missing-fields
            mapType = {
                is_dead = true,
            },
            localDb = {
                types = {},
                nametable = {},
            },
            decodeDefaultArray = false,
            decodeDefaultMessage = false,
            encodeDefaultValues = false,
            enumAsValue = false,
            int64Mode = ConstantDefine.Int64Mode.LPB_NUMBER,
            useDecodeHooks = false,
            useEncodeHooks = false,
            ---@diagnostic disable-next-line: assign-type-mismatch
            db = nil,
        }

        CurrentConfig.db = CurrentConfig.localDb
    end
    return CurrentConfig
end

--#region 配置

---@alias protobuf.GlobalConfigOption
---| "autoDefaultValues" 解码模式, 自动选择默认值设置, 对于`proto3`为`useDefaultValues`, 其他为`noDefaultValues`
---| "useDefaultValues" 解码模式, 将默认值表复制到解码目标表中来
---| "noDefaultValues" 解码模式, 将默认值表复制到解码目标表中来
---| "useDefaultMetatable" 解码模式, 将默认值表作为解码目标表的元表使用
---| "enumAsName" 解码枚举的时候, 设置值为枚举名(默认)
---| "enumAsValue" 解码枚举的时候, 设置值为枚举值数字



---@param opt protobuf.GlobalConfigOption 选项
function M.setOption(opt)
    ---@cast opt protobuf.GlobalConfigOption
    local config = M.getConfig()
    if not config then return end
    if opt == "autoDefaultValues" then
        config.decodeMode = ConstantDefine.DecodeMode.LPB_DEFDEF
    elseif opt == "useDefaultValues" then
        config.decodeMode = ConstantDefine.DecodeMode.LPB_COPYDEF
    elseif opt == "noDefaultValues" then
        config.decodeMode = ConstantDefine.DecodeMode.LPB_NODEF
    elseif opt == "useDefaultMetatable" then
        config.decodeMode = ConstantDefine.DecodeMode.LPB_METADEF
    elseif opt == "enumAsName" then
        config.enumAsValue = false
    elseif opt == "enumAsValue" then
        config.enumAsValue = true
    end
end

--#endregion

--#region 数据库搜索

-- 从数据库搜索类型
---@param state protobuf.TypeDatabase
---@param tname protobuf.NameValue
---@return protobuf.Type?
local function findType(state, tname)
    if not state or not tname then
        return nil
    end
    local _type = state.types[tname]
    if _type and (not _type.is_dead) then
        return _type
    end
    return nil
end


-- 从类型中搜索字段
---@param protobufType protobuf.Type
---@param number integer
---@return protobuf.Field?
function M.findField(protobufType, number)
    if not protobufType then
        return nil
    end
    return protobufType.field_tags[number]
end

---@param protobufType protobuf.Type
---@param name protobuf.NameValue?
---@return protobuf.Field?
function M.findName(protobufType, name)
    if not protobufType or not name then
        return nil
    end
    return protobufType.field_names[name]
end

-- 搜索内部类型(以`.`开头的类型)
---@param LS protobuf.GlobalConfig
---@param s protobuf.Slice
---@return protobuf.Type?
function M.findInternalType(LS, s)
    -- 0: `\0`   46: '.'
    if s._data[1] == 46 or s.pos == nil or s._data[1] == 0 then
        local name = tryGetName(LS.db, s)
        if name then
            return findType(LS.db, name)
        end
    else
        local name = tryGetName(LS.db, "." .. getSliceString(s))
        if name then
            return findType(LS.db, name)
        end
    end
end

--#endregion

return M
