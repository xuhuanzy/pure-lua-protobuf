# Google protobuf support for Lua5.4+

This project provides support for Protobuf versions 2/3 in a pure Lua environment, aimed at special environments that do not support loading DLLs. It only supports Lua 5.4+.

本项目提供在纯Lua环境下的 protobuf 2/3 版本支持, 应用于不支持加载 DLL 的特殊环境, 仅支持 Lua 5.4 +.


## 安装
复制 `protobuf` 目录到你的项目中, 并在你的项目中 `require("protobuf")` 即可.

`tools`目录是不必要的, 仅用于测试和示例.

接口类型提示依赖于vscode插件 `sumneko.lua`(`emmylua`或许也可以), 请一并安装.


## 样例
```lua
local dump = require("tools.utility").dump
local encode = require("protobuf").encode
local decode = require("protobuf").decode

local toHex = require("protobuf").toHex
-- 通过导出的函数直接加载
-- 但也可以使用  `local protobuf= require("protobuf").new(); protobuf:load(...)` 
local load = require("protobuf").load
assert(load [[
   message Phone {
      optional string name        = 1;
      optional int64  phonenumber = 2;
   }
   message Person {
      optional string name     = 1;
      optional int32  age      = 2;
      optional string address  = 3;
      repeated Phone  contacts = 4;
   } ]])

-- lua 表数据
local data = {
   name = "ilse",
   age  = 18,
   contacts = {
      { name = "alice", phonenumber = 12312341234 },
      { name = "bob",   phonenumber = 45645674567 }
   }
}

-- 将Lua表编码为二进制数据
local bytes = assert(encode("Person", data))
print(toHex(bytes))

-- 再解码回Lua表
local data2 = assert(decode("Person", bytes))
print(dump(data2))

```

## 性能

简单测试`lua`版本性能约为`dll`版本的 12%.
```
dll: avg 0.002468 ms
lua: avg 0.021600 ms
```

## 感谢

- [lua-protobuf](https://github.com/starwing/lua-protobuf)
