local window = {}
do
    local windows = {}
    window.__index = window

    local function get(pn, window_id)
        if not windows[pn] then
            windows[pn] = {}
        elseif windows[pn][window_id]
                and getmetatable(windows[pn][window_id]) then
            return windows[pn][window_id]
        end
        windows[pn][window_id] = {
            window_id = window_id,
            pn = pn,
            ta_ids = { },
            img_ids = {},
            ta_id_highest = 0,
            is_persistent = false
        }
        return setmetatable(windows[pn][window_id], window)
    end

    local function clearAll(pn)
        windows[pn] = nil
    end

    function window:addImage(name, target, x, y)
        local img_id = tfm.exec.addImage(name, target, x, y, self.pn)
        self.img_ids[img_id] = self.is_persistent
    end

    function window:addTextArea(text, x, y, width, height, bg_c, bd_c, bg_a, fixed)
        local id = self.window_id + self.ta_id_highest + 1
        ui.addTextArea(id, text, self.pn, x, y, width, height, bg_c, bd_c, bg_a, fixed)
        self.ta_ids[id] = self.is_persistent
        self.ta_id_highest = self.ta_id_highest + 1
    end

    -- elements added after calling this function will have their persistance flag set accordingly
    function window:setPersistent(b)
        self.is_persistent = b
    end

    function window:partialClose()
        for id, persist in pairs(self.ta_ids) do
            if not persist then
                ui.removeTextArea(id, self.pn)
            end
        end
        for id, persist in pairs(self.img_ids) do
            if not persist then
                tfm.exec.removeImage(id)
            end
        end
        self.is_persistent = false
    end

    function window:close()
        for id in pairs(self.ta_ids) do
            ui.removeTextArea(id, self.pn)
        end
        for id in pairs(self.img_ids) do
            tfm.exec.removeImage(id)
        end
        self.ta_ids = {}
        self.img_ids = {}
        self.ta_id_highest = 0
        self.is_persistent = false
    end

    window.get = get
end

----------------------
--- sample usage 
----------------------
function eventPlayerLeft(pn)
    window.clearAll(pn)
end

local wdw = window.get("Casserole", 69)
wdw:setPersistent(true)
wdw:addTextArea("", 10, 10, 700, 300)
wdw:setPersistent(false)
wdw:addTextArea("wow", 100, 100, 50, 50)
wdw:addTextArea("whut", 200, 100, 50, 50)
wdw:addImage("1729bab289f.png","%Casserole",-21,-30)

system.newTimer(function(id, w) w:partialClose() end, 3000, false, wdw)
system.newTimer(function(id, w) w:close() end, 6000, false, wdw)
