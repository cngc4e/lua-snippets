local ping_system
do
    local players = {}
    local packet_received_callback = nil
    local results_callback = nil
    local send_delay_threshold_ms = 0 -- a delay after which the next packet can be sent again after receiving one. used to prevent race causing cheese not getting removed in time.

    -- Cached function lookups
    local os_time = os.time
    local tfm_exec_removeCheese = tfm.exec.removeCheese
    local tfm_exec_movePlayer = tfm.exec.movePlayer

    local function tests_results(numtbl)
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

    local function add_player(pn, test_counts)
        test_counts = test_counts or 4
        players[pn] = { 
            max_tests_count = test_counts,
            tests = { _count = 0 },
            is_awaiting_packet = false,
            packet_sent_time = nil,
            packet_received_time = nil
        }
    end

    local function remove_player(pn)
        players[pn] = nil
    end

    local function set_packet_received_callback(cb)
        packet_received_callback = cb
    end

    local function set_results_callback(cb)
        results_callback = cb
    end

    -- To be hooked on to eventLoop
    local function send_packets()
        local now_epoch = os_time()
        for name, player in pairs(players) do
            if not player.is_awaiting_packet then
                if not player.packet_received_time or now_epoch - player.packet_received_time >= send_delay_threshold_ms then
                    tfm_exec_removeCheese(name)
                    tfm_exec_movePlayer(name, 388, 278)  -- tp to cheese
                    player.packet_sent_time = now_epoch
                    player.is_awaiting_packet = true
                end
            end
        end
    end

    -- To be hooked on to eventPlayerGetCheese
    local function receive_packet(pn)
        local player = players[pn]
        if player and player.is_awaiting_packet then
            local now_epoch = os_time()
            local time_ms = (now_epoch - player.packet_sent_time)
            if packet_received_callback then
                packet_received_callback(pn, time_ms)
            end
            player.packet_received_time = now_epoch
            player.tests[player.tests._count + 1] = time_ms
            player.tests._count = player.tests._count + 1
            player.is_awaiting_packet = false
            if player.tests._count == player.max_tests_count then
                -- end of test
                if results_callback then
                    results_callback(pn, tests_results(player.tests))
                end
                remove_player(pn)
            end
        end
    end

    -- Publicly accessible methods
    ping_system = {
        addPlayer = add_player,
        removePlayer = remove_player,
        setPacketReceivedCallback = set_packet_received_callback,
        setResultsCallback = set_results_callback,
        sendPackets = send_packets,
        receivePacket = receive_packet
    }
end

----------------------
--- sample usage of the PingSystem class
----------------------
ping_system.setPacketReceivedCallback(function(pn, time_ms)
    print(pn..": "..time_ms.."ms")
end)
ping_system.setResultsCallback(function(pn, result)
    print(pn.."'s Average: "..result.average.."ms, Lowest: "..result.lowest.."ms, Highest: "..result.highest.."ms")
end)
function eventLoop()
    ping_system.sendPackets()
end
function eventPlayerGetCheese(pn)
    ping_system.receivePacket(pn)
end
function eventPlayerLeft(pn)
    ping_system.removePlayer(pn)
end

local function init()
    for _,v in ipairs({'AfkDeath','AutoNewGame','AutoScore','AutoShaman','AutoTimeLeft','PhysicalConsumables'}) do
        tfm.exec['disable'..v](true)
    end
    system.disableChatCommandDisplay(nil,true)
end

local function pFind(target)
    local ign = string.lower(target or ' ')
    for name in pairs(tfm.get.room.playerList) do
        if string.lower(name):find(ign) then return name end
    end
end

function eventChatCommand(pn, msg)
    msg = string.lower(msg)
    local args = {}
    for arg in msg:gmatch("[^ ]+") do
        args[#args + 1] = arg
    end
    if args[1] == 'ping' then
        tfm.exec.removeCheese(pn)
        local target, tries = pn, tonumber(args[2])
        if #args >= 2 and not tries then
            local p = pFind(args[2])
            if p then  -- pinging others
                target = p
                tries = tonumber(args[3])
            end
        end
        ping_system.addPlayer(target, tries)
    end
end

init()
tfm.exec.newGame('<C><P /><Z><S><S L="171" X="390" H="10" Y="395" T="4" P="0,0,20,0.2,0,0,0,0" /><S L="10" X="368" H="146" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /><S L="10" H="146" X="408" Y="327" T="1" P="0,0,0,0.2,0,0,0,0" /></S><D><F Y="278" X="388" /><DS Y="375" X="388" /></D><O /></Z></C>')
