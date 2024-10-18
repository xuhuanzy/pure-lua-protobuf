local tool = require("protobuf.tool")
local meta = tool.meta
local setmetatable = setmetatable


---@class protobuf.OneofEntry
---@field name protobuf.NameValue
---@field index integer

---@class protobuf.Type
---@field name protobuf.NameValue
---@field basename string
---@field field_sort protobuf.Field[]
---@field field_tags protobuf.Field[]
---@field field_names {[string]: protobuf.Field} 
---@field oneof_index protobuf.OneofEntry[]
---@field oneof_count integer # extra field count from oneof entries
---@field oneof_field integer  #  extra field in oneof declarations
---@field field_count integer
---@field is_enum boolean
---@field isMap boolean
---@field is_proto3 boolean
---@field is_dead boolean
local ProtobufType = meta("protobuf.Type")

---@param str string
---@return string
local function getBasename(str)
    local last_dot = str:find(".", 1, true)
    local start = last_dot
    while last_dot do
        start = last_dot
        last_dot = str:find(".", start + 1, true)
    end
    return start and str:sub(start + 1) or str
end

---@return protobuf.Type
---@param name protobuf.NameValue
function ProtobufType.new(name)
    ---@type protobuf.Type
    local self = {
        name = name,
        basename = getBasename(name),
        field_names = {},
        field_tags = {},
        oneof_index = {},
        field_sort = {},
        field_count = 0,
        oneof_count = 0,
        oneof_field = 0,
        is_enum = false,
        isMap = false,
        is_proto3 = false,
        is_dead = false,
    }
    return setmetatable(self, ProtobufType)
end

return ProtobufType
