local constants = require "tch.constants"
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"
require "tch.gui.imguiutils"
require "tch.common.lua-string"

local MainWindow = require "tch.gui.windows.main"
local SettingsWindow = require "tch.gui.windows.settings"
local InfoWindow = require "tch.gui.windows.info"
local Red = require "tch.gui.themes.red"

local MenuDialogue = require "tch.samp.dialogues.menu"
local ContractsDialogue = require "tch.samp.dialogues.contracts"
local SuggestionDialogue = require "tch.samp.dialogues.suggestion"
local DocumentsDialogue = require "tch.samp.dialogues.documents"
local IllegalCargoDialogue = require "tch.samp.dialogues.illegalcargo"
local SkillDialogue = require "tch.samp.dialogues.skill"

local Sound = require "tch.entities.sounds.sound"
local Contract = require "tch.entities.contracts.contract"
local Message = require "tch.entities.chat.message"
local LocalMessage = require "tch.entities.chat.localmessage"
local DriverCoordinatesEntry = require "tch.entities.coords.drivercoordinatesentry"
local Race = require "tch.entities.race"
local Time = require "tch.entities.time"
local Number = require "tch.entities.number"

local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local ScheduleService = require "tch.services.scheduleservice"
local ServerMessageService = require "tch.services.servermessageservice"
local DriverCoordinatesEntryService = require "tch.services.drivercoordinatesentryservice"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local HttpService = require "tch.services.httpservice"
local PointsService = require "tch.services.pointsservice"
local Config = require "tch.common.config"
local Hotkeys = require "tch.common.storage.hotkeys"
local ProfitAndLoss = require "tch.common.storage.profitandloss"
local Array = require "tch.common.array"
local AudioStreamState = require("moonloader").audiostream_state
local Color = require "tch.common.color"
local argb2abgr = Color.argbToAbgr
local renderDrawLineBy3dCoords = Color.renderWorldLine
local registerCommands = require "tch.commands"

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
local illegalCargoDialogue = IllegalCargoDialogue.new()
local skillDialogue = SkillDialogue.new()

local contract = Contract.new()
local mainWindow = MainWindow.new()
local settingsWindow = SettingsWindow.new()
local infoWindow = InfoWindow.new()
local markSound = Sound.new("mark.wav", 0.8)
local tickSound = Sound.new("tick.wav", 5)

local contractsService = ContractService.new()
local chatService = ChatService.new()
local scheduleService = ScheduleService.new()
local serverMessageService = ServerMessageService.new()
local playerService = PlayerService.new()
local carsService = CarService.new()
local driverCoordinatesService = DriverCoordinatesEntryService.new()
local httpService = HttpService.new()
local pointService = PointsService.new()

local TWO_HOURS = 3600 * 2
local MAX_UNLOAD_ATTEMPTS = 3
local race = nil
local connectionGeneration = 0
local isSettingsApplied = false
local isSuccessfulRenting = false
local illegalCargoDialogueShowedAt = nil
local lastCargoTakenAt = nil
local autounloading = { notified = false }

local currentBlip = {
	blip = nil, 
	coords = nil,
	activeCoords = nil
}

local function clearCurrentBlip()
	if currentBlip.blip then removeBlip(currentBlip.blip) end
	currentBlip.blip = nil
	currentBlip.activeCoords = nil
end

local unloading = {
	active = false, 
	time = nil,
	notified = false,
	tries = 0
}

local function sendContractCommandAfterDelay(command, delay)
	local generation = connectionGeneration
	lua_thread.create(function()
		wait(delay)
		if generation == connectionGeneration then
			chatService.send(Message.new(command))
		end
	end)
end

