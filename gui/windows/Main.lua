local imgui = require "mimgui"
local encoding = require "encoding"

local constants = require "tch.constants"
local Window = require "tch.gui.windows.window"
local Message = require "tch.entities.chat.message"
local LocalMessage = require "tch.entities.chat.localmessage"
local MenuDialogue = require "tch.samp.dialogues.menu"
local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local RedThemeTransparent = require "tch.gui.themes.redtransparent"
local RedTheme = require "tch.gui.themes.red"
local Config = require "tch.common.config"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()
local SCROLLBAR_SIZE = 11

local chatService = ChatService.new()
local contractsService = ContractService.new()

local Main = {
    new = function()
        local self = Window.new()
        self.hideCursor = true
        local screenX, screenY = getScreenResolution()
        local contractWindowTypeSizes = { { 415, 370 }, { 420, 290 }, { 320, 230 } }
        local position = imgui.ImVec2(config.data.settings.contractsScreenX or screenX - 420, config.data.settings.contractsScreenY or screenY - 410)
        imgui.OnFrame
        (
            function() return self.window[0] end,
            function(player)
                if config.data.settings.selectedScriptStatus == 0 then return end
                ((config.data.settings.transparentContracts and self.hideCursor) and RedThemeTransparent or RedTheme).new()
                self.title = string.format(u8("Список контрактов (%d)"), #contractsService.getContracts())
                local x, y = table.unpack(contractWindowTypeSizes[config.data.settings.contractWindowTypes + 1])
                local size = imgui.ImVec2(x, y)
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(size, imgui.Cond.Always)
                imgui.Begin(self.title, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
                player.HideCursor = self.hideCursor
                if not self.hideCursor and imgui.IsMouseDown(0) then
                    position = imgui.GetWindowPos()
                    config.data.settings.contractsScreenX = position.x
                    config.data.settings.contractsScreenY = position.y
                    config.save()
                 end
                for number, contract in ipairs(contractsService.getContracts()) do
                    if imgui.CollapsingHeader(u8(contract.toString())) and config.data.settings.contractWindowTypes ~= 2 then
                        if imgui.Button(string.format(u8"Взять ##%d", contract.id), imgui.ImVec2(120, 0)) and self.window[0] and contractsService.CanTake() then
                            MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                            MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                            chatService.send(Message.new(constants.COMMANDS.MENU))
                        end
                        imgui.SameLine()
                        if imgui.Button(string.format(u8"Взять и загрузить ##%d", contract.id, imgui.ImVec2(130, 0))) and self.window[0] and contractsService.CanTake() then
                            MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                            MenuDialogue.FLAGS.CONTRACT.IS_MANUAL_LOADING = true
                            MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                            chatService.send(Message.new(constants.COMMANDS.MENU))
                        end
                        imgui.SameLine()
                        local buttonName = contract.IsPinned and u8("Открепить") or u8("Закрепить")
                        local messageName = contract.IsPinned and "откреплен" or "закреплен"
                        local contractId = tonumber(contract.id)
                        if imgui.Button(string.format("%s ##%d", buttonName, contractId), imgui.ImVec2(-1, 0)) then
                            if contract.IsPinned then contractsService.unpin(contractId) end
                            if not contract.IsPinned then contractsService.pin(contract) end
                            chatService.send(LocalMessage.new(string.format(" Контракт успешно {ed5a5a}%s{FFFFFF}. Изменения {ed5a5a}вступят{FFFFFF} в силу после автообновления списка.", messageName)))
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