local imgui = require 'mimgui'
local encoding = require "encoding"

local constants = require 'tch.constants'
local Window = require 'tch.gui.windows.window'
local Message = require "tch.entities.chat.message"
local MenuDialogue = require 'tch.samp.dialogues.menu'
local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local chatService = ChatService.new()
local contractsService = ContractService.new()

local Main = {
    new = function()
        local self = Window.new()
        self.hideCursor = true

        local sizes = imgui.ImVec2(410, 370)
        local posX, posY = getScreenResolution()

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
              local windowTitle = string.format(u8"Список контрактов (%d)", #ContractService.CONTRACTS)
              imgui.SetNextWindowPos(imgui.ImVec2(posX - 225, posY - 200), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
              imgui.SetNextWindowSize(sizes, imgui.Cond.FirstUseEver)
              imgui.Begin(windowTitle, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
              player.HideCursor = self.hideCursor

              for number, contract in ipairs(ContractService.CONTRACTS) do
                if imgui.CollapsingHeader(u8(contract.toString())) then
                    if imgui.Button(string.format(u8"Взять контракт ##%d", contract.id)) and self.window[0] and contractsService.CanTake(ContractService.CONTRACTS) then
                        MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                        MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                        
                        chatService.send(Message.new(
                            constants.COMMANDS.MENU
                        ))
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Взять контракт и загрузить ##%d", contract.id)) and self.window[0] and contractsService.CanTake(ContractService.CONTRACTS) then
                        MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
                        MenuDialogue.FLAGS.CONTRACT.ID = contract.id
                        
                        chatService.send(Message.new(
                            constants.COMMANDS.MENU
                        ))

                        chatService.send(Message.new(
                            constants.COMMANDS.LOAD,
                            1000
                        ))
                     end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Загрузить ##%d", contract.id)) then
                        chatService.send(Message.new(
                            constants.COMMANDS.LOAD
                        ))
                    end
                    imgui.SameLine()
                    if imgui.Button(string.format(u8"Отм ##%d", contract.id)) then
                        MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = true

                        chatService.send(Message.new(
                            constants.COMMANDS.MENU
                        ))
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