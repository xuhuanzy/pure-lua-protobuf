local tool = require("protobuf.tool")
local meta = tool.meta
local setmetatable = setmetatable




---@class protobuf.Field
---@field name protobuf.NameValue
---@field type protobuf.Type
---@field defaultValue? protobuf.NameValue
---@field number integer
---@field sortIndex integer
---@field oneofIdx integer
---@field typeId integer
---@field repeated boolean # 是否是`repeated`类型, repeated: 可重复
---@field packed boolean # 是否是`packed`类型, packed: 压缩
---@field scalar boolean # 是否是`scalar`类型, scalar: 标量
local ProtobufField = meta("protobuf.Field")

---@param name protobuf.NameValue
---@param type protobuf.Type
---@param number integer
---@return protobuf.Field
function ProtobufField.new(name, type, number)
    ---@type protobuf.Field
    local self = {
        name = name,
        type = type,
        number = number,
        oneofIdx = 0,
        typeId = 0,
        repeated = false,
        packed = false,
        scalar = false,
        defaultValue = nil,
        sortIndex = 0,
    }
    return setmetatable(self, ProtobufField)
end

return ProtobufField