local function resetContractSession()
	connectionGeneration = connectionGeneration + 1
	race = nil
	lastCargoTakenAt = nil
	isSuccessfulRenting = false
	illegalCargoDialogueShowedAt = nil
	illegalCargoDialogue.isActive = false
	contractsService.setContracts({})
	contractsService.hasUnknownActiveContract = false
	unloading.tries = 0
	unloading.time = nil
	unloading.notified = false
	autounloading.notified = false

	local flags = MenuDialogue.FLAGS
	flags.IS_PARSING_CONTRACTS = false
	flags.IS_PARSING_CONTRACTS_LAST_STEP = false
	flags.CONTRACT.ID = 0
	flags.CONTRACT.IS_TAKING = false
	flags.CONTRACT.IS_LOADING = false
	flags.CONTRACT.IS_CANCELING = false
	flags.CONTRACT.IS_WRONG_LOADING_POINT = false
	flags.CONTRACT.IS_MANUAL_LOADING = false

	infoWindow.information.race.setValue("—")
	infoWindow.information.raceTime.setValue(Time.new(0).toString())
end

local function applyEarningsChange(amount, categoryName)
	amount = tonumber(amount)
	if not amount then return false end

	local profitAndLoss
	local category
	if categoryName then
		profitAndLoss = ProfitAndLoss.new()
		local match = profitAndLoss.getByName(categoryName)
		if match then category = match[2] end
	end

	if category then
		category.sum = category.sum + amount
		local saved, err = profitAndLoss.save()
		if not saved then
			print("[TCH] " .. tostring(err))
			return false
		end
	end

	config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + amount
	config.data.settings.totalEarnings = config.data.settings.totalEarnings + amount

	infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
	config.save()
	return true
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	bigFontSize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 28.0, _, glyph_ranges)
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

		sampAddChatMessage(" {FFFFFF}Меню настроек - {ed5a5a}/tch.menu{FFFFFF}, страница скрипта: {ed5a5a}" .. thisScript().url, 0xFFFFFF)
		httpService.getAvailableUpdates()

		local car = carsService.getDrivenTruck()
		local isAttached = car and carsService.hasAttachedTrailer(car)
		if isAttached then contractsService.hasUnknownActiveContract = true end

		registerCommands({config=config, infoWindow=infoWindow, mainWindow=mainWindow, settingsWindow=settingsWindow, imgui=imgui, chatService=chatService, LocalMessage=LocalMessage, contractsService=contractsService, httpService=httpService, constants=constants, playerService=playerService, Message=Message})

		-- Автообновление списка контрактов
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					if mainWindow.window[0] 
					and mainWindow.hideCursor 
					and contractsService.CanSearch() 
					and not MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT then
						MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
						local message = Message.new(constants.COMMANDS.MENU)
						chatService.send(message)
					end
				end
			end, 
			3000
		):run()

		-- Авторазгрузка
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus <= 0 or not config.data.settings.autounload then return end
				if not (race and not race.finishedAt) and not contractsService.hasUnknownActiveContract then return end

				local now = os.time()
				if lastCargoTakenAt and now - lastCargoTakenAt <= 30 then return end
				if unloading.time and now < unloading.time then return end
				if unloading.notified or not contractsService.CanUnload() then return end

				unloading.time = nil
				if unloading.tries >= MAX_UNLOAD_ATTEMPTS then
					unloading.notified = true
					local text = " Контракт больше неактуален или Вы взяли не свой груз"
					chatService.send(LocalMessage.new(text, 0, constants.COLORS.DARK_GRAY))
					return
				end

				unloading.tries = unloading.tries + 1
				chatService.send(Message.new(constants.COMMANDS.UNLOAD))
				wait(1000)
			end,
			200
		):run()

		-- Прослушка комбинации клавиш для показывания курсора мыши
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local hotkey = Hotkeys.getActive("cursor")
					if hotkey.first and hotkey.second then
						if isKeyDown(hotkey.first) and isKeyDown(hotkey.second) then
							while isKeyDown(hotkey.first) and isKeyDown(hotkey.second) do wait(80) end
							mainWindow.hideCursor = not mainWindow.hideCursor
						end
					end
					if hotkey.first and not hotkey.second then
						if isKeyDown(hotkey.first) then
							while isKeyDown(hotkey.first) do wait(80) end
							mainWindow.hideCursor = not mainWindow.hideCursor
						end
					end
				end
			end,
			40
		):run()

		-- Прослушка комбинации клавиш для принятия координат с рации
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and currentBlip.coords and currentBlip.coords ~= currentBlip.activeCoords then
					if isKeyDown(18) and isKeyDown(89) then
						while isKeyDown(18) and isKeyDown(89) do wait(80) end
						clearCurrentBlip()
						currentBlip.blip = addSpriteBlipForCoord(currentBlip.coords.x, currentBlip.coords.y, currentBlip.coords.z, 41)
						currentBlip.activeCoords = currentBlip.coords
						local messages = {
							LocalMessage.new(" Метка успешно {ed5a5a}поставлена{FFFFFF} на карте."),
							LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами{ed5a5a} ALT + N {FFFFFF}чтобы убрать метку.")
						}
						for _, message in pairs(messages) do chatService.send(message) end
						setAudioStreamState(markSound.audioStream, AudioStreamState.PLAY)
					end
				end
				if config.data.settings.selectedScriptStatus > 0 and currentBlip.blip then
					if isKeyDown(18) and isKeyDown(78) then
						while isKeyDown(18) and isKeyDown(78) do wait(80) end
						clearCurrentBlip()
					end
				end
			end,
			40
		):run()

		-- Прослушка на возможность дать цвет ника, закрыть машину, показать окно
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and not isSettingsApplied then
					local car = carsService.getDrivenTruck()

					if car then
						local isLocked = getCarDoorLockStatus(car) > 0
						-- Меняем цвет ника
						if config.data.settings.clistChoice > 0 then
							local message = Message.new(string.format(constants.COMMANDS.CLIST, config.data.settings.clistChoice))
							chatService.send(message)
							wait(2000)
						end
						-- Закрываем машину
						if config.data.settings.autolock and not isLocked then
							local message = Message.new(constants.COMMANDS.LOCK)
							chatService.send(message)
							wait(2000)
						end
						-- Обновляем опыт
						SkillDialogue.IS_PARSING = true
						local message = Message.new(constants.COMMANDS.SKILL)
						chatService.send(message)
						wait(2000)
						-- Активируем окно с контрактами
						if config.data.settings.truckRentedChoice > 0 then
							mainWindow.hideCursor = true
							mainWindow.activate()
						end
						-- Активируем окно со статистикой
						if config.data.settings.statistics then infoWindow.activate() end
						isSettingsApplied = true
					end
				end
			end,
			10
		):run()

		-- Прослушка на дрифт
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and config.data.settings.drift then
					local hotkey = Hotkeys.getActive("drift")
					if isCharInAnyCar(PLAYER_PED) then
						local car = storeCarCharIsInNoSave(PLAYER_PED)
						local speed = getCarSpeed(car)
						setCarCollision(car, true)
						if isKeyDown(hotkey.first) 
						and isVehicleOnAllWheels(car)
						and doesVehicleExist(car)
						and speed > 0.5 then
							setCarCollision(car, false)
							if isCarInAirProper(car) then
								setCarCollision(car, true)
								if isKeyDown(vkeys.VK_A) then
									addToCarRotationVelocity(car, 0, 0, 0.1)
								end
								if isKeyDown(vkeys.VK_D) then
									addToCarRotationVelocity(car, 0, 0, -0.1)
								end
							end
						end
					end
				end
			end
		):run()

		-- Прослушка на удаление маркера при дистанции 20 метров
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and currentBlip.activeCoords then
					local player = playerService.getLocalPlayer()
					if player and player.IsWithinDistance(currentBlip.activeCoords, 20) then clearCurrentBlip() end
				end
			end
		):run()

		-- Прослушка на нахождение рядом со складами
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 
				and config.data.settings.autoload
				and isCharInAnyCar(PLAYER_PED)
				and mainWindow.hideCursor
				and not contractsService.hasUnknownActiveContract
				and not MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT then
					if not race or race.finishedAt then
						local contract = contractsService.findAvailableToTake()
						if not contract then return false end
						MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
						MenuDialogue.FLAGS.CONTRACT.ID = contract.id
						chatService.send(Message.new(constants.COMMANDS.MENU))
						wait(2000)
					end
					if race and not race.finishedAt then
						local contract = contractsService.findActive()
						if not contract then return false end
						local player = playerService.getLocalPlayer()
						local sourcePoint = contract.getSourcePoint()
						if not player or not sourcePoint then return end
						local isSourcePointAvailable = pointService.validateSourcePointAvailability(sourcePoint)
						local isAutoLoadDistance = player.IsWithinDistance(sourcePoint.coords, sourcePoint.autoLoadDistance)
						if isSourcePointAvailable and isAutoLoadDistance and not MenuDialogue.FLAGS.CONTRACT.IS_LOADING then
							MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
			 				chatService.send(LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите..."))
			 				chatService.send(Message.new(constants.COMMANDS.LOAD))
			 				wait(2000)
						end
						if (not lastCargoTakenAt or os.difftime(os.time(), lastCargoTakenAt) > 30) and (not isSourcePointAvailable and not autounloading.notified) then
							local hotkey = Hotkeys.getActive("take-and-load")
			 				local messages = {LocalMessage.new(" {FFFFFF}У точки загрузки находятся другие {ed5a5a}дальнобойщики."), LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами {ed5a5a}" .. hotkey.buttonText .. "{FFFFFF} или подождите пока точка будет свободна.")}
			 				for _, message in pairs(messages) do chatService.send(message) end
			 				autounloading.notified = true
							wait(1000)
						end
					end
				end
			end,
			1000
		):run()

		-- Смена таймингов
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					if infoWindow.window[0] then
						-- Обновление таймингов нелегального груза
						local illegalCargoAvailableAt = config.data.settings.lastIllegalCargoUnloadedAt + TWO_HOURS
						local illegalCargoDiffTime = os.difftime(illegalCargoAvailableAt, os.time())
						local illegalCargoAvailableAtFormatted = Time.new(illegalCargoDiffTime).toString()
						infoWindow.information.cargo.setValue(illegalCargoAvailableAtFormatted)
						
						-- Обновление таймингов рейса
						if race then
							local raceDiffTime = os.difftime(race.finishedAt or os.time(), race.startedAt)
							infoWindow.information.raceTime.setValue(Time.new(raceDiffTime).toString())
						end
					end
				end
			end
		):run()

		-- Отрисовка линий камер
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and config.data.settings.cameraLines then
					for _, line in pairs(constants.CAMERA_LINES.VALUES) do
						local startX, startY, startZ, finishX, finishY, finishZ = table.unpack(line)
						renderDrawLineBy3dCoords
						(
							startX, 
							startY, 
							startZ, 
							finishX, 
							finishY, 
							finishZ, 
							config.data.settings.linesWidth, 
							argb2abgr(config.data.settings.linesColor), 
							-0.5
						)
					end
				end
			end
		):run()

		-- Отключение коллизии для трупов
		scheduleService.create
		(
			function()
				local players = playerService.getNpc()
				local isScriptEnabled = config.data.settings.selectedScriptStatus > 0
				local isTransparentCorpses = not config.data.settings.transparentCorpses
				for _, player in pairs(players) do
					if not isScriptEnabled then setCharCollision(player, true) end
					if isScriptEnabled then setCharCollision(player, isTransparentCorpses) end
				end
			end
		):run()

		-- Прослушка комбинации клавиш для ручной автозагрузки
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local hotkey = Hotkeys.getActive("take-and-load")
					if hotkey.first and hotkey.second then
						if isKeyDown(hotkey.first) and isKeyDown(hotkey.second) then
							while isKeyDown(hotkey.first) and isKeyDown(hotkey.second) do wait(80) end
							if (not lastCargoTakenAt or os.difftime(os.time(), lastCargoTakenAt) > 30) and mainWindow.hideCursor then
								local contract = contractsService.findActive()
								if contract then
									MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
									chatService.send(LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите..."))
									chatService.send(Message.new(constants.COMMANDS.LOAD))
									wait(2000)
								end
							end
						end
					end
					if hotkey.first and not hotkey.second then
						if isKeyDown(hotkey.first) then
							while isKeyDown(hotkey.first) do wait(80) end
							if (not lastCargoTakenAt or os.difftime(os.time(), lastCargoTakenAt) > 30) and mainWindow.hideCursor then
								local contract = contractsService.findActive()
								if contract then
									MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
									chatService.send(LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите..."))
									chatService.send(Message.new(constants.COMMANDS.LOAD))
									wait(2000)
								end
							end
						end
					end
				end
			end,
			40
		):run()

		-- Прослушка комбинации на отмену текущего контракта
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local hotkey = Hotkeys.getActive("cancel-contract")
					if hotkey.first and hotkey.second then
						if isKeyDown(hotkey.first) and isKeyDown(hotkey.second) then
							while isKeyDown(hotkey.first) and isKeyDown(hotkey.second) do wait(80) end
							MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = true
                            chatService.send(Message.new(constants.COMMANDS.MENU))
						end
					end
					if hotkey.first and not hotkey.second then
						if isKeyDown(hotkey.first) then
							while isKeyDown(hotkey.first) do wait(80) end
							MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = true
                            chatService.send(Message.new(constants.COMMANDS.MENU))
						end
					end
				end
			end,
			40
		):run()

		while true do
			wait(-1)
		end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if config.data.settings.selectedScriptStatus > 0 then
		-- проверяем, что текущий диалог является главным меню и был открыт по специальной команде
		if menuDialogue.title == title and MenuDialogue.FLAGS.IS_PARSING_CONTRACTS then
			-- проверяем надо ли закрывать главное меню в случае возвращения назад из списка контрактов
			if MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP then
				-- обнуляем флаги, чтобы повторный вызов функции не зациклил открытие меню
				MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT = false
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
			contractsService.setContracts(contractsService.parse(text))
			return false
		end

		if menuDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
			sampSendDialogResponse(id, 1, 0, _)
			return false
		end

		if contractsDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then
			MenuDialogue.FLAGS.CONTRACT.IS_TAKING = false
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update(contractId, { IsActive = true })
			race = Race.new(contract, os.time())
			infoWindow.information.race.setValue(trim(race.getContract()))
			sampSendDialogResponse(id, 1, contractId - 1, _)
			return false
		end

		if menuDialogue.title == title and MenuDialogue.FLAGS.CONTRACT.IS_CANCELING then
			MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = false
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update(contractId, { IsActive = false })
			sampSendDialogResponse(id, 1, 1, _)

			if MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT then
				MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = true
				sendContractCommandAfterDelay(constants.COMMANDS.MENU, 3000)
			end

			return false
		end

		if title:find(skillDialogue.title) and SkillDialogue.IS_PARSING then
			SkillDialogue.IS_PARSING = false
			local level = tonumber(text:match("Уровень:	{.-}(%d+) ур."))
			local current, goal = text:match("Опыт:	{.-}(%d+) из (%d+)")
			local value = goal - current
			local valueFormatted = Number.new(value < 0 and 0 or value).format(0, "", "{F2545B}")
			local titleText = level == constants.MAX_TRUCK_DRIVER_LEVEL and constants.MAX_TRUCK_DRIVER_LEVEL or level + 1
			local title = string.format("Опыта до %s уровня:", titleText)
			infoWindow.information.experienceToLevel.setValue(valueFormatted)
			infoWindow.information.experienceToLevel.setTitle(title)
			sampSendDialogResponse(id, 0, _, _)
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

		if title:find(illegalCargoDialogue.title) then
			illegalCargoDialogueShowedAt = os.time()
			illegalCargoDialogue.isActive = true
		end

		if illegalCargoDialogueShowedAt and not title:find(illegalCargoDialogue.title)
		and os.difftime(os.time(), illegalCargoDialogueShowedAt) > 10 then
			illegalCargoAvailableAt = nil
			illegalCargoDialogue.isActive = false
		end
	end
