local tool = require "pb.tool"
local meta = tool.meta
local setmetatable = setmetatable

---@alias protobuf.NameValue string

---@class protobuf.NameEntry
---@field refcount integer # 引用计数
---@field name protobuf.NameValue # 名称

---@class pb_NameEntry
---@field next pb_NameEntry
---@field hash integer
---@field length integer
---@field refcount integer
---@field name protobuf.NameValue

---@class pb_NameTable
---@field size integer
---@field count integer
---@field hash pb_NameEntry[]

---@class pb_CacheSlot
---@field name protobuf.NameValue
---@field hash integer

---@class pb_Cache
---@field slots pb_CacheSlot[][] # [PB_CACHE_SIZE][2]
---@field hash integer

---@class pb_State
---@field nametable { [protobuf.NameValue]: protobuf.NameEntry } @名称表, 未使用
---@field types { [protobuf.NameValue]: Protobuf.Type } @类型表
---@field typepool pb_Pool @类型池
---@field fieldpool pb_Pool @字段池

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
---@field name protobuf.NameValue
---@field type Protobuf.Type
---@field default_value? protobuf.NameValue
---@field number integer
---@field sort_index integer
---@field oneof_idx integer
---@field type_id integer
---@field repeated boolean # 是否是`repeated`类型, repeated: 可重复
---@field packed boolean # 是否是`packed`类型, packed: 压缩
---@field scalar boolean # 是否是`scalar`类型, scalar: 标量
local ProtobufField = meta("Protobuf.Field")

---@param name protobuf.NameValue
---@param type Protobuf.Type
---@param number integer
---@return Protobuf.Field
function ProtobufField.new(name, type, number)
    ---@type Protobuf.Field
    local self = {
        name = name,
        type = type,
        number = number,
        oneof_idx = 0,
        type_id = 0,
        repeated = false,
        packed = false,
        scalar = false,
        default_value = nil,
        sort_index = 0,
    }
    return setmetatable(self, ProtobufField)
end

return {
    ProtobufField = ProtobufField
}
