
--- [[ Set up debugging and init queue (for event loop)]]
IS_DEBUGGING = true
queue = {}
function verbose(...)
    if IS_DEBUGGING then
        print(...)
    end
end

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

local ERROR_COROUTINE = { error = 0x03 }

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
            verbose("debug coroutine status", coroutine.status(t.coro))
            local ret = { coroutine.resume(t.coro, table.unpack(args)) }
            if ret[1] ~= true then
                verbose("try resume after error")
                --- @type string
                local errmsg = ret[2]
                if type(errmsg) == "string" then
                    errmsg = errmsg:match("^%S*:?%d*:? ?(.-)$")
                else
                    errmsg = "Unknown error thrown in " .. tostring(t.coro)
                end
                coroutine.resume(this_coroutine, ERROR_COROUTINE, errmsg)
            else
                verbose("try resume", this_coroutine)
                coroutine.resume(this_coroutine, table.unpack(ret, 2))
            end
        end
        verbose("await before", this_coroutine)
        return coroutine.yield()
    end
end

--- async error check
---
--- unfortunately due to the limitations of lua coroutines, we're unable
--- to resume the thread and throw an error immediately. so we have to rely
--- on the fact that the first return value may possibly be an error value.
--- this function checks for that.
--- @param val any # the first return value of the await
--- @return boolean
local function isAsyncError(val)
    return val == ERROR_COROUTINE
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

--- test async yield function
--- @return number
local async_for_op = async (function ()
    for i = 1, 4 do
        coroutine.yield(i)
    end
end)

--- test async exception function
local async_error = async (function()
    error("thrown error!")
    return "success apparently?!"
end)

--- the main test !
local test = async (function ()
    print("test basic return")
    local v1, v2 = await (async_op)(2, 3)
    print(v1, v2)

    print("now let's count to four !")
    local await_container = await (async_for_op)
    local val = await_container()
    while val ~= nil do
        print(val)
        val = await_container()
    end

    print("and then let's bite the dust...")
    local r1, e = await (async_error)()
    if isAsyncError(r1) then
        -- Equivalent of a 'catch' block
        r1 = e
    end

    print(r1)

end)

--IS_DEBUGGING = false
print("start")
test()

-- [[ Start the Event Loop for non-TFM environments ]]
--[[
function wait(n)
    -- By geniuses @ https://stackoverflow.com/q/17987618
    local waiter = io.popen("ping -n " .. tonumber(n+1) .. " localhost > NUL")
    waiter:close()
end

while true do
    wait(1)
    eventLoop()
end]]