end

local function handleFinancialServerMessage(text)
-- Учитываем расход с бустов в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("tbooster").message)) then
			local tboosterExpense = text:match(serverMessageService.findByCode("tbooster").message)
			applyEarningsChange(-tboosterExpense, "Бусты")
		end

		-- Учитываем полученный штраф в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("fine").message)) then
			local fine = text:match(serverMessageService.findByCode("fine").message)
			applyEarningsChange(-fine, "Штрафы с камер")
		end

		-- Учитываем полученный доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("income").message)) then
			local commission, income = text:match(serverMessageService.findByCode("income").message)
			applyEarningsChange(income, race and race.contract.source or "Неизвестный источник")
		end

		-- Учитываем полученный семейный доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("family-income").message)) then
			local familyIncome = text:match(serverMessageService.findByCode("family-income").message)
			applyEarningsChange(familyIncome, "Семейный бонус")
		end

		-- Учитываем полученный квест-доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("quest-income").message)) then
			local questIncome = text:match(serverMessageService.findByCode("quest-income").message)
			applyEarningsChange(questIncome, "Семейный бонус")
		end

		-- Учитываем полученный расход с заправки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("refilled-at-gas-station").message)) then
			local expense = text:match(serverMessageService.findByCode("refilled-at-gas-station").message)
			if carsService.getDrivenTruck() then
				applyEarningsChange(-expense, "Заправка на станции")
			end
		end

		-- Учитываем полученный расход с починки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("repair-accepted").message)) then
			local expense = text:match(serverMessageService.findByCode("repair-accepted").message)
			if carsService.getDrivenTruck() then
				applyEarningsChange(-expense, "Починка механиком")
			end
		end

		-- Учитываем полученный расход с покупки рем. комплекта в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("repair-kit-acquired").message)) then
			local expense = text:match(serverMessageService.findByCode("repair-kit-acquired").message)
			if carsService.getDrivenTruck() then
				applyEarningsChange(-expense, "Рем. комплекты")
			end
		end

		-- Учитываем полученный расход с покупки канистры в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("gasoline-canister-acquired").message)) then
			local expense = text:match(serverMessageService.findByCode("gasoline-canister-acquired").message)
			if carsService.getDrivenTruck() then
				applyEarningsChange(-expense, "Канистры")
			end
		end

		-- Учитываем полученный расход с заправки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("refill-accepted").message)) then
			local expense = text:match(serverMessageService.findByCode("refill-accepted").message)
			if carsService.getDrivenTruck() then
				applyEarningsChange(-expense, "Заправка механиком")
			end
		end

		end

