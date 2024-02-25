local imgui = require "mimgui"
local encoding = require "encoding"

local Window = require "tch.gui.windows.window"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Demo = {
    new = function()
        local self = Window.new()

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
              imgui.Begin("Demo")
              imgui.ShowDemoWindow()
              imgui.End()
            end
        )

        sampRegisterChatCommand(
            'tch.demo',
            function() self.toggle() end
        )

        return self
    end
}

return Demo