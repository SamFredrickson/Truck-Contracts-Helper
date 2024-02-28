local imgui = require "mimgui"
local new = imgui.new

local Window = {
    new = function()
        local self = {}
        self.window = new.bool(false)

        function self.activate()
            self.window[0] = true
        end

        function self.deactivate()
            self.window[0] = false
        end

        function self.toggle()
            self.window[0] = not self.window[0]
        end

        return self
    end
}

return Window