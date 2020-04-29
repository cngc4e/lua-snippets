local players = {}

local PingSystem
do
    PingSystem = { }
    PingSystem.__index = PingSystem

    local tests_results = function(numtbl)
        local sum, lowest, highest, cnt = 0, numtbl[1], numtbl[1], numtbl._count
        for i = 1, cnt do
            sum = sum + numtbl[i]
            if numtbl[i] > highest then
                highest = numtbl[i]
            elseif numtbl[i] < lowest then
                lowest = numtbl[i]
            end
        end
        return { average = sum / cnt, lowest = lowest, highest = highest }
    end

    function PingSystem:new()
        return setmetatable({
            players = {},
            callback = nil
        }, self)
    end

    function PingSystem:addPlayer(pn, test_counts)
        test_counts = test_counts or 4
        self.players[pn] = { 
            max_tests_count = test_counts,
            tests = { _count = 0 },
            is_awaiting_packet = false,
            packet_sent_time = nil
        }
    end

    function PingSystem:removePlayer(pn)
        self.players[pn] = nil
    end

    function PingSystem:setCallback(cb)
        self.callback = cb
    end

    -- To be hooked on to eventLoop
    function PingSystem:sendPackets()
        local now_epoch = os.time()
        for name, player in pairs(self.players) do
            if not player.is_awaiting_packet then
                tfm.exec.movePlayer(name, 388, 278)  -- tp to cheese
                player.packet_sent_time = now_epoch
                player.is_awaiting_packet = true
            end
        end
    end

    -- To be hooked on to eventPlayerGetCheese
    function PingSystem:receivePacket(pn)
        local player = self.players[pn]
        if player and player.is_awaiting_packet then
            local time_ms = (os.time() - player.packet_sent_time)
            print(pn..": "..time_ms.."ms")
            player.tests[player.tests._count + 1] = time_ms
            player.tests._count = player.tests._count + 1
            player.is_awaiting_packet = false
            tfm.exec.removeCheese(pn)
            if player.tests._count == player.max_tests_count then
                -- end of test
                self:removePlayer(pn)
                local result = tests_results(player.tests)
                print(pn.."'s Average: "..result.average.."ms, Lowest: "..result.lowest.."ms, Highest: "..result.highest)
            end
        end
    end
end

local ps = PingSystem:new()
function eventLoop()
    ps:sendPackets()
end
function eventPlayerGetCheese(pn)
    ps:receivePacket(pn)
end

local function init()
    for _,v in ipairs({'AfkDeath','AutoNewGame','AutoScore','AutoShaman','AutoTimeLeft','PhysicalConsumables'}) do
        tfm.exec['disable'..v](true)
    end
    system.disableChatCommandDisplay(nil,true)
    for name in pairs(tfm.get.room.playerList) do eventNewPlayer(name) end
end

--function __eventLoop()
--    for name,p in pairs(tfm.get.room.playerList) do
--        if players[name].is_tracking then
--            local x,y = p.x-1, p.y-2
--            --print(x.." , "..y)
--            ui.addTextArea(1, "", nil, x, y, 4, 4, 0xfc572d, 0xffffff, .5, false)
--            --ui.addTextArea(2,"<J>"..players[name].track_name,nil,x,y,4,4,1,0,0.8,true)
--        end
--    end   
--end

function eventKeyboard(pn, key, down, x, y)
    if players[pn].is_tracking then
        x,y = x-1, y-2
        --print(x.." , "..y)
        ui.addTextArea(1, "", nil, x, y, 4, 4, 0xfc572d, 0xffffff, .5, false)
        --ui.addTextArea(2,"<J>"..players[name].track_name,nil,x,y,4,4,1,0,0.8,true)
    end
    --eventLoop()
end

local last_pid = 0
function eventNewPlayer(pn)
    last_pid = last_pid + 1
    players[pn] = {
        pid = last_pid,
        is_tracking = false,
    }
    tfm.exec.bindKeyboard(pn, 32, true)
    tfm.exec.bindKeyboard(pn, 32, false)
end

function eventPlayerLeft(pn)
    if players[pn] then
        players[pn].is_tracking = false
    end
end

function eventChatCommand(pn, msg)
    msg = string.lower(msg)
    local args = {}
    for arg in msg:gmatch("[^ ]+") do
        args[#args + 1] = arg
    end
    if args[1] == "track" then
        if players[pn].is_tracking then
            players[pn].is_tracking = false
            ui.removeTextArea(players[pn].pid)
        else
            players[pn].track_name = args[2] or pn
            players[pn].is_tracking = true
            --eventLoop()
        end
    elseif args[1] == 'np' or args[1] == 'map' then
        tfm.exec.newGame(args[2])
    elseif args[1] == 'ping' then
        tfm.exec.removeCheese(pn)
        ps:addPlayer(pn, tonumber(args[2]))
    end
end

init()
tfm.exec.newGame('<C><P /><Z><S><S L="171" X="390" H="10" Y="395" T="4" P="0,0,20,0.2,0,0,0,0" /><S L="10" X="368" H="146" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /><S L="10" H="146" X="408" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /></S><D><F Y="278" X="388" /><DS Y="375" X="388" /></D><O /></Z></C>')
