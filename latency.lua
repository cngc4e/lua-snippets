local players = {}

local PingSystem
do
    PingSystem = { }
    PingSystem.__index = PingSystem

    local send_delay_threshold_ms = 0 -- a delay after which the next packet can be sent again after receiving one. used to prevent race causing cheese not getting removed in time.

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
            packet_sent_time = nil,
            packet_received_time = nil
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
                if not player.packet_received_time or now_epoch - player.packet_received_time >= send_delay_threshold_ms then
                    tfm.exec.removeCheese(name)
                    tfm.exec.movePlayer(name, 388, 278)  -- tp to cheese
                    player.packet_sent_time = now_epoch
                    player.is_awaiting_packet = true
                end
            end
        end
    end

    -- To be hooked on to eventPlayerGetCheese
    function PingSystem:receivePacket(pn)
        local player = self.players[pn]
        if player and player.is_awaiting_packet then
            local now_epoch = os.time()
            local time_ms = (now_epoch - player.packet_sent_time)
            print(pn..": "..time_ms.."ms")
            player.packet_received_time = now_epoch
            player.tests[player.tests._count + 1] = time_ms
            player.tests._count = player.tests._count + 1
            player.is_awaiting_packet = false
            if player.tests._count == player.max_tests_count then
                -- end of test
                self:removePlayer(pn)
                local result = tests_results(player.tests)
                print(pn.."'s Average: "..result.average.."ms, Lowest: "..result.lowest.."ms, Highest: "..result.highest.."ms")
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
end

function eventChatCommand(pn, msg)
    msg = string.lower(msg)
    local args = {}
    for arg in msg:gmatch("[^ ]+") do
        args[#args + 1] = arg
    end
    if args[1] == 'ping' then
        tfm.exec.removeCheese(pn)
        ps:addPlayer(pn, tonumber(args[2]))
    end
end

init()
tfm.exec.newGame('<C><P /><Z><S><S L="171" X="390" H="10" Y="395" T="4" P="0,0,20,0.2,0,0,0,0" /><S L="10" X="368" H="146" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /><S L="10" H="146" X="408" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /></S><D><F Y="278" X="388" /><DS Y="375" X="388" /></D><O /></Z></C>')
