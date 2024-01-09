local moonloader = require "moonloader"
local imgui = require 'mimgui'
local encoding = require "encoding"

local constants = require 'tch.constants'
local Window = require 'tch.gui.windows.window'
local Utils = require 'tch.common.utils'
local Command = require 'tch.samp.commands.command'
local MenuDialogue = require 'tch.samp.dialogues.menu'

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Main = {
    new = function()
        local self = Window.new()

        local sizes = imgui.ImVec2(410, 370)
        local posX, posY = getScreenResolution()

        self.hideCursor = true
        self.contracts = {}

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
              local windowTitle = string.format(u8"Список контрактов (%d)", #self.contracts)
              imgui.SetNextWindowPos(imgui.ImVec2(posX / 2, posY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
              imgui.SetNextWindowSize(sizes, imgui.Cond.FirstUseEver)
              imgui.Begin(windowTitle, self.window, imgui.WindowFlags.NoResize)
              player.HideCursor = self.hideCursor

              for number, contract in ipairs(self.contracts) do

                local headerTitle = string.format(
                    "%s%d. %s -> %s[%d / %d]", 
                    contract.top and "[TOP] " or "",
                    contract.id, 
                    contract.source, 
                    contract.destination,
                    contract.amount.first,
                    contract.amount.second
                )

                if imgui.CollapsingHeader(u8(headerTitle)) then
                    if imgui.Button(string.format(u8"Взять контракт ##%d", contract.id)) and MenuDialogue.isTakingAllowed(self.window[0]) then
                       MenuDialogue.take(contract.id)
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Взять контракт и загрузить ##%d", contract.id)) and MenuDialogue.isTakingAllowed(self.window[0]) then
                        lua_thread.create(function()
                            MenuDialogue.take(contract.id)
                            wait(1000)
                            MenuDialogue.load()
                            return
                        end)
                     end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Загрузить ##%d", contract.id)) then
                        MenuDialogue.load()
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"GPS ##%d", contract.id)) then
                        print("GPS")
                    end
                    if imgui.Button(string.format(u8"Отменить ##%d", contract.id)) then
                        MenuDialogue.cancel()
                    end
                end
              end

              imgui.End()
            end
        )

        return self
    end
}

return Main