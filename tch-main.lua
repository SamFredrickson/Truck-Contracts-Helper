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
local Race = require "tch.entities.race"
local Time = require "tch.entities.time"
local Number = require "tch.entities.number"

local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local ScheduleService = require "tch.services.scheduleservice"
local ServerMessageService = require "tch.services.servermessageservice"
local FinancialMessages = require "tch.services.financialmessages"
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
local requestMenu
local mainWindow = MainWindow.new(function(contract, loadAfterTake)
	requestMenu("take", contract, loadAfterTake, true)
end)
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
local httpService = HttpService.new()
local pointService = PointsService.new()

local TWO_HOURS = 3600 * 2
local MAX_UNLOAD_ATTEMPTS = 3
local race = nil
local connectionGeneration = 0
local MENU_TIMEOUT = 8
local menuOperation, queuedMenuOperation
local isLoading = false
local recoveringLoadingPoint = false
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

local function sendLoad(delay)
	if not delay then
		chatService.send(Message.new(constants.COMMANDS.LOAD))
		return
	end
	local generation, pendingRace = connectionGeneration, race
	lua_thread.create(function()
		wait(delay)
		if generation == connectionGeneration and pendingRace == race and isLoading then
			chatService.send(Message.new(constants.COMMANDS.LOAD))
		end
	end)
end

local function requestLoad(delay)
	isLoading = true
	chatService.send(LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите..."))
	sendLoad(delay)
end

local function waitForHotkeyRelease(hotkey)
	local function isPressed()
		return hotkey.first and isKeyDown(hotkey.first) and (not hotkey.second or isKeyDown(hotkey.second))
	end
	if not isPressed() then return false end
	local generation = connectionGeneration
	repeat wait(80) until not isPressed()
	return generation == connectionGeneration
end

local function advanceMenu(operation, stage)
	operation.stage = stage
	operation.expiresAt = os.time() + MENU_TIMEOUT
end

local function startMenu(operation)
	menuOperation = operation
	if not operation.delay then
		advanceMenu(operation, "menu")
		chatService.send(Message.new(constants.COMMANDS.MENU))
		return
	end
	advanceMenu(operation, "scheduled")
	lua_thread.create(function()
		wait(operation.delay)
		if menuOperation ~= operation or config.data.settings.selectedScriptStatus <= 0 then return end
		advanceMenu(operation, "menu")
		chatService.send(Message.new(constants.COMMANDS.MENU))
	end)
end

local function finishMenu()
	recoveringLoadingPoint = false
	menuOperation = nil
end

local function currentMenu()
	if menuOperation and os.time() >= menuOperation.expiresAt then finishMenu() end
	return menuOperation
end

requestMenu = function(kind, contract, loadAfterTake, manual, delay)
	local operation = { kind = kind, contract = contract, loadAfterTake = loadAfterTake, manual = manual, delay = delay }
	local current = currentMenu()
	if current or queuedMenuOperation then
		if manual and current and current.kind == "search" and not queuedMenuOperation then
			operation.expiresAt = os.time() + MENU_TIMEOUT * 3
			queuedMenuOperation = operation
			return true
		end
		if manual then chatService.send(LocalMessage.new(" Меню контрактов занято. Повторите действие позже.")) end
		return false
	end
	startMenu(operation)
	return true
end

local function processQueuedMenu()
	if queuedMenuOperation and os.time() >= queuedMenuOperation.expiresAt then queuedMenuOperation = nil end
	if currentMenu() or not queuedMenuOperation or sampIsDialogActive() then return end
	local operation = queuedMenuOperation
	queuedMenuOperation = nil
	if config.data.settings.selectedScriptStatus <= 0 then return end
	if operation.kind == "take" then
		operation.contract = contractsService.findMatchingContract(operation.contract)
		if not operation.contract then
			chatService.send(LocalMessage.new(" Список контрактов изменился. Выберите контракт снова."))
			return
		end
		if not contractsService.CanTake() then return end
	end
	startMenu(operation)
end

local function resetCargoProgress()
	lastCargoTakenAt = nil
	isLoading = false
	contractsService.hasUnknownActiveContract = false
	unloading.tries = 0
	unloading.time = nil
	unloading.notified = false
	autounloading.notified = false
end

local function clearRace()
	race = nil
	infoWindow.information.race.setValue("—")
	infoWindow.information.raceTime.setValue(Time.new(0).toString())
end

local function completeRace(legalDelivery)
	if legalDelivery then
		local contract = contractsService.findActive()
		if contract then contract.IsActive = false end
	end
	resetCargoProgress()
	if race then race.finishedAt = os.time() end
	config.data.settings.sessionRaceQuantity = config.data.settings.sessionRaceQuantity + 1
	infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)
	config.save()
	if config.data.settings.autohideContractsList then
		mainWindow.hideCursor = true
		mainWindow.activate()
	end
end

