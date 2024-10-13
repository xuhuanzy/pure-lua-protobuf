local tool = require "pb.tool"
local meta = tool.meta
---@alias pb_Name string

---@class pb_NameEntry
---@field next pb_NameEntry
---@field hash integer
---@field length integer
---@field refcount integer
---@field name pb_Name

---@class pb_NameTable
---@field size integer
---@field count integer
---@field hash pb_NameEntry[]

---@class pb_CacheSlot
---@field name pb_Name
---@field hash integer

---@class pb_Cache
---@field slots pb_CacheSlot[][] # [PB_CACHE_SIZE][2]
---@field hash integer

---@class pb_State
---@field nametable pb_NameTable
---@field types { [pb_Name]: Protobuf.Type }
---@field typepool pb_Pool
---@field fieldpool pb_Pool

---@class pb_Pool
---@field obj_size integer


---@class pb_Table
---@field size integer
---@field lastfree integer
---@field entry_size integer
---@field has_zero integer
---@field hash pb_Entry[]

---@class pb_Entry
---@field next integer
---@field key integer



---@class Protobuf.Field
---@field name pb_Name
---@field type Protobuf.Type
---@field default_value? pb_Name
---@field number integer
---@field sort_index integer
---@field oneof_idx integer
---@field type_id integer
---@field repeated boolean # 是否是`repeated`类型, repeated: 可重复
---@field packed boolean # 是否是`packed`类型, packed: 压缩
---@field scalar boolean # 是否是`scalar`类型, scalar: 标量
local ProtobufField = meta("Protobuf.Field")

---@param name pb_Name
---@param type Protobuf.Type
---@param number integer
---@return Protobuf.Field
function ProtobufField.new(name, type, number)
    ---@type Protobuf.Field
---@diagnostic disable-next-line: missing-fields
    local self = {
        name = name,
        type = type,
        number = number,

    }
    return setmetatable(self, ProtobufField)
end

return {
    ProtobufField = ProtobufField
}
