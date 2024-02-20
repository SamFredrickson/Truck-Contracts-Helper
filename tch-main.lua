local constants = require 'tch.constants'
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"

local MainWindow = require 'tch.gui.windows.main'
local Red = require 'tch.gui.themes.red'
local MenuDialogue = require 'tch.samp.dialogues.menu'
local ContractsDialogue = require 'tch.samp.dialogues.contracts'
local SuggestionDialogue = require 'tch.samp.dialogues.suggestion'
local DocumentsDialogue = require 'tch.samp.dialogues.documents'
local Contract = require 'tch.entities.contracts.contract'
local Message = require "tch.entities.chat.message"
local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local ScheduleService = require "tch.services.scheduleservice"
local ServerMessageService = require "tch.services.servermessageservice"

script_author(constants.SCRIPT_INFO.AUTHOR)
script_version(constants.SCRIPT_INFO.VERSION)
script_moonloader(constants.SCRIPT_INFO.MOONLOADER)
script_version_number(constants.SCRIPT_INFO.VERSION_NUMBER)
script_url(constants.SCRIPT_INFO.URL)
script_name(constants.SCRIPT_INFO.NAME)

encoding.default = "CP1251"
local u8 = encoding.UTF8

local menuDialogue = MenuDialogue.new()
local contractsDialogue = ContractsDialogue.new()
local suggestionDialogue = SuggestionDialogue.new()
local documentsDialogue = DocumentsDialogue.new()
local contract = Contract.new()
local mainWindow = MainWindow.new()
local contractsService = ContractService.new()
local chatService = ChatService.new()
local scheduleService = ScheduleService.new()
local serverMessageService = ServerMessageService.new()

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    Red.new()
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

		sampAddChatMessage(
			"{FFFFFF}Список контрактов - {00CED1}/tch.show{FFFFFF}, страница скрипта: {00CED1}" .. 
			thisScript().url, 0xFFFFFF
		)

		sampRegisterChatCommand(
            'tch.show',
			function() mainWindow.toggle() end
        )

		scheduleService.create
		(
			function()
				local contracts = ContractService.CONTRACTS
				if mainWindow.window[0] 
				and mainWindow.hideCursor 
				and contractsService.CanSearch(contracts) then
					MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
					chatService.send(Message.new(
						constants.COMMANDS.MENU
					))
				end
			end, 
			3000
		):run()

		scheduleService.create
		(
			function()
				local contracts = ContractService.CONTRACTS
				if contractsService.CanUnload(contracts) then
					chatService.send(Message.new(
						constants.COMMANDS.UNLOAD
					))
					wait(1000)
				end
			end
		):run()

		scheduleService.create
		(
			function()
				if isKeyDown(vkeys.VK_SHIFT) and isKeyDown(vkeys.VK_C) then
                    while isKeyDown(vkeys.VK_SHIFT) and isKeyDown(vkeys.VK_C) do wait(80) end
					mainWindow.hideCursor = not mainWindow.hideCursor
                end
			end,
			40
		):run()

		while true do
			wait(-1)
		end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	-- проверяем, что текущий диалог является главным меню и был открыт по специальной команде
	if menuDialogue.title == title and MenuDialogue.FLAGS.IS_PARSING_CONTRACTS then
		-- проверяем надо ли закрывать главное меню в случае возвращения назад из списка контрактов
		if MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP then
			-- обнуляем флаги, чтобы повторный вызов функции не зациклил открытие меню
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP = false
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = false
			sampSendDialogResponse(id, 0, _, _)
			return false
		end
		-- проверяем надо ли открывать список контрактов в случае первоначального открытия главного меню
		if not MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP then
			sampSendDialogResponse(id, 1, 0, _)
			return false
		end
	end
	-- проверяем, что текущий диалог является списком контрактов и был открыт по специальной команде
	if contractsDialogue.title == title and MenuDialogue.FLAGS.IS_PARSING_CONTRACTS then
		MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP = true -- устанавливаем данный флаг в "true", чтобы не вызвать циклическое открытие
		sampSendDialogResponse(id, 0, _, _)
		ContractService.CONTRACTS = contractsService.make(text)
		return false
	end

	if menuDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
		sampSendDialogResponse(id, 1, 0, _)
		return false
	end

	if contractsDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
		MenuDialogue.FLAGS.CONTRACT.IS_TAKING = false
		local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)

		local contract = contractsService.update(
			contractId,
			{ IsActive = true },
			ContractService.CONTRACTS
		)

		sampSendDialogResponse(id, 1, contractId - 1, _)
		return false
	end

	if menuDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_CANCELING then
		MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = false
		local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)

		local contract = contractsService.update(
			contractId,
			{ IsActive = false },
			ContractService.CONTRACTS
		)
		
		sampSendDialogResponse(id, 1, 1, _)
		return false
	end

	-- Скрывать диалоги, которые появляеются при загрузке или выгрузке
	if documentsDialogue.title == title then
		sampSendDialogResponse(id, 0, _, _)
		return false
	end

	if suggestionDialogue.title == title then
		sampSendDialogResponse(id, 0, _, _)
		return false
	end
end

function sampev.onServerMessage(color, text)
	if text:find(serverMessageService.findByCode("contract-canceled").message) then
		local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
		local contract = contractsService.update(
			contractId,
			{ IsActive = false },
			ContractService.CONTRACTS
		)
	end
	if text:find(serverMessageService.findByCode("delivery-success").message) then
		local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
		local contract = contractsService.update(
			contractId,
			{ IsActive = false },
			ContractService.CONTRACTS
		)
	end
end

in_array = function(needle, array)
    for _, value in pairs(array) do
        if needle == value then
            return true
        end
    end
    return false
end