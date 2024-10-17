---@alias Protobuf.Char integer

---@class pb_Slice
---@field _data Protobuf.Char[]
---@field pos? integer 当前位置
---@field start? integer 起始位置
---@field end_pos integer 结束位置
---@field stringValue string? 字符串值缓存. 如果该值不为空, 则其他值不应该发生改变



