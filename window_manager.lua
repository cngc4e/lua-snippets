local WINDOW_TESTING = bit32.lshift(0, 8)
do
    sWindow = {}
    local INDEPENDENT = 1  -- window is able to stay open regardless of other open windows
    local MUTUALLY_EXCLUSIVE = 2  -- window will close other mutually exclusive windows that are open

    -- WARNING: No error checking, ensure that all your windows have all the required attributes (open, close, type, players)
    local windows = {
        [WINDOW_TESTING] = {
            open = function(pn, p_data, page)
                if not p_data.page then
                    ui.addTextArea(WINDOW_TESTING+1, "", pn, 10, 10, 700, 300)
                end
                if page == 1 then
                    p_data.page = 1
                    ui.addTextArea(WINDOW_TESTING+2, "wow", pn, 100, 100, 50, 50)
                    ui.addTextArea(WINDOW_TESTING+3, "whut", pn, 200, 100, 50, 50)
                    p_data.images['haha_picture'] = tfm.exec.addImage("1729bab289f.png","%Casserole",-21,-30)
                elseif page == 2 then
                    p_data.page = 2
                    ui.removeTextArea(WINDOW_TESTING+2)
                    ui.removeTextArea(WINDOW_TESTING+3)
                    ui.addTextArea(WINDOW_TESTING+4, "damn", pn, 200, 200, 50, 50)
                    ui.addTextArea(WINDOW_TESTING+5, "rofl", pn, 300, 200, 50, 50)
                end
            end,
            close = function(pn, p_data)
                ui.removeTextArea(WINDOW_TESTING+1)
                ui.removeTextArea(WINDOW_TESTING+2)
                ui.removeTextArea(WINDOW_TESTING+3)
                ui.removeTextArea(WINDOW_TESTING+4)
                ui.removeTextArea(WINDOW_TESTING+5)
                tfm.exec.removeImage(p_data.images['haha_picture'])
                p_data.images['haha_picture'] = nil
            end,
            type = MUTUALLY_EXCLUSIVE,
            players = {}
        },
    }

    sWindow.open = function(window_id, pn, ...)
        if not windows[window_id] then
            return
        elseif not windows[window_id].players[pn] then
            windows[window_id].players[pn] = {images = {}}
        end
        if windows[window_id].type == MUTUALLY_EXCLUSIVE then
            for w_id, w in pairs(windows) do
                if w_id ~= window_id and w.type == MUTUALLY_EXCLUSIVE then
                    sWindow.close(w_id, pn)
                end
            end
        end
        windows[window_id].players[pn].is_open = true
        windows[window_id].open(pn, windows[window_id].players[pn], table.unpack(arg))
    end

    sWindow.close = function(window_id, pn)
        if sWindow.isOpened(window_id, pn) then
            windows[window_id].players[pn].is_open = false
            windows[window_id].close(pn, windows[window_id].players[pn])
        end
    end

    -- Hook this on to eventPlayerLeft, where all of the player's windows would be closed
    sWindow.clearPlayer = function(pn)
        for w_id in pairs(windows) do
            windows[w_id].players[pn] = nil
        end
    end

    sWindow.isOpened = function(window_id, pn)
        return windows[window_id]
            and windows[window_id].players[pn]
            and windows[window_id].players[pn].is_open
    end
end

for name in pairs(tfm.get.room.playerList) do
    sWindow.open(WINDOW_TESTING, name, 1)
    system.newTimer(function(id) sWindow.open(WINDOW_TESTING, name, 2) end, 3000, false)
    system.newTimer(function(id) sWindow.close(WINDOW_TESTING, name) end, 6000, false)
end

eventPlayerLeft = function(pn)
    sWindow.clearPlayer(pn)
end
