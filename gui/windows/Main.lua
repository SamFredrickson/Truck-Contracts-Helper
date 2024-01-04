local moonloader = require "moonloader"
local imgui = require 'mimgui'
local encoding = require "encoding"

local Window = require 'tch.gui.windows.window'
local Utils = require 'tch.common.utils'
local Command = require 'tch.samp.commands.command'
local MenuDialogue = require 'tch.samp.dialogues.menu'

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Main = {
    new = function()
        local self = Window.new()

        local sizes = imgui.ImVec2(300, 345)
        local posX, posY = getScreenResolution()
        local title = u8"Список контрактов"
        local hideCursor = true

        self.contracts = {}

        local frame = imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
              imgui.SetNextWindowPos(imgui.ImVec2(posX / 2, posY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
              imgui.SetNextWindowSize(sizes, imgui.Cond.FirstUseEver)
              imgui.Begin(title, self.window, imgui.WindowFlags.NoResize)
              player.HideCursor = hideCursor

              for number, contract in ipairs(self.contracts) do
                local header = string.format(
                    "%d. %s -> %s", 
                    contract.id, 
                    contract.source, 
                    contract.destination
                )
                if imgui.CollapsingHeader(u8(header)) then
                    if imgui.Button(string.format("GPS ##%d", contract.id)) then
                        print(string.format("GPS %d", contract.id))
                    end
                    imgui.SameLine()
                    if imgui.Button("TAKE") then
                    end
                end
              end

              imgui.End()
            end
        )

        sampRegisterChatCommand(
            'tch.contracts',
            function() self.toggle() end
        )

        sampRegisterChatCommand(
            'tch.contracts.cursor',
            function() hideCursor = not hideCursor end
        )

        lua_thread.create(function()
            while true do
                wait(2000)
                if hideCursor and not sampIsDialogActive() and self.window[0] then
                    MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
                    sampSendChat('/tmenu')
                end
            end
        end)

        -- lua_thread.create(function()
        --     while true do
        --         wait(10)
        --         local result = isKeyDown(VK_LCONTROL)
        --         if result then hideCursor = false end
        --         if not result then hideCursor = true end
        --     end
        -- end)

        return self
    end
}

return Main