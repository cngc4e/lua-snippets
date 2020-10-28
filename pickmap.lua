--[[
    Attempt to pick an element with smaller numbers.

    Usecase:
        Picking a mapcode in a list, given number of rounds played each.
        Algorithm gives higher chance for newer maps with lower plays
        to be picked, eventually closing in their differences in play
        count. This can provide more accurate statistics for the map
        pool.
]]

math.randomseed(os.time())
local pool = {
    12,
    16,
    80,
    86,
    78,
    60,
    90,
    91,
    43,
    200,
    --9834,  -- when adding this, we should realise that the other numbers are chosen more evenly
    12,
}

local cnc = function(chance)
	return math.random(1, 100) < (chance or 50)
end

local pick = function(p, dbg_cb)
    dbg_cb = dbg_cb or function() end
    local sz = #p
    if sz < 1 then return nil end

    local min, max, range = p[1], p[1]
    for i = 2 , sz do
        local m = p[i]
        if m < min then min = m
        elseif m > max then max = m end
    end
    range = max - min
    if range < 1 then return math.random(sz) end  -- lol we're not dividing by zero

    local chosen = 1
    local chosen_pool, cp_sz = {chosen}, 1  -- for elements with similar chances, make a new pool to pick amongst them
    for i = 2 , sz do
        local d = p[chosen] - p[i]
        local ratio = d / range
        dbg_cb("=== ".. i ..".", "diff: "..d, "ratio: "..ratio, "number: "..p[i])
        if ratio > 0.1 then
            local c = math.sqrt(ratio) * 100
            dbg_cb("+ > picking with chance: " .. c)
            if cnc(c) then
                chosen = i
                cp_sz = 0
                dbg_cb("> got picked :O")
            end
        elseif ratio < -0.1 then
            -- reciprocal equation giving more chance to the lows, from range 1 - 10
            local c = 1 / math.abs(ratio)
            dbg_cb("- > picking with chance: " .. c)
            if cnc(c) then
                chosen = i
                cp_sz = 0
                dbg_cb("> got picked :O")
            end
        else
            dbg_cb("> picking with equal chances")
            chosen = i
            cp_sz = cp_sz + 1
            chosen_pool[cp_sz] = i
        end
    end

    for i = 1, cp_sz do dbg_cb("dbg chosen pool: ", chosen_pool[i]) end

    return cp_sz > 1 and chosen_pool[math.random(cp_sz)] or chosen
end

--[[ Tests ]]

local INTERVAL = .2
local MAX = math.huge
local ADD_ONCE_CHOSEN = true  -- simulate real world scenario

local time = nil
local tries = 0

while true do
    if not time or os.clock() >= time then
        local chose = pick(pool, nil)
        print( "\nfinal picked!!", chose, pool[chose])

        if ADD_ONCE_CHOSEN then pool[chose] = pool[chose] + 1 end

        time = os.clock() + INTERVAL
        tries = tries + 1
    end
    if tries >= MAX then break end
end
