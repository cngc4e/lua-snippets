local window = {}
do
    local windows = {}
    window.__index = window

    local function get(window_id, pn)
        if not windows[window_id] then
            windows[window_id] = {}
        elseif windows[window_id][pn]
                and getmetatable(windows[window_id][pn]) then
            return windows[window_id][pn]
        end
        windows[window_id][pn] = {
            window_id = window_id,
            pn = pn,
            ta_ids = { _count = 0 },
            img_ids = { _count = 0 },
        }
        return setmetatable(windows[window_id][pn], window)
    end

    function window:addImage(name, target, x, y)
        local img_id = tfm.exec.addImage(name, target, x, y, self.pn)
        self.img_ids[self.img_ids._count + 1] = img_id
        self.img_ids._count = self.img_ids._count + 1
    end

    function window:addTextArea(text, x, y, width, height, bg_c, bd_c, bg_a, fixed)
        local id = self.window_id + self.ta_ids._count + 1
        ui.addTextArea(id, text, self.pn, x, y, width, height, bg_c, bd_c, bg_a, fixed)
        self.ta_ids[self.ta_ids._count + 1] = id
        self.ta_ids._count = self.ta_ids._count + 1
    end

    function window:partialClose()  -- TODO
    end

    function window:close()
        for i = 1, self.ta_ids._count do
            ui.removeTextArea(self.ta_ids[i], self.pn)
        end
        for i = 1, self.img_ids._count do
            tfm.exec.removeImage(self.img_ids[i])
        end
    end

    window.get = get
end

----------------------
--- sample usage 
----------------------
local wdw = window.get(69, "Casserole")
wdw:addTextArea("wow", 100, 100, 50, 50)
wdw:addTextArea("whut", 200, 100, 50, 50)
wdw:addImage("1729bab289f.png","%Casserole",-21,-30)

system.newTimer(function(id, w) w:close() end, 3000, false, wdw)
