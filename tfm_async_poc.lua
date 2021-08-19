
--- [[ Set up debugging and init queue (for event loop)]]
IS_DEBUGGING = true
queue = {}
function verbose(...)
    if IS_DEBUGGING then
        print("[DBG]", ...)
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
do

--- A unique pointer indicating an error thrown in the coroutine.
local ERROR_COROUTINE = { error = 0x03 }

--- Handles the resumption of a yielded coroutine.
--- Returns the coroutine return values, throws in case of error.
local function afterYield(...)
    if select(1, ...) == ERROR_COROUTINE then
        verbose("caught an error from awaiting")
        error(select(2, ...), 0)
    end
    return ...
end

--- Handles the return values of the yielded coroutine.
--- Throws in case of error.
local function afterResume(...)
    if select(1, ...) ~= true then
        verbose("caught an error in afterResume")
        error(select(2, ...), 0)
    end
end

--- Handles the return values of the yielded coroutine.
--- Returns the coroutine return values in succession, otherwise ERROR_COROUTINE plus any error message.
local function afterResumePropagate(...)
    local len = select("#", ...)
    local retvals = {...}
    if retvals[1] ~= true then
        return ERROR_COROUTINE, retvals[2]
    end
    return table.unpack(retvals, 2, len)
end

--- async
--- @generic T
--- @param fnc T
--- @return T
function async(fnc)
    local t = {}
    t.fnc = fnc
    setmetatable(t, {
        __call = function()
            local coro = coroutine.create(fnc)
            -- no return because not awaited
            queue[#queue+1] = function()
                assert(coroutine.status(coro) == "suspended",
                    "Could not resume couroutine that is in state: " .. coroutine.status(coro))
                -- Any errors thrown from coro are rethrown in this context, since there is no one awaiting.
                afterResume(coroutine.resume(coro))
            end
        end
    })
    return t
end

--- await
--- @generic T
--- @param t T
--- @return T
function await(t)
    local this_coroutine, is_main = coroutine.running()
    if not this_coroutine or is_main then
        error("cannot call await without async")
    end
    local coro = coroutine.create(t.fnc)
    return function(...)
        local args_len = select("#", ...)
        local args = {...}
        queue[#queue+1] = function()
            assert(coroutine.status(coro) == "suspended",
                "Could not resume couroutine that is in state: " .. coroutine.status(coro))

            -- For debugging purposes, we want to log *after* resuming coro and *before* resuming
            -- this_coroutine. Add a wrapping logger around afterResumePropagate() if debugging.
            local afterResumePropagate = afterResumePropagate
            if IS_DEBUGGING then
                local original_fnc = afterResumePropagate
                afterResumePropagate = function(...)
                    local saveRetVals = function (...)
                        return select("#", ...), {...}
                    end
                    local len, saved_retvals = saveRetVals(original_fnc(...))
                    verbose("debug executing coroutine status", coroutine.status(coro))
                    return table.unpack(saved_retvals, 1, len)
                end
            end

            -- Cross-eyed? It's okay me too.
            -- 1. Resume this_coroutine with the return values of coro
            -- 2. Any errors thrown from this_coroutine (unhandled) are rethrown in this context per
            --    default behavior. At this point it's not wrong to say that no one is awaiting.
            afterResume(
                coroutine.resume(
                    this_coroutine,
                    afterResumePropagate(coroutine.resume(coro, table.unpack(args, 1, args_len)))
                )
            )
        end
        verbose("await before", this_coroutine)
        return afterYield(coroutine.yield())
    end
end

end

-- [[ A basic try / catch implementation ]]

--- try catch
--- @param fnc fun() # The function to execute synchronously.
--- @param catchFnc fun(e: string) # The function to execute synchronously if `fnc` throws.
function trycatch(fnc, catchFnc)
    local status, exception = pcall(fnc)
    if not status then
        catchFnc(exception)
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

--- test async yield function
--- @return number
local async_for_op = async (function ()
    for i = 1, 4 do
        coroutine.yield(i)
    end
end)

--- test async exception function
--- @param throw boolean # whether to throw
--- @return string
local async_error = async (function(throw)
    if throw then error("thrown error!") end
    return "success !"
end)

--- the main test !
local test = async (function ()
    print("test basic return")
    local v1, v2 = await (async_op)(2, 3)
    print(v1, v2)

    print("now let's count to four !")
    -- We must create a coroutine container to ensure that the context is saved from yielding.
    local await_container = await (async_for_op)
    local val = await_container()
    while val ~= nil do
        print(val)
        val = await_container()
    end

    print("and then let's bite the dust...")
    local r1
    trycatch(function ()
        print(await (async_error)(false))
        r1 = await (async_error)(true)
        print(await (async_error)(false))
    end, function (e)
        r1 = e
    end)

    print(r1)

end)

--IS_DEBUGGING = false
print("start")
test()

if not tfm then
    -- [[ Start the Event Loop for non-TFM environments ]]
    --[[]]
    function wait(n)
        -- By geniuses @ https://stackoverflow.com/q/17987618
        local waiter = io.popen("ping -n " .. tonumber(n+1) .. " localhost > NUL")
        waiter:close()
    end

    while true do
        wait(1)
        eventLoop()
    end
end
