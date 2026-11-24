local imgui = require "mimgui"
local Palette = require "tch.gui.themes.palette"
local new = imgui.new

local Window = {
    new = function()
        local self = {}
        self.window = new.bool(false)
        function self.activate() self.window[0] = true end
        function self.deactivate() self.window[0] = false end
        function self.toggle() self.window[0] = not self.window[0] end
        return self
    end
}

function Window.reportSave(saved, err)
    if saved then return true end

    sampAddChatMessage(Palette.recolor(" {ed5a5a}[TCH]{FFFFFF} Не удалось сохранить изменения. Подробности в журнале MoonLoader.", true), -1)
    print("[TCH] " .. tostring(err or "Unable to save settings"))
    return false
end

return Window