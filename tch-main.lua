local constants = require 'tch.constants'
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"

local MainWindow = require 'tch.gui.windows.main'
local DemoWindow = require 'tch.gui.windows.demo'
local Red = require 'tch.gui.themes.red'
local MenuDialogue = require 'tch.samp.dialogues.menu'
local ContractsDialogue = require 'tch.samp.dialogues.contracts'
local SuggestionDialogue = require 'tch.samp.dialogues.suggestion'
local DocumentsDialogue = require 'tch.samp.dialogues.documents'
local Contract = require 'tch.entities.contracts.contract'

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
local demoWindow = DemoWindow.new()


imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    Red.new()
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

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
		mainWindow.contracts = Contract.makeListFromText(text)
		return false
	end

	if menuDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
		sampSendDialogResponse(id, 1, 0, _)
		return false
	end

	if contractsDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
		MenuDialogue.FLAGS.CONTRACT.IS_TAKING = false
		sampSendDialogResponse(id, 1, MenuDialogue.FLAGS.CONTRACT.ID - 1, _)
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
	if MenuDialogue.FLAGS.IS_UNLOADING and text:find("Вы успешно доставили груз") then
		MenuDialogue.FLAGS.IS_UNLOADING = false
		return true
	end
end