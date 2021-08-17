-- [[ Override print to accept varargs in tfm ]]
local raw_print = print

--- Receives any number of arguments and prints their values to `stdout`, converting each argument to a string following the same rules of [tostring](command:extension.lua.doc?["en-us/52/manual.html/pdf-tostring"]). \
--- The function print is not intended for formatted output, but only as a quick way to show a value, for instance for debugging. For complete control over the output, use [string.format](command:extension.lua.doc?["en-us/52/manual.html/pdf-string.format"]) and [io.write](command:extension.lua.doc?["en-us/52/manual.html/pdf-io.write"]).
---
--- [View documents](command:extension.lua.doc?["en-us/52/manual.html/pdf-print"])
print = function(...)
    local args = {...}
    local nargs = select('#', ...)
    local segments = {}
    for i = 1, nargs do
        segments[i] = tostring(args[i])
    end
    return raw_print(table.concat(segments, "\t"))
end

-- [[ Async/Await Proof of concept ! ]]
queue = {}

--- async
--- @generic T
--- @param fnc T
--- @return T
local function async(fnc)
    local t = {}
    t.coro = coroutine.create(fnc)
    setmetatable(t, {
        __call = function()
            -- no return because not awaited
            queue[#queue+1] = function() coroutine.resume(t.coro) end
        end
    })
    return t
end

--- await
--- @generic T
--- @param t T
--- @return T
local function await(t)
    local this_coroutine, is_main = coroutine.running()
    if not this_coroutine or is_main then
        error("cannot call await without async")
    end
    return function(...)
        local args = {...}
        queue[#queue+1] = function()
            print("debug coroutine status", coroutine.status(t.coro))
            local ret = { coroutine.resume(t.coro, table.unpack(args)) }
            if ret[1] ~= true then
                error("resume routine fail")
            end
            print("try resume", this_coroutine)
            coroutine.resume(this_coroutine, table.unpack(ret, 2))
        end
        print("await before", this_coroutine)
        return coroutine.yield()
    end
end


-- [[ Start init ]]
function eventLoop()
    local q = queue
    queue = {}
    for i = 1, #q do
        q[i]()
    end
end

--- test async function
--- @param h number # will divide by 2
--- @param r number # will multiply by 2
--- @return number
--- @return number
local async_op = async (function (h, r)
    return h / 2, r * 2
end)


local test = async (function ()
    print("test")
    local v1, v2 = await (async_op)(2, 3)
    print(v1, v2)
end)

print("start")
test()
