local constants = require 'tch.constants'
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"

local MainWindow = require "tch.gui.windows.main"
local SettingsWindow = require "tch.gui.windows.settings"
local Red = require "tch.gui.themes.red"
local MenuDialogue = require 'tch.samp.dialogues.menu'
local ContractsDialogue = require 'tch.samp.dialogues.contracts'
local SuggestionDialogue = require 'tch.samp.dialogues.suggestion'
local DocumentsDialogue = require 'tch.samp.dialogues.documents'
local Contract = require 'tch.entities.contracts.contract'
local Message = require "tch.entities.chat.message"
local LocalMessage = require "tch.entities.chat.localmessage"
local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local ScheduleService = require "tch.services.scheduleservice"
local ServerMessageService = require "tch.services.servermessageservice"
local DriverCoordinatesEntryService = require "tch.services.drivercoordinatesentryservice"
local DriverCoordinatesEntry = require "tch.entities.coords.drivercoordinatesentry"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local Config = require "tch.common.config"

local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"

local trucks = { 
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id 
}

script_author(constants.SCRIPT_INFO.AUTHOR)
script_version(constants.SCRIPT_INFO.VERSION)
script_moonloader(constants.SCRIPT_INFO.MOONLOADER)
script_version_number(constants.SCRIPT_INFO.VERSION_NUMBER)
script_url(constants.SCRIPT_INFO.URL)
script_name(constants.SCRIPT_INFO.NAME)

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local menuDialogue = MenuDialogue.new()
local contractsDialogue = ContractsDialogue.new()
local suggestionDialogue = SuggestionDialogue.new()
local documentsDialogue = DocumentsDialogue.new()

local contract = Contract.new()
local mainWindow = MainWindow.new()
local settingsWindow = SettingsWindow.new()

local contractsService = ContractService.new()
local chatService = ChatService.new()
local scheduleService = ScheduleService.new()
local serverMessageService = ServerMessageService.new()
local playerService = PlayerService.new()
local carsService = CarService.new()
local driverCoordinatesService = DriverCoordinatesEntryService.new()