function sampev.onServerMessage(color, text)
	if config.data.settings.selectedScriptStatus > 0 then
		if text:find(serverMessageService.findByCode("contract-canceled").message) then
			lastCargoTakenAt = nil
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			contractsService.hasUnknownActiveContract = false
			unloading.tries = 0
			unloading.time = nil
			unloading.notified = false
			autounloading.notified = false
			
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update(contractId, { IsActive = false })

			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.activate()
			end

			-- Обнуляем текущий рейс
			race = nil
			infoWindow.information.race.setValue("—")
			infoWindow.information.raceTime.setValue(Time.new(0).toString())
		end

		-- Логика при появлении собщения в чате, что игрок имеет активный контракт
		if text:find(serverMessageService.findByCode("has-active-contract").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT = false
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = false
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP = false
			local contract = contractsService.findActive()
			
			if not contract then
				contractsService.setContracts({})
				contractsService.hasUnknownActiveContract = true
			end 

			local message = LocalMessage.new(" {FFFFFF}У вас уже есть {ed5a5a}активный {FFFFFF}контракт. Откройте главное меню {ed5a5a}(( /tmenu )){FFFFFF}, если нужно отменить его")
			chatService.send(message)
			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end
			
			return false
		end

		-- Логика при успешной доставки обычного груза
		if text:find(serverMessageService.findByCode("delivery-success").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT = false
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			contractsService.hasUnknownActiveContract = false
			unloading.tries = 0
			unloading.time = nil
			unloading.notified = false
			autounloading.notified = false
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update(contractId, { IsActive = false })

			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.activate()
			end

			config.data.settings.sessionRaceQuantity = config.data.settings.sessionRaceQuantity + 1
			infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)
			if race then race.finishedAt = os.time() end
			config.save()
		end

		-- Логика при выборе контракта из списка
		if text:find(serverMessageService.findByCode("delivery-start").message) then
			local hotkey = Hotkeys.getActive("cancel-contract")
			local message = LocalMessage.new(" {FFFFFF}Если нужно {ed5a5a}отменить{FFFFFF} контракт - воспользуйтесь горячими клавишами {ed5a5a}" .. hotkey.buttonText, 1000)
			chatService.send(message)

			local contract = contractsService.findAvailableToTake()
			if contract and MenuDialogue.FLAGS.CONTRACT.IS_MANUAL_LOADING then
				MenuDialogue.FLAGS.CONTRACT.IS_MANUAL_LOADING = false
				chatService.send(LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите..."))
				sendContractCommandAfterDelay(constants.COMMANDS.LOAD, 1000)
			end
			
			if not contract and MenuDialogue.FLAGS.CONTRACT.IS_MANUAL_LOADING then
				MenuDialogue.FLAGS.CONTRACT.IS_MANUAL_LOADING = false
				chatService.send(LocalMessage.new(" Вы слишком далеко от точки загрузки.", 1000, constants.COLORS.DARK_GRAY))
			end
		end

		-- Логика при успешной доставке нелегального груза
		if text:find(serverMessageService.findByCode("illegal-delivery-success").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			contractsService.hasUnknownActiveContract = false
			unloading.tries = 0
			unloading.time = nil
			unloading.notified = false
			autounloading.notified = false

			-- Обновляем количество рейсов за сессию
			config.data.settings.sessionRaceQuantity = config.data.settings.sessionRaceQuantity + 1
			infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)
			config.save()

			if race then race.finishedAt = os.time() end
			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.activate()
			end
		end

		-- Логика при получении опыта за груз
		if text:find(serverMessageService.findByCode("contract-experience").message) then
			-- Обновляем количество полученного опыта за сессию
			local experience = text:match(serverMessageService.findByCode("contract-experience").message)
			config.data.settings.sessionExperience = config.data.settings.sessionExperience + experience
			infoWindow.information.sessionExperience.setValue(Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}"))
			config.save()

			SkillDialogue.IS_PARSING = true
			local message = Message.new(constants.COMMANDS.SKILL, 1000)
			chatService.send(message)
		end

		-- Логика при получении документов на груз
		if text:find(serverMessageService.findByCode("receive-documents").message) then
			lastCargoTakenAt = os.time()
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			if config.data.settings.autohideContractsList then
				local localMessage = LocalMessage.new(" {FFFFFF}Список контрактов успешно скрыт {ed5a5a}(( /tch.list ))")
				chatService.send(localMessage)
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end

			if httpService.version and (httpService.version.number > constants.SCRIPT_INFO.VERSION_NUMBER) then
				local messages = {
					LocalMessage.new
					(
						string.format
						(
							" {FFFFFF}Доступна новая версия скрипта" .. 
							" {ed5a5a}Truck Contracts Helper {FFFFFF}(%s).", 
							httpService.version.full_number
						),
						1000
					),
					LocalMessage.new
					(
						" {FFFFFF}Введите команду {ed5a5a}/tch.update{FFFFFF}" .. 
						" чтобы начать скачивание по ссылке.",
						1000
					)
				}
				for _, message in pairs(messages) do chatService.send(message) end
			end
		end

				 handleFinancialServerMessage(text)

		-- Логика при получении сообщения об освобождении места для груза
		if config.data.settings.autounload and text:find(serverMessageService.findByCode("waiting-for-free-place").message) and contractsService.CanUnload() then
			local minutes, seconds = text:match(serverMessageService.findByCode("waiting-for-free-place").message)
			local time = ((tonumber(minutes) * 60) + tonumber(seconds))
			local text = string.format(" {FFFFFF}Авторазгрузка начата! Пожалуйста, подождите {ed5a5a}%s секунд...", time)
			unloading.time = os.time() + time
			local message = LocalMessage.new(text)
			chatService.send(message)
			return false
		end

		if config.data.settings.autounload and text:find(serverMessageService.findByCode("no-cargo-attached").message) then
			return false
		end

		-- Проверка на аренду фуры, чтобы учесть статистику
		if text:find(serverMessageService.findByCode("successful-renting").message) then isSuccessfulRenting = true end

		-- Проверка на успешную загрузку нелегального груза
		if illegalCargoDialogue.isActive and text:find(serverMessageService.findByCode("successful-loading").message) then
			illegalCargoAvailableAt = nil
			illegalCargoDialogue.isActive = false

			-- Обновляем тайминги
			config.data.settings.lastIllegalCargoUnloadedAt = os.time()
			local illegalCargoAvailableAt = config.data.settings.lastIllegalCargoUnloadedAt + TWO_HOURS
			local illegalCargoDiffTime = os.difftime(illegalCargoAvailableAt, os.time())
			local illegalCargoAvailableAtFormatted = Time.new(illegalCargoDiffTime).toString()
			infoWindow.information.cargo.setValue(illegalCargoAvailableAtFormatted)

			-- Обновляем информацию о текущем рейсе
			race = Race.new(nil, os.time())
			infoWindow.information.race.setValue("{32CD32}Нелегальный груз{FFFFFF}")
			config.save()

			if config.data.settings.autohideContractsList then
				local localMessage = LocalMessage.new(" {FFFFFF}Список контрактов успешно скрыт {ed5a5a}(( /tch.list ))")
				chatService.send(localMessage)
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end
		end
			
		if text:find(serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message) then
			local message = serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message
			local player = playerService.getLocalPlayer()
			local nickname, _, x, y, z = text:match(message)
			x, y, z = tonumber(x), tonumber(y), tonumber(z)
			if player and player.name ~= nickname and x and y and z then
				currentBlip.coords = { x = x, y = y, z = z }
				local messages = {
					LocalMessage.new(" Вы получили координаты другого {ed5a5a}дальнобойщика{FFFFFF} по рации.", 300),
					LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами{ed5a5a} ALT + Y {FFFFFF}чтобы поставить метку.", 300)
				}
				for _, message in pairs(messages) do chatService.send(message) end
				setAudioStreamState(tickSound.audioStream, AudioStreamState.PLAY)
			end
		end

		if text:find(serverMessageService.findByCode("wrong-loading-point").message) then
			local contract = contractsService.findAvailableToTake()
			if not contract then return true end
			chatService.send(LocalMessage.new(" Произошла рассинхронизация списка контрактов. Пожалуйста, подождите...", 500, constants.COLORS.DARK_GRAY))
			MenuDialogue.FLAGS.CONTRACT.IS_WRONG_LOADING_POINT = true
			MenuDialogue.FLAGS.CONTRACT.IS_CANCELING = true
			sendContractCommandAfterDelay(constants.COMMANDS.MENU, 1000)
		end

		if text:find(serverMessageService.findByCode("flood").message) and MenuDialogue.FLAGS.CONTRACT.IS_TAKING then return false end
		if text:find(serverMessageService.findByCode("flood").message) and MenuDialogue.FLAGS.CONTRACT.IS_LOADING then
			lastCargoTakenAt = nil
			sendContractCommandAfterDelay(constants.COMMANDS.LOAD, 1000)
			return false
		end
	end
end

-- Деактивируем окно с контрактами и статистикой, если пед вышел с машины
function sampev.onSendExitVehicle(vehicleId, isPassenger)
	if config.data.settings.selectedScriptStatus > 0 then
		lua_thread.create
		(
			function()
				while isCharInAnyCar(PLAYER_PED) do wait(0) end
				mainWindow.deactivate()
				infoWindow.deactivate()
				isSettingsApplied = false
				return
			end
		)
	end
end

function sampev.onInitGame()
	resetContractSession()
	config.data.settings.sessionRaceQuantity = 0
	config.data.settings.sessionExperience = 0
	infoWindow.information.sessionExperience.setValue(Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}"))
	infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)
	config.save()
end

function sampev.onGivePlayerMoney(money)
	if config.data.settings.selectedScriptStatus > 0 then
		if ((race and not race.contract) or illegalCargoDialogue.isActive) then 
			if carsService.getDrivenTruck() then
				applyEarningsChange(money, "Нелегальный груз")
			end
		end

		-- Проверка на аренду фуры
		local generation = connectionGeneration
		lua_thread.create
		(
			function()
				wait(1000)
				if generation ~= connectionGeneration or not isSuccessfulRenting then return end
				isSuccessfulRenting = false
				applyEarningsChange(money)
				return
			end
		)
	end
end

-- Утилитные функции
function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