local function resetContractSession()
	connectionGeneration = connectionGeneration + 1
	finishMenu()
	queuedMenuOperation = nil
	resetCargoProgress()
	clearRace()
	isSuccessfulRenting = false
	illegalCargoDialogueShowedAt = nil
	illegalCargoDialogue.isActive = false
	contractsService.setContracts({})
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

		-- Start the next user request after the previous menu closes.
		scheduleService.create(processQueuedMenu, 100):run()

		-- Автообновление списка контрактов
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					if mainWindow.window[0] 
					and mainWindow.hideCursor 
					and contractsService.CanSearch() 
					and not recoveringLoadingPoint then
						requestMenu("search")
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
				if config.data.settings.selectedScriptStatus > 0 and waitForHotkeyRelease(Hotkeys.getActive("cursor")) then
					mainWindow.hideCursor = not mainWindow.hideCursor
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
				and not recoveringLoadingPoint then
					if not race or race.finishedAt then
						local contract = contractsService.findAvailableToTake()
						if not contract then return false end
						if not requestMenu("take", contract) then return end
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
						if isSourcePointAvailable and isAutoLoadDistance and not isLoading then
							requestLoad()
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
				if config.data.settings.selectedScriptStatus > 0 and waitForHotkeyRelease(Hotkeys.getActive("take-and-load"))
				and (not lastCargoTakenAt or os.difftime(os.time(), lastCargoTakenAt) > 30)
				and mainWindow.hideCursor and contractsService.findActive() then
					requestLoad()
					wait(2000)
				end
			end,
			40
		):run()

		-- Прослушка комбинации на отмену текущего контракта
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 and waitForHotkeyRelease(Hotkeys.getActive("cancel-contract")) then
					requestMenu("cancel", nil, nil, true)
				end
			end,
			40
		):run()

		while true do
			wait(-1)
		end
end

local function handleContractDialog(id, title, text)
	local operation = currentMenu()
	if not operation then return end

	if title == menuDialogue.title then
		if operation.stage == "close-menu" then
			finishMenu()
			sampSendDialogResponse(id, 0, 0, "")
			return false
		end
		if operation.stage == "menu" then
			if operation.kind == "cancel" then
				advanceMenu(operation, "confirmation")
				sampSendDialogResponse(id, 1, 1, "")
			else
				advanceMenu(operation, "list")
				sampSendDialogResponse(id, 1, 0, "")
			end
			return false
		end
	elseif title == contractsDialogue.title and operation.stage == "list" then
		if operation.kind == "search" then
			contractsService.setContracts(contractsService.parse(text))
			advanceMenu(operation, "close-menu")
			sampSendDialogResponse(id, 0, 0, "")
		else
			local row = contractsService.findDialogRow(text, operation.contract)
			if not row then
				contractsService.setContracts(contractsService.parse(text))
				if operation.manual then chatService.send(LocalMessage.new(" Список контрактов изменился. Выберите контракт снова.")) end
				advanceMenu(operation, "close-menu")
				sampSendDialogResponse(id, 0, 0, "")
			else
				advanceMenu(operation, "confirmation")
				sampSendDialogResponse(id, 1, row, "")
			end
		end
		return false
	end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
	if config.data.settings.selectedScriptStatus > 0 then
		if handleContractDialog(id, title, text) == false then return false end

		if title:find(skillDialogue.title) and SkillDialogue.IS_PARSING then
			SkillDialogue.IS_PARSING = false
			local level = tonumber(text:match("Уровень:	{.-}(%d+) ур."))
			local current, goal = text:match("Опыт:	{.-}(%d+) из (%d+)")
			current, goal = tonumber(current), tonumber(goal)
			if not level or not current or not goal then return end
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

local function clearCanceledContract(operation)
	local recover = recoveringLoadingPoint and operation and operation.kind == "cancel"
	if operation and operation.kind == "cancel" then finishMenu() end
	local contract = contractsService.findActive()
	if contract then contract.IsActive = false end

	resetCargoProgress()
	clearRace()

	if recover then recoveringLoadingPoint = requestMenu("search", nil, nil, false, 3000) end
	if config.data.settings.autohideContractsList then
		mainWindow.hideCursor = true
		mainWindow.activate()
	end
end

local function isNoActiveContractMessage(text)
	local message = text:gsub("{%x%x%x%x%x%x}", ""):gsub("^%s*", ""):gsub("^%[Ошибка%]%s*", "")
	return serverMessageService.match(message, "hasnt-active-contract")
		or serverMessageService.match(message, "hasnt-active-contract-short")
end