local isSettingsApplied = false

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    Red.new()
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

		sampAddChatMessage(
			"{FFFFFF}Меню настроек - {00CED1}/tch.menu{FFFFFF}, страница скрипта: {00CED1}" .. 
			thisScript().url, 0xFFFFFF
		)

		if config.data.settings.truckRentedChoice == 1 then
			lua_thread.create(function()
				while true do
					wait(10)
					if sampIsLocalPlayerSpawned() then
						mainWindow.activate()
						return
					end
				end
			end)
		end

		sampRegisterChatCommand(
            'tch.show',
			function() mainWindow.toggle() end
        )

		sampRegisterChatCommand(
            "tch.menu",
			function() settingsWindow.toggle() end
        )

		sampRegisterChatCommand(
            "tch.coords.send",
			function(args) 
				if args == nil or args == "" then
					local localMessage = LocalMessage.new("{00CED1}/tch.coords.send{FFFFFF} [текст сообщения]")
					chatService.send(localMessage)
					return
				end

				local player = playerService.getByHandle(
					playerService.get(), 
					PLAYER_PED
				)

				local message = Message.new(
					string.format(
						"/j %s %f|%f|%f", 
						args, 
						player.coords.x, 
						player.coords.y, 
						player.coords.z
					)
				)

				chatService.send(message)
			end
        )

		scheduleService.create
		(
			function()
				local contracts = ContractService.CONTRACTS
				if mainWindow.window[0] 
				and mainWindow.hideCursor 
				and contractsService.CanSearch(contracts) then
					MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
					local message = Message.new(constants.COMMANDS.MENU)
					chatService.send(message)
				end
			end, 
			3000
		):run()

		scheduleService.create
		(
			function()
				if config.data.settings.autounload then
					local contracts = ContractService.CONTRACTS
					if contractsService.CanUnload(contracts) then
						local message = Message.new(constants.COMMANDS.UNLOAD)
						chatService.send(message)
						wait(1000)
					end
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

		scheduleService.create
		(
			function()
				if not isSettingsApplied then
					local cars = carsService.get()
					local players = playerService.get()

					local player = playerService.getByHandle(
						players, 
						PLAYER_PED
					)
				
					local car = carsService.getByDriver(
						cars,
						player
					)

					if car and in_array(car.model, trucks) then
						if config.data.settings.clistChoice > 0 then
							local message = Message.new(
								string.format(
									constants.COMMANDS.CLIST, 
									config.data.settings.clistChoice
								)
							)
							chatService.send(message)
							wait(1000)
						end
						if config.data.settings.autolock then
							local message = Message.new(constants.COMMANDS.LOCK)
							chatService.send(message)
							wait(1000)
						end
						if config.data.settings.truckRentedChoice > 0 then
							mainWindow.activate()
						end
						isSettingsApplied = true
					end
				end
			end,
			10
		):run()

		scheduleService.create
		(
			function()
				if config.data.settings.drift then
					local cars = carsService.get()
					local players = playerService.get()

					local player = playerService.getByHandle(
						players, 
						PLAYER_PED
					)
				
					local car = carsService.getByDriver(
						cars,
						player
					)

					if car then
						setCarCollision(car.handle, true)
						if isKeyDown(vkeys.VK_SHIFT) 
						and isVehicleOnAllWheels(car.handle)
						and doesVehicleExist(car.handle) then
							setCarCollision(car.handle, false)
							if isCarInAirProper(car.handle) then
								setCarCollision(car.handle, true)
								if isKeyDown(vkeys.VK_A) then
									addToCarRotationVelocity(car.handle, 0, 0, 0.1)
								end
								if isKeyDown(vkeys.VK_D) then
									addToCarRotationVelocity(car.handle, 0, 0, -0.1)
								end
							end
						end
					end
				end
			end
		):run()

		scheduleService.create
		(
			function()
				if #DriverCoordinatesEntryService.ENTRIES > 0 then
					local player = playerService.getByHandle(
						playerService.get(), 
						PLAYER_PED
					)
					for _, entry in pairs(DriverCoordinatesEntryService.ENTRIES) do
						local coords = { x = entry.x, y = entry.y, z = entry.z }
						if player.IsWithinDistance(coords, 20) then
							removeBlip(entry.blip)
						end
					end
				end
			end
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

	if config.data.settings.documentsDialogue then
		if documentsDialogue.title == title then
			sampSendDialogResponse(id, 0, _, _)
			return false
		end
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

	if text:find(serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message) then
		local nickname, message, x, y, z = text:match(
			serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message
		)
		local driverCoordinatesEntry = DriverCoordinatesEntry.new(
			nickname,
			message,
			x, y, z
		)
		local data = driverCoordinatesService.findByNickname(
			DriverCoordinatesEntryService.ENTRIES,
			nickname
		)
		if data then
			driverCoordinatesService.update(
				DriverCoordinatesEntryService.ENTRIES, 
				data.id,
				{ 
					nickname = driverCoordinatesEntry.nickname, 
					message = driverCoordinatesEntry.message,
					x = driverCoordinatesEntry.x,
					y = driverCoordinatesEntry.y, 
					z = driverCoordinatesEntry.z
				}
			)
			removeBlip(data.item.blip)
		end

		if not data then
			driverCoordinatesService.create(
				DriverCoordinatesEntryService.ENTRIES, 
				driverCoordinatesEntry
			)
		end
	end
end

function sampev.onSendExitVehicle(vehicleId, isPassenger)
	lua_thread.create(function()
		while isCharInAnyCar(PLAYER_PED) do wait(0) end
		mainWindow.deactivate()
		isSettingsApplied = false
		return
	end)
end

in_array = function(needle, array)
    for _, value in pairs(array) do
        if needle == value then
            return true
        end
    end
    return false
end

function floatify(number)
    return string.format("%0.1f", number)
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end