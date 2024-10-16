local tool = require "pb.tool"
local meta = tool.meta

---@class Protobuf.OneofEntry
---@field name pb_Name
---@field index integer

---@class Protobuf.Type
---@field name pb_Name
---@field basename string
---@field field_sort Protobuf.Field[]
---@field field_tags Protobuf.Field[]
---@field field_names {[string]: Protobuf.Field} 
---@field oneof_index Protobuf.OneofEntry[]
---@field oneof_count integer # extra field count from oneof entries
---@field oneof_field integer  #  extra field in oneof declarations
---@field field_count integer
---@field is_enum boolean
---@field is_map boolean
---@field is_proto3 boolean
---@field is_dead boolean
local ProtobufType = meta("Protobuf.Type")

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

---@return Protobuf.Type
---@param name pb_Name
function ProtobufType.new(name)
    ---@type Protobuf.Type
    ---@diagnostic disable-next-line: missing-fields
    local self = {
        name = name,
        basename = getBasename(name),
        ---@diagnostic disable-next-line: missing-fields
        field_names = {},
        ---@diagnostic disable-next-line: missing-fields
        field_tags = {},
        ---@diagnostic disable-next-line: missing-fields
        oneof_index = {},
        ---@diagnostic disable-next-line: missing-fields
        field_sort = {},
        field_count = 0,
        oneof_count = 0,
        oneof_field = 0,
    }
    return setmetatable(self, ProtobufType)
end

return {
    ProtobufType = ProtobufType
}