function sampev.onServerMessage(color, text)
	if config.data.settings.selectedScriptStatus > 0 then
		if serverMessageService.match(text, "contract-canceled") then
			clearCanceledContract(currentMenu())
		elseif isLoading or (menuOperation and menuOperation.kind == "cancel") then
			if isNoActiveContractMessage(text) then
				local operation = currentMenu()
				if isLoading or (operation and operation.kind == "cancel" and operation.stage ~= "scheduled") then
					if queuedMenuOperation and queuedMenuOperation.kind == "cancel" then queuedMenuOperation = nil end
					clearCanceledContract(operation)
					return
				end
			end
		end

		-- Логика при появлении собщения в чате, что игрок имеет активный контракт
		if serverMessageService.match(text, "has-active-contract") then
			finishMenu()
			queuedMenuOperation = nil
			isLoading = false
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
		if serverMessageService.match(text, "delivery-success") then completeRace(true) end

		-- Логика при выборе контракта из списка
		if serverMessageService.match(text, "delivery-start") then
			local hotkey = Hotkeys.getActive("cancel-contract")
			local message = LocalMessage.new(" {FFFFFF}Если нужно {ed5a5a}отменить{FFFFFF} контракт - воспользуйтесь горячими клавишами {ed5a5a}" .. hotkey.buttonText, 1000)
			chatService.send(message)

			local operation = currentMenu()
			if operation and operation.kind == "take" and operation.stage == "confirmation" then
				local contract = operation.contract
				contract.IsActive = true
				finishMenu()
				resetCargoProgress()
				race = Race.new(contract, os.time())
				infoWindow.information.race.setValue(trim(race.getContract()))
				if operation.loadAfterTake then
					local player = playerService.getLocalPlayer()
					local point = contract.getSourcePoint()
					if player and point and player.IsWithinDistance(point.coords, point.autoTakeDistance) then
						requestLoad(1000)
					else
						chatService.send(LocalMessage.new(" Вы слишком далеко от точки загрузки.", 1000, constants.COLORS.DARK_GRAY))
					end
				end
			end
		end

		-- Логика при успешной доставке нелегального груза
		if serverMessageService.match(text, "illegal-delivery-success") then completeRace(false) end

		-- Логика при получении опыта за груз
		local experience = tonumber(serverMessageService.match(text, "contract-experience"))
		if experience then
			config.data.settings.sessionExperience = config.data.settings.sessionExperience + experience
			infoWindow.information.sessionExperience.setValue(Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}"))
			config.save()

			SkillDialogue.IS_PARSING = true
			local message = Message.new(constants.COMMANDS.SKILL, 1000)
			chatService.send(message)
		end

		-- Логика при получении документов на груз
		if serverMessageService.match(text, "receive-documents") then
			lastCargoTakenAt = os.time()
			isLoading = false
			if config.data.settings.autohideContractsList then
				local localMessage = LocalMessage.new(" {FFFFFF}Список контрактов успешно скрыт {ed5a5a}(( /tch.list ))")
				chatService.send(localMessage)
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end

			httpService.notifyIfUpdateAvailable()
		end
		if not race or race.contract then
			FinancialMessages.handle(text, race and race.contract.source, serverMessageService, carsService.getDrivenTruck, applyEarningsChange)
		end

		-- Логика при получении сообщения об освобождении места для груза
		local minutes, seconds = serverMessageService.match(text, "waiting-for-free-place")
		minutes, seconds = tonumber(minutes), tonumber(seconds)
		if config.data.settings.autounload and minutes and seconds and contractsService.CanUnload() then
			local time = minutes * 60 + seconds
			local text = string.format(" {FFFFFF}Авторазгрузка начата! Пожалуйста, подождите {ed5a5a}%s секунд...", time)
			unloading.time = os.time() + time
			local message = LocalMessage.new(text)
			chatService.send(message)
			return false
		end

		if config.data.settings.autounload and serverMessageService.match(text, "no-cargo-attached") then
			return false
		end

		-- Проверка на аренду фуры, чтобы учесть статистику
		if serverMessageService.match(text, "successful-renting") then isSuccessfulRenting = true end

		-- Проверка на успешную загрузку нелегального груза
		if illegalCargoDialogue.isActive and serverMessageService.match(text, "successful-loading") then
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
			
		local nickname, _, x, y, z = serverMessageService.match(text, "truck-driver-chat-new-message-with-coords")
		if nickname then
			local player = playerService.getLocalPlayer()
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

		if serverMessageService.match(text, "wrong-loading-point") then
			if not contractsService.findAvailableToTake() then return true end
			if not recoveringLoadingPoint and requestMenu("cancel", nil, nil, false, 1000) then
				recoveringLoadingPoint = true
				chatService.send(LocalMessage.new(" Произошла рассинхронизация списка контрактов. Пожалуйста, подождите...", 500, constants.COLORS.DARK_GRAY))
			end
		end

		if serverMessageService.match(text, "flood") then
			local operation = currentMenu()
			if operation and operation.kind == "take" and operation.stage ~= "scheduled" then
				finishMenu()
				return false
			end
			if isLoading then
				lastCargoTakenAt = nil
				sendLoad(1000)
				return false
			end
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
