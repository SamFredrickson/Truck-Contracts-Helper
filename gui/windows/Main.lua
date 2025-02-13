local imgui = require "mimgui"
local encoding = require "encoding"

local constants = require "tch.constants"
local Window = require "tch.gui.windows.window"
local Message = require "tch.entities.chat.message"
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
        local position = imgui.ImVec2
        (
            config.data.settings.contractsScreenX or screenX - 420, 
            config.data.settings.contractsScreenY or screenY - 410
        )
        imgui.OnFrame
        (
            function() return self.window[0] end,
            function(player)
                if config.data.settings.selectedScriptStatus == 0 then return end
                ((config.data.settings.transparentContracts and self.hideCursor) and RedThemeTransparent or RedTheme).new()
                self.title = string.format
                (
                    u8"Список контрактов (%d)", 
                    #ContractService.CONTRACTS
                )
                local x, y = table.unpack(contractWindowTypeSizes[config.data.settings.contractWindowTypes + 1])
                local size = imgui.ImVec2(x, y)
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(size, imgui.Cond.Always)
                imgui.Begin
                (
                    self.title, 
                    self.window, 
                    imgui.WindowFlags.NoResize 
                    + imgui.WindowFlags.NoCollapse
                )
                player.HideCursor = self.hideCursor
                if not self.hideCursor and imgui.IsMouseDown(0) then
                    position = imgui.GetWindowPos()
                    config.data.settings.contractsScreenX = position.x
                    config.data.settings.contractsScreenY = position.y
                    config.save()
                 end
                for number, contract in ipairs(ContractService.CONTRACTS) do
                    if imgui.CollapsingHeader(u8(contract.toString())) then
                        if imgui.Button(string.format(u8"Взять контракт ##%d", contract.id)) and self.window[0] and contractsService.CanTake(ContractService.CONTRACTS) then
                            MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                            MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                            chatService.send(Message.new(constants.COMMANDS.MENU))
                        end
                        imgui.SameLine()
                        if imgui.Button(string.format(u8"Взять контракт и загрузить ##%d", contract.id)) and self.window[0] and contractsService.CanTake(ContractService.CONTRACTS) then
                            MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                            MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
                            MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                            chatService.send(Message.new(constants.COMMANDS.MENU))
                        end
                        imgui.SameLine()
                        if imgui.Button(string.format(u8"Загрузить ##%d", contract.id)) then
                            chatService.send(Message.new(constants.COMMANDS.LOAD))
                        end
                        imgui.SameLine()
                        local cancelButtonSize = #ContractService.CONTRACTS <= SCROLLBAR_SIZE and imgui.ImVec2(41, 0) or nil
                        if imgui.Button(string.format(u8"Отм ##%d", contract.id), cancelButtonSize) then
                            MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = true
                            chatService.send(Message.new(constants.COMMANDS.MENU))
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