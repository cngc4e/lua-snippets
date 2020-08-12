-- Command handler for Transformice
local tfmcmd = {}
do
    local commands = {}

    --- Error enums
    tfmcmd.OK       = 0  -- No errors
    tfmcmd.ENOCMD   = 1  -- No such valid command found
    tfmcmd.EPERM    = 2  -- Permission denied
    tfmcmd.EINVAL   = 3  -- Invalid argument value
    tfmcmd.ETYPE    = 4  -- Invalid argument type
    tfmcmd.ERANGE   = 5  -- Number out of range
    tfmcmd.EOTHER   = 6  -- Other unknown errors

    --- Command types
    local MT_Main = { __index = {
        register = function(self)
            if not self.name or not self.args or not self.func then
                error("Invalid command def")
            end
            commands[self.name] = {
                args = self.args,
                func = self.func,
                call = self.call
            }
            if self.aliases then
                for i = 1, #self.aliases do
                    local alias = self.aliases[i]
                    if commands[alias] then
                        error("Alias '"..alias.."' is duplicated!!")
                    end
                    commands[alias] = commands[self.name]
                end
            end
        end,
        call = function(self, pn, a)
            local args = {}
            local arg_len = #self.args
            for i = 1, arg_len do
                local err, res = self.args[i]:verify(a)
                if err ~= tfmcmd.OK then
                    return err, res
                end
                args[i] = res
            end
            self.func(pn, table.unpack(args, 1, arg_len))
            return tfmcmd.OK
        end,
    }}
    tfmcmd.Main = function(attr)
        return setmetatable(attr or {}, MT_Main)
    end

    local MT_Interface = { __index = {
        register = function(self)
            if not self.commands or not self.args or not self.func then
                error("Invalid command def")
            end
            for i = 1, #self.commands do
                commands[self.commands[i]] = {
                    name = self.commands[i],
                    args = self.args,
                    func = self.func,
                    call = self.call
                }
            end
        end,
        call = function(self, pn, a)
            local args = {}
            local arg_len = #self.args
            for i = 1, arg_len do
                local err, res = self.args[i]:verify(a)
                if err ~= tfmcmd.OK then
                    return err, res
                end
                args[i] = res
            end
            self.func(pn, self.name, table.unpack(args, 1, arg_len))
            return tfmcmd.OK
        end,
    }}
    tfmcmd.Interface = function(attr)
        return setmetatable(attr or {}, MT_Interface)
    end

    --- Argument types
    local MT_ArgPlayerName = { __index = {
        verify = function(self, a)
            local str = a[a.current]
            if not str then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EINVAL, "missing argument"
                end
            end
            local ign = str:lower()
            for name in pairs(tfm.get.room.playerList) do
                if string.lower(name):find(ign) then
                    a.current = a.current + 1  -- go up one word
                    return tfmcmd.OK, name
                end
            end
            return tfmcmd.EOTHER, "No such player found."
        end,
    }}
    tfmcmd.ArgPlayerName = function(attr)
        return setmetatable(attr or {}, MT_ArgPlayerName)
    end

    local MT_ArgString = { __index = {
        verify = function(self, a)
            local str = a[a.current]
            if not str then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EINVAL, "missing argument"
                end
            end
            a.current = a.current + 1  -- go up one word
            return tfmcmd.OK, str
        end,
    }}
    tfmcmd.ArgString = function(attr)
        return setmetatable(attr or {}, MT_ArgString)
    end

    local MT_ArgJoinedString = { __index = {
        verify = function(self, a)
            local join = {}
            local max_index = a._len
            if self.length then
                max_index = math.min(a._len, a.current + self.length - 1)
            end
            for i = a.current, max_index do
                a.current = i + 1  -- go up one word
                join[#join + 1] = a[i]
            end
            if #join == 0 then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EINVAL, "missing argument"
                end
            end
            return tfmcmd.OK, table.concat(join, " ")
        end,
    }}
    tfmcmd.ArgJoinedString = function(attr)
        return setmetatable(attr or {}, MT_ArgJoinedString)
    end

    local MT_ArgNumber = { __index = {
        verify = function(self, a)
            local word = a[a.current]
            if not word then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EINVAL, "missing argument"
                end
            end
            local res = tonumber(word)
            if not res then
                return tfmcmd.ETYPE, "Expected number"
            end
            if a.min and res < a.min then
                return tfmcmd.ERANGE, "Min: " .. a.min
            end
            if a.max and res > a.min then
                return tfmcmd.ERANGE, "Max: " .. a.max
            end
            a.current = a.current + 1  -- go up one word
            return tfmcmd.OK, res
        end,
    }}
    tfmcmd.ArgNumber = function(attr)
        return setmetatable(attr or {}, MT_ArgNumber)
    end

    --- Methods
    tfmcmd.initCommands = function(cmds)
        for i = 1, #cmds do
            cmds[i]:register()
        end
    end

    tfmcmd.executeChatCommand = function(pn, msg)
        local words = { current = 2, _len = 0 }  -- current = index of argument which is to be accessed first in the next arg type
        for word in msg:gmatch("[^ ]+") do
            words._len = words._len + 1
            words[words._len] = word
        end
        if commands[words[1]] then
            return commands[words[1]]:call(pn, words)
        else
            return tfmcmd.ENOCMD, "no command found"
        end
    end
end

local commands = {
    tfmcmd.Main {
        name = "shaman",
        aliases = {"sham"},
        description = "Sets player as shaman",
        args = {
            tfmcmd.ArgPlayerName { optional = true },
        },
        func = function(pn, target)
            tfm.exec.setShaman(pn, target)
        end,
    },
    tfmcmd.Main {
        name = "score",
        description = "Sets player score to specified",
        args = {
            tfmcmd.ArgPlayerName { optional = true },
            tfmcmd.ArgNumber { default = 0 },
        },
        func = function(pn, target, score)
            tfm.exec.setPlayerScore(pn, target, score)
        end,
    },
    tfmcmd.Main {
        name = "map",
        aliases = {"np"},
        description = "Loads specified map",
        args = {
            tfmcmd.ArgString { optional = true },
            tfmcmd.ArgString { optional = true },
        },
        func = function(pn, code, arg)
            tfm.exec.chatMessage("code "..(code or "none"))
            tfm.exec.newGame(code, arg == "mirror")
        end,
    },
    tfmcmd.Interface {
        name = "spidiv",
        commands = {"spiritual", "divinity"},
        description = "Plays a random spiritual/divinity map of specified difficulty",
        args = {
            tfmcmd.ArgNumber { min = 1 },
            tfmcmd.ArgNumber { min = 1, optional = true },
        },
        func = function(pn, cmd, n1, n2)

        end,
    },
    tfmcmd.Main {
        name = "a",
        aliases = {"me"},
        description = "MEME",
        args = {
            tfmcmd.ArgJoinedString { length = 4, default = "pooped" },
        },
        func = function(pn, msg)
            tfm.exec.chatMessage("<T>*"..pn.." "..msg)
        end,
    },
}

tfmcmd.initCommands(commands)

function eventChatCommand(pn, msg)
    local ret, msg = tfmcmd.executeChatCommand(pn, msg)
    if ret ~= tfmcmd.OK then
        tfm.exec.chatMessage("<R>error" .. (msg and (": "..msg) or ""), pn)
    end
end
