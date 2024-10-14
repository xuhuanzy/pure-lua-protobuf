local _print = print

---测试性能
---@param msg string 消息
---@param n integer|"千"|"万"|"十万"|"百万"|"千万"|"亿" 次数
---@param fun function 函数
---@param ... any 参数
local function TimerTest(msg, n, fun, ...)
    if type(n) == "string" then
        if n == "千" then
            n = 1000
        elseif n == "万" then
            n = 10000
        elseif n == "十万" then
            n = 100000
        elseif n == "百万" then
            n = 1000000
        elseif n == "千万" then
            n = 10000000
        elseif n == "亿" then
            n = 100000000
        end
    end
    local start = os.clock()
    ---@diagnostic disable-next-line: missing-global-doc
    print = function() end
    for i = 1, n do fun(...) end
    print = _print
    local end_time = os.clock()
    -- 打印平均时间, 单位毫秒
    print(string.format("%s:  sum %f ms, avg %f ms", msg, end_time - start, (end_time - start) * 1000 / n))
end


return {
    TimerTest = TimerTest
}