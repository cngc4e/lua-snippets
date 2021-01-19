local order = {
    -- Lua 5.1
    "add",
    "sub",
    "mul",
    "div",
    "mod",
    "pow",
    "unm",
    "concat",
    "eq",
    "lt",
    "le",
    "index",
    "newindex",
    "call",
    "metatable",
    "tostring",
    -- Lua 5.2
    "len",
    "pairs",
    "ipairs",
}

local invoke = {
    ["add"] = function(metatbl)
        local _ = metatbl + 0
    end,
    ["sub"] = function(metatbl)
        local _ = metatbl - 0
    end,
    ["mul"] = function(metatbl)
        local _ = metatbl * 0
    end,
    ["div"] = function(metatbl)
        local _ = metatbl / 0
    end,
    ["mod"] = function(metatbl)
        local _ = metatbl % 0
    end,
    ["pow"] = function(metatbl)
        local _ = metatbl ^ 0
    end,
    ["unm"] = function(metatbl)
        local _ = -metatbl
    end,
    ["concat"] = function(metatbl)
        local _ = metatbl .. ""
    end,
    ["eq"] = function(metatbl)
        -- http://lua-users.org/wiki/MetatableEvents
        -- "This method is invoked when "myTable1 == myTable2" is evaluated, but only if both tables have the exact same metamethod for __eq.
        local tmp_mt = setmetatable({}, getmetatable(metatbl))
        local _ = metatbl == tmp_mt
    end,
    ["lt"] = function(metatbl)
        -- Normal Lua seems to have no need for the both tables to have the same metamethod in
        -- order to invoke the corresponding metamethod, but LuaJ seems to require so
        local tmp_mt = setmetatable({}, getmetatable(metatbl))
        local _ = metatbl < tmp_mt
    end,
    ["le"] = function(metatbl)
        -- Normal Lua seems to have no need for the both tables to have the same metamethod in
        -- order to invoke the corresponding metamethod, but LuaJ seems to require so
        local tmp_mt = setmetatable({}, getmetatable(metatbl))
        local _ = metatbl <= tmp_mt
    end,
    ["index"] = function(metatbl)
        local _ = metatbl[0]
    end,
    ["newindex"] = function(metatbl)
        metatbl[0] = 0
    end,
    ["call"] = function(metatbl)
        metatbl()
    end,
    ["tostring"] = function(metatbl)
        local _ = tostring(metatbl)
    end,
    ["len"] = function(metatbl)
        local _ = #metatbl
    end,
    ["pairs"] = function(metatbl)
        for k, v in pairs(metatbl) do break end
    end,
    ["ipairs"] = function(metatbl)
        for k, v in ipairs(metatbl) do break end
    end,
}

local test_overrides = {
    ["metatable"] = function(metamthd)
        local cmp_mt = {cmp=0}
        local test = setmetatable({}, {
            ["__" .. metamthd] = cmp_mt
        })

        return getmetatable(test) == cmp_mt
    end,
}

local test_func = function(metamthd)
    if test_overrides[metamthd] then return test_overrides[metamthd](metamthd) end
    local result = nil

    local test = setmetatable({}, {
        ["__" .. metamthd] = function()
            result = true
        end
    })

    if invoke[metamthd] then
        result = false
        pcall(invoke[metamthd], test)
    end

    return result
end

print("[] Checking metamethods...")
for i = 1, #order do
    local result = test_func(order[i])
    print(("\t%s ... %s"):format(order[i], result == nil and "NO TEST" or (result and "PASS" or "FAIL") ))
end
