
---@alias pb_Name string

---@class pb_NameEntry
---@field next pb_NameEntry
---@field hash integer
---@field length integer
---@field refcount integer
---@field name string

---@class pb_NameTable
---@field size integer
---@field count integer
---@field hash pb_NameEntry[]

---@class pb_CacheSlot
---@field name string
---@field hash integer

---@class pb_Cache
---@field slots pb_CacheSlot[][] # [PB_CACHE_SIZE][2]
---@field hash integer

---@class pb_State
---@field nametable pb_NameTable
---@field types pb_Table
---@field typepool pb_Pool
---@field fieldpool pb_Pool

---@class pb_Pool
---@field obj_size integer

---@class pb_Field
---@field name pb_Name
---@field type pb_Type
---@field default_value pb_Name
---@field number integer
---@field sort_index integer
---@field oneof_idx integer
---@field type_id integer
---@field repeated integer
---@field packed integer
---@field scalar integer

---@class pb_Type
---@field name pb_Name
---@field basename string
---@field field_sort pb_Field
---@field field_tags pb_Table
---@field field_names pb_Table
---@field oneof_index pb_Table
---@field oneof_count integer # extra field count from oneof entries
---@field oneof_field integer  #  extra field in oneof declarations
---@field field_count integer
---@field is_enum integer
---@field is_map integer
---@field is_proto3 integer
---@field is_dead integer


---@class pb_Table
---@field size integer
---@field lastfree integer
---@field entry_size integer
---@field has_zero integer
---@field hash pb_Entry[]

---@class pb_Entry
---@field next integer
---@field key integer


