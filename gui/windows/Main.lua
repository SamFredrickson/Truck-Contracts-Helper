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
        local title = u8"Список контрактов"
        local hideCursor = true
        self.contracts = {}

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
              imgui.SetNextWindowPos(imgui.ImVec2(posX / 2, posY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
              imgui.SetNextWindowSize(sizes, imgui.Cond.FirstUseEver)
              imgui.Begin(title, self.window, imgui.WindowFlags.NoResize)
              player.HideCursor = hideCursor

              for number, contract in ipairs(self.contracts) do

                local title = string.format(
                    "%s%d. %s -> %s[%d / %d]", 
                    contract.top and "[TOP] " or "",
                    contract.id, 
                    contract.source, 
                    contract.destination,
                    contract.amount.first,
                    contract.amount.second
                )

                if imgui.CollapsingHeader(u8(title)) then
                    if imgui.Button(string.format(u8"Взять контракт ##%d", contract.id)) and MenuDialogue.isTakingAllowed(self.window[0]) then
                       MenuDialogue.take(contract.id)
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Загрузить ##%d", contract.id)) then
                        MenuDialogue.load()
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Сообщить о контракте (/j) ##%d", contract.id)) then
                        MenuDialogue.report(contract)
                    end
                end
              end

              imgui.End()
            end
        )

        sampRegisterChatCommand(
            'tch.show',
            function() self.toggle() end
        )
        
        lua_thread.create(function()
            while true do
                wait(3000)
                if MenuDialogue.isSearchingAllowed(hideCursor, self.window[0]) then
                    MenuDialogue.search()
                end
            end
        end)

        lua_thread.create(function()
            while true do
                wait(0)
                if MenuDialogue.isUnloadingAllowed() then
                    MenuDialogue.FLAGS.IS_UNLOADING = true
                    MenuDialogue.unload()
                    wait(1000)
                end
            end
        end)

        lua_thread.create(function()
            while true do
                wait(40)
                if isKeyDown(VK_SHIFT) and isKeyDown(VK_C) then
                    while isKeyDown(VK_SHIFT) and isKeyDown(VK_C) do wait(80) end
                    hideCursor = not hideCursor
                end
            end
        end)

        return self
    end
}

return Main