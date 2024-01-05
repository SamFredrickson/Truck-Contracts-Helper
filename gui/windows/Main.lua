local moonloader = require "moonloader"
local imgui = require 'mimgui'
local encoding = require "encoding"

local constants = require 'tch.constants'
local Window = require 'tch.gui.windows.window'
local Utils = require 'tch.common.utils'
local Command = require 'tch.samp.commands.command'
local MenuDialogue = require 'tch.samp.dialogues.menu'
local Linerunner = require 'tch.entities.vehicles.linerunner'
local Tanker = require 'tch.entities.vehicles.tanker'
local RoadTrain = require 'tch.entities.vehicles.roadtrain'

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
        local trucks = {
            Linerunner.new().id, 
            Tanker.new().id, 
            RoadTrain.new().id
        }

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
                    if imgui.Button(string.format("GPS ##%d", contract.id)) then
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Взять ##%d", contract.id)) then
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Отменить ##%d", contract.id)) then
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Сообщить (/j) ##%d", contract.id)) then
                    end
                end
              end

              imgui.End()
            end
        )

        function isParsingAllowed()
            if isCharInAnyCar(PLAYER_PED) then
                local modelId = Utils.getPlayerCarModelId()
                return hideCursor 
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not sampTextdrawIsExists(constants.TEXTDRAWS.CONTRACTS.PRICE) -- ебаный костыль на проверку запущенного контракта
                and Utils.in_array(modelId, trucks)
                and self.window[0]
            end
            return false
        end

        function search()
            if isParsingAllowed() then
                MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
                sampSendChat('/tmenu')
            end
        end

        sampRegisterChatCommand(
            'tch.show',
            function() self.toggle() end
        )
        
        lua_thread.create(function()
            while true do wait(2000) search() end
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