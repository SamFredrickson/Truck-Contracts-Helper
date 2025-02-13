local constants = require "tch.constants"
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"
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
local isSettingsApplied = false
local isSuccessfulRenting = false
local race = nil
local illegalCargoDialogueShowedAt = nil
local currentBlip = {
	blip = nil, 
	coords = nil,
	isActive = false
}

local unloading = {
	active = false, 
	time = nil,
	notified = false,
	tries = 0
}

local autounloading = {
	notified = false
}

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	bigFontSize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 28.0, _, glyph_ranges)
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

		sampAddChatMessage(
			" {FFFFFF}Меню настроек - {ed5a5a}/tch.menu{FFFFFF}, страница скрипта: {ed5a5a}" .. 
			thisScript().url, 0xFFFFFF
		)

		httpService.getAvailableUpdates()

		local cars = carsService.get()
		local players = playerService.get()

		local player = playerService.getByHandle(players, PLAYER_PED)
		local car = carsService.getByDriver(cars, player)

		if car 
		and car.IsTruck() 
		and carsService.IsCarAttachedToTrailer(cars, car) then
			contractsService.hasUnknownActiveContract = true
		end

		sampRegisterChatCommand
		(
			"tch.info",
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					infoWindow.toggle()
				end
			end
		)

		sampRegisterChatCommand
		(
            "tch.list",
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					mainWindow.toggle()
				end
			end
        )

		sampRegisterChatCommand
		(
            "tch.menu",
			function() settingsWindow.toggle() end
        )

		sampRegisterChatCommand
		(
            "tch.toggle",
			function() 
				local selectedScriptStatus = config.data.settings.selectedScriptStatus == 0 and 1 or 0
				config.data.settings.selectedScriptStatus = selectedScriptStatus
				settingsWindow.selectedScriptStatus = imgui.new.int(config.data.settings.selectedScriptStatus)
				config.save()
			end
        )

		sampRegisterChatCommand
		(
            "tch.pin",
			function(contractId)
				contractId = tonumber(contractId)
				if contractId == nil or contractId == "" then
					local localMessage = LocalMessage.new("{ed5a5a}/tch.pin{FFFFFF} [номер контракта]")
					chatService.send(localMessage)
					return false
				end
				if not constants.PINS:Includes(contractId) then
					constants.PINS:Push(contractId)
				end
				return true
			end
        )

		sampRegisterChatCommand
		(
            "tch.unpin",
			function(contractId)
				contractId = tonumber(contractId)
				if contractId == nil or contractId == "" then
					local localMessage = LocalMessage.new("{ed5a5a}/tch.unpin{FFFFFF} [номер контракта]")
					chatService.send(localMessage)
					return false
				end
				constants.PINS = constants.PINS.Filter(function(id)
					return contractId ~= id
				end)
				return true
			end
        )

		sampRegisterChatCommand
		(
            "tch.update",
			function()
				if not httpService.version then
					local localMessage = LocalMessage.new(
						"{FFFFFF}Произошла {ed5a5a}ошибка {FFFFFF}при попытке обновления. " ..
						"Свяжитесь с разработчиком скрипта."
					)
					chatService.send(localMessage)
					return
				end

				if httpService.version.number == constants.SCRIPT_INFO.VERSION_NUMBER then
					local localMessage = LocalMessage.new(
						"{FFFFFF}У вас уже установлена {ed5a5a}" .. 
						"актуальная {FFFFFF}версия скрипта."
					)
					chatService.send(localMessage)
					return
				end

				lua_thread.create
				(
					function()
						local messages = {
							LocalMessage.new(
								" {FFFFFF}Не забудьте распаковать {ed5a5a}архив {FFFFFF}в папке " .. 
								" {ed5a5a}moonloader {FFFFFF}с заменой старых файлов." 
							),
							LocalMessage.new(
								" {FFFFFF}Переход по ссылке для скачивания через {ed5a5a}3 секунды..." 
							)
						}
						local commands = {
							string.format(
								"start %s", 
								httpService.version.release_url
							),
							string.format(
								"start %s", 
								constants.SCRIPT_INFO.CHANGELOG_URL
							)
						}
						for _, message in pairs(messages) do
							chatService.send(message)
						end
						wait(3000)
						for _, command in pairs(commands) do
							os.execute(command)
						end
						return
					end
				)
			end
        )

		sampRegisterChatCommand
		(
            "tch.sos",
			function(args) 
				if config.data.settings.selectedScriptStatus > 0 then
					local player = playerService.getByHandle
					(
						playerService.get(),
						PLAYER_PED
					)
					local message = Message.new
					(
						string.format
						(
							"/j %s GPS: %.1f, %.1f, %.1f", 
							args:isempty() and "Помогите!" or args,
							player.coords.x, 
							player.coords.y, 
							player.coords.z
						)
					)
					chatService.send(message)
				end
			end
        )

		-- Автообновление списка контрактов
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local contracts = ContractService.CONTRACTS
					local isAutoloading = (config.data.settings.autoload and pointService.getPlayerAutoloadPoint())
					if mainWindow.window[0]
					and not contractsService.hasUnknownActiveContract
					and not isAutoloading
					and mainWindow.hideCursor
					and contractsService.CanSearch(contracts) then
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
				if config.data.settings.selectedScriptStatus > 0 then
					local contracts = ContractService.CONTRACTS
					local canUnload = contractsService.CanUnload(contracts)

					-- Легальный груз
					if config.data.settings.autounload
					and canUnload
					and ((race and race.contract) or contractsService.hasUnknownActiveContract)
					and unloading.tries < 3 
					and not unloading.time then
						unloading.tries = unloading.tries + 1
						local message = Message.new(constants.COMMANDS.UNLOAD)
						chatService.send(message)
						wait(1000)
					end

					if config.data.settings.autounload
					and canUnload
					and ((race and race.contract) or contractsService.hasUnknownActiveContract)
					and unloading.time then
						local difftime = os.difftime(unloading.time, os.time())
						if difftime < 0 then
							local message = Message.new(constants.COMMANDS.UNLOAD)
							chatService.send(message)
							wait(1000)
						end
					end

					if config.data.settings.autounload
					and canUnload
					and ((race and race.contract) or contractsService.hasUnknownActiveContract)
					and unloading.tries >= 3
					and not unloading.notified
					and not unloading.time then
						unloading.notified = true
						local text = " Контракт больше неактуален или Вы взяли не свой груз"
						local message = LocalMessage.new(text, 0, constants.COLORS.DARK_GRAY)
						chatService.send(message)
						wait(1000)
					end

					-- Нелегальный груз
					if config.data.settings.autounload
					and canUnload
					and ((race and not race.contract) or contractsService.hasUnknownActiveContract)
					and unloading.tries < 3 
					and not unloading.time then
						unloading.tries = unloading.tries + 1
						local message = Message.new(constants.COMMANDS.UNLOAD)
						chatService.send(message)
						wait(1000)
					end

					if config.data.settings.autounload
					and canUnload
					and ((race and not race.contract) or contractsService.hasUnknownActiveContract)
					and unloading.time then
						local difftime = os.difftime(unloading.time, os.time())
						if difftime < 0 then
							local message = Message.new(constants.COMMANDS.UNLOAD)
							chatService.send(message)
							wait(1000)
						end
					end
				end
			end
		):run()

		-- Прослушка комбинации клавиш для показывания курсора мыши
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local index, hotkey = table.unpack(Hotkeys.new().getByName("cursor"))
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
				if config.data.settings.selectedScriptStatus > 0 and currentBlip and not currentBlip.isActive then
					if isKeyDown(18) and isKeyDown(89) then
						while isKeyDown(18) and isKeyDown(89) do wait(80) end
						removeBlip(currentBlip.blip)
						currentBlip.blip = addSpriteBlipForCoord
						(
							currentBlip.coords.x, 
							currentBlip.coords.y, 
							currentBlip.coords.z, 
							41
						)
						currentBlip.isActive = true
						local messages = {
							LocalMessage.new(" Метка успешно {ed5a5a}поставлена{FFFFFF} на карте."),
							LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами{ed5a5a} ALT + N {FFFFFF}чтобы убрать метку.")
						}
						for _, message in pairs(messages) do
							chatService.send(message)
						end
						setAudioStreamState(markSound.audioStream, AudioStreamState.PLAY)
					end
				end
				if config.data.settings.selectedScriptStatus > 0 and currentBlip then
					if isKeyDown(18) and isKeyDown(78) then
						while isKeyDown(18) and isKeyDown(78) do wait(80) end
						removeBlip(currentBlip.blip)
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
					local cars = carsService.get()
					local players = playerService.get()

					local player = playerService.getByHandle(players, PLAYER_PED)
					local car = carsService.getByDriver(cars, player)

					if car and car.IsTruck() then
						-- Меняем цвет ника
						if config.data.settings.clistChoice > 0 then
							local message = Message.new(
								string.format(
									constants.COMMANDS.CLIST, 
									config.data.settings.clistChoice
								)
							)
							chatService.send(message)
							wait(2000)
						end
						-- Закрываем машину
						if config.data.settings.autolock and car.isLocked <= 0 then
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
						if config.data.settings.statistics then
							infoWindow.activate()
						end
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
					local index, hotkey = table.unpack(Hotkeys.new().getByName("drift"))
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
				if config.data.settings.selectedScriptStatus > 0 and currentBlip.coords then
					local player = playerService.getByHandle
					(
						playerService.get(), 
						PLAYER_PED
					)
					if player.IsWithinDistance(currentBlip.coords, 20) then
						removeBlip(currentBlip.blip)
					end
				end
			end
		):run()

		-- Прослушка на нахождение рядом со складами
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					local contracts = ContractService.CONTRACTS
					if config.data.settings.autoload 
					and contractsService.CanTake(contracts) 
					and mainWindow.hideCursor then
						local point = pointService.getPlayerAutoloadPoint()
						local contract = contractsService.getContractByAutoloadPoint(point, contracts)
						local canAutoTake = contractsService.CanAutotake(point)

						if contract 
						and not canAutoTake 
						and not autounloading.notified then
							local index, hotkey = table.unpack(Hotkeys.new().getByName("take-and-load"))
							local messages = {
								LocalMessage.new(" {FFFFFF}У точки загрузки находятся другие {ed5a5a}дальнобойщики."),
								LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами {ed5a5a}" .. hotkey.buttonText .. "{FFFFFF} или подождите пока точка будет свободна.")
							}
							for _, message in pairs(messages) do
								chatService.send(message)
							end
							autounloading.notified = true
						end

						if contract and canAutoTake then
							MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
							MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
							MenuDialogue.FLAGS.CONTRACT.ID = contract.id
							local startTimeMessage = LocalMessage.new(" {FFFFFF}Автозагрузка начата! Пожалуйста, {ed5a5a}подождите...")
							local menuCommandMessage = Message.new(constants.COMMANDS.MENU)
							chatService.send(startTimeMessage)
							chatService.send(menuCommandMessage)
							wait(1000)
						end
					end
				end
			end
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
					local index, hotkey = table.unpack(Hotkeys.new().getByName("take-and-load"))
					if hotkey.first and hotkey.second then
						if isKeyDown(hotkey.first) and isKeyDown(hotkey.second) then
							while isKeyDown(hotkey.first) and isKeyDown(hotkey.second) do wait(80) end
							local contracts = ContractService.CONTRACTS
							if contractsService.CanTake(contracts) and mainWindow.hideCursor then
								local point = pointService.getPlayerAutoloadPoint()
								local contract = contractsService.getContractByAutoloadPoint(point, contracts)
								if contract then
									MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
									MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
									MenuDialogue.FLAGS.CONTRACT.ID = contract.id
									local menuCommandMessage = Message.new(constants.COMMANDS.MENU)
									chatService.send(menuCommandMessage)
									wait(1000)
								end
							end
						end
					end
					if hotkey.first and not hotkey.second then
						if isKeyDown(hotkey.first) then
							while isKeyDown(hotkey.first) do wait(80) end
							local contracts = ContractService.CONTRACTS
							if contractsService.CanTake(contracts) and mainWindow.hideCursor then
								local point = pointService.getPlayerAutoloadPoint()
								local contract = contractsService.getContractByAutoloadPoint(point, contracts)
								if contract then
									MenuDialogue.FLAGS.CONTRACT.IS_LOADING = true
									MenuDialogue.FLAGS.CONTRACT.IS_TAKING = true
									MenuDialogue.FLAGS.CONTRACT.ID = contract.id
									local menuCommandMessage = Message.new(constants.COMMANDS.MENU)
									chatService.send(menuCommandMessage)
									wait(1000)
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
					local index, hotkey = table.unpack(Hotkeys.new().getByName("cancel-contract"))
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
			ContractService.CONTRACTS = contractsService.parse(text)
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

		if title:find(skillDialogue.title) and SkillDialogue.IS_PARSING then
			SkillDialogue.IS_PARSING = false
			local level = tonumber(text:match("Уровень:	{.-}(%d+) ур."))
			local current, goal = text:match("Опыт:	{.-}(%d+) из (%d+)")
			local value = goal - current
			local valueFormatted = Number.new(value < 0 and 0 or value).format(0, "", "{F2545B}")
			local title = string.format(
				"Опыта до %s уровня:",
				level == constants.MAX_TRUCK_DRIVER_LEVEL and constants.MAX_TRUCK_DRIVER_LEVEL or level + 1
			)

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

		if not title:find(illegalCargoDialogue.title) 
		and os.difftime(os.time(), illegalCargoDialogueShowedAt) > 10 then
			illegalCargoAvailableAt = nil
			illegalCargoDialogue.isActive = false
		end
	end
end

function sampev.onServerMessage(color, text)
	if config.data.settings.selectedScriptStatus > 0 then
		-- Логика при появлении собщения в чате, что контракт отменен
		if text:find(serverMessageService.findByCode("contract-canceled").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			contractsService.hasUnknownActiveContract = false
			unloading.tries = 0
			unloading.time = nil
			unloading.notified = false
			autounloading.notified = false
			
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update(
				contractId,
				{ IsActive = false },
				ContractService.CONTRACTS
			)

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
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS = false
			MenuDialogue.FLAGS.IS_PARSING_CONTRACTS_LAST_STEP = false
			local contract = contractsService.findActive(ContractService.CONTRACTS)
			
			if not contract then
				ContractService.CONTRACTS = {}
				contractsService.hasUnknownActiveContract = true
			end 

			local messages = {
				LocalMessage.new(" {FFFFFF}У вас уже есть {ed5a5a}активный {FFFFFF}контракт"),
				LocalMessage.new(" {FFFFFF}Используйте меню {ed5a5a}(( /tmenu )){FFFFFF} контрактов, чтобы отменить его")
			}

			for _, message in pairs(messages) do
				chatService.send(message)
			end

			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end
			
			return false
		end

		-- Логика при успешной доставки обычного груза
		if text:find(serverMessageService.findByCode("delivery-success").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			contractsService.hasUnknownActiveContract = false
			unloading.tries = 0
			unloading.time = nil
			unloading.notified = false
			autounloading.notified = false
			local contractId = tonumber(MenuDialogue.FLAGS.CONTRACT.ID)
			local contract = contractsService.update
			(
				contractId,
				{ IsActive = false },
				ContractService.CONTRACTS
			)
			if config.data.settings.autohideContractsList then
				mainWindow.hideCursor = true
				mainWindow.activate()
			end
			-- Обновляем количество рейсов за сессию
			config.data.settings.sessionRaceQuantity = config.data.settings.sessionRaceQuantity + 1
			infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)
			-- Устанавливаем время окончания рейса
			if race then race.finishedAt = os.time() end
			config.save()
		end

		-- Логика при выборе контракта из списка
		if text:find(serverMessageService.findByCode("delivery-start").message) then
			local isLoading = MenuDialogue.FLAGS.CONTRACT.IS_LOADING
			local isNextToAutoloadPoint = pointService.getPlayerAutoloadPoint()
			if isLoading and isNextToAutoloadPoint then
				local loadCommandMessage = Message.new(constants.COMMANDS.LOAD, 1000)
				chatService.send(loadCommandMessage)
			end
			if isLoading and not isNextToAutoloadPoint then
				local message = LocalMessage.new(" Вы слишком далеко от места загрузки товара", 0, constants.COLORS.DARK_GRAY)
				chatService.send(message)
			end
		end

		if text:find(serverMessageService.findByCode("flood").message) and MenuDialogue.FLAGS.CONTRACT.IS_LOADING then
			local loadCommandMessage = Message.new(constants.COMMANDS.LOAD, 1000)
			chatService.send(loadCommandMessage)
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

			-- Устанавливаем время окончания рейса
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
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			local contract = contractsService.findActive(ContractService.CONTRACTS)
			if config.data.settings.autohideContractsList then
				local localMessage = LocalMessage.new(" {FFFFFF}Список контрактов успешно скрыт {ed5a5a}(( /tch.list ))")
				chatService.send(localMessage)
				mainWindow.hideCursor = true
				mainWindow.deactivate()
			end
			if contract then
				race = Race.new(contract, os.time())
				infoWindow.information.race.setValue(trim(race.getContract()))
			end
		end

		-- Учитываем полученный штраф в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("fine").message)) then
			local fine = text:match(serverMessageService.findByCode("fine").message)
			local profitAndLoss = ProfitAndLoss.new()
			local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Штрафы с камер"))
			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - fine
			config.data.settings.totalEarnings = config.data.settings.totalEarnings - fine
			profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(fine)
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			profitAndLoss.save()
			config.save()
		end

		-- Учитываем полученный доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("income").message)) then
			local commission, income = text:match(serverMessageService.findByCode("income").message)
			local profitAndLoss = ProfitAndLoss.new()
			local profitAndLossName = profitAndLoss.getByName(race and race.contract.source or "Неизвестный источник")
			local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLossName)
			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + income
			config.data.settings.totalEarnings = config.data.settings.totalEarnings + income
			profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum + tonumber(income)
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			profitAndLoss.save()
			config.save()
		end

		-- Учитываем полученный семейный доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("family-income").message)) then
			local familyIncome = text:match(serverMessageService.findByCode("family-income").message)
			local profitAndLoss = ProfitAndLoss.new()
			local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Семейный бонус"))
			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + familyIncome
			config.data.settings.totalEarnings = config.data.settings.totalEarnings + familyIncome
			profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum + tonumber(familyIncome)
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			profitAndLoss.save()
			config.save()
		end

		-- Учитываем полученный квест-доход с разгрузки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("quest-income").message)) then
			local questIncome = text:match(serverMessageService.findByCode("quest-income").message)
			local profitAndLoss = ProfitAndLoss.new()
			local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Семейный бонус"))
			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + questIncome
			config.data.settings.totalEarnings = config.data.settings.totalEarnings + questIncome
			profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum + tonumber(questIncome)
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			profitAndLoss.save()
			config.save()
		end

		-- Учитываем полученный расход с заправки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("refilled-at-gas-station").message)) then
			local expense = text:match(serverMessageService.findByCode("refilled-at-gas-station").message)
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Заправка на станции"))
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - expense
				config.data.settings.totalEarnings = config.data.settings.totalEarnings - expense
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(expense)
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end

		-- Учитываем полученный расход с починки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("repair-accepted").message)) then
			local expense = text:match(serverMessageService.findByCode("repair-accepted").message)
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Починка механиком"))
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - expense
				config.data.settings.totalEarnings = config.data.settings.totalEarnings - expense
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(expense)
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end

		-- Учитываем полученный расход с покупки рем. комплекта в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("repair-kit-acquired").message)) then
			local expense = text:match(serverMessageService.findByCode("repair-kit-acquired").message)
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Рем. комплекты"))
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - expense
				config.data.settings.totalEarnings = config.data.settings.totalEarnings - expense
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(expense)
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end

		-- Учитываем полученный расход с покупки канистры в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("gasoline-canister-acquired").message)) then
			local expense = text:match(serverMessageService.findByCode("gasoline-canister-acquired").message)
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Канистры"))
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - expense
				config.data.settings.totalEarnings = config.data.settings.totalEarnings - expense
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(expense)
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end

		-- Учитываем полученный расход с заправки в статистику заработка
		if ((not race or (race and race.contract)) and text:find(serverMessageService.findByCode("refill-accepted").message)) then
			local expense = text:match(serverMessageService.findByCode("refill-accepted").message)
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Заправка механиком"))
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - expense
				config.data.settings.totalEarnings = config.data.settings.totalEarnings - expense
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum - tonumber(expense)
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end

		-- Логика при получении сообщения об освобождении места для груза
		if config.data.settings.autounload
		and contractsService.CanUnload(ContractService.CONTRACTS) 
		and text:find(serverMessageService.findByCode("waiting-for-free-place").message) then
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
			local nickname, message, x, y, z = text:match
			(
				serverMessageService
				.findByCode("truck-driver-chat-new-message-with-coords")
				.message
			)
			local player = playerService.getByHandle
			(
				playerService.get(), 
				PLAYER_PED
			)
			if player.name ~= nickname then
				currentBlip.isActive = false
				currentBlip.coords = { x = x, y = y, z = z }
				local messages = {
					LocalMessage.new(" Вы получили координаты другого {ed5a5a}дальнобойщика{FFFFFF} по рации.", 300),
					LocalMessage.new(" {ed5a5a}Воспользуйтесь{FFFFFF} горячими клавишами{ed5a5a} ALT + Y {FFFFFF}чтобы поставить метку.", 300)
				}
				for _, message in pairs(messages) do
					chatService.send(message)
				end
				setAudioStreamState(tickSound.audioStream, AudioStreamState.PLAY)
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
    config.data.settings.sessionEarnings = 0
	config.data.settings.sessionRaceQuantity = 0
	config.data.settings.sessionExperience = 0

	infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
	infoWindow.information.sessionExperience.setValue(Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}"))
	infoWindow.information.raceQuantity.setValue(config.data.settings.sessionRaceQuantity)

	config.save()
end

function sampev.onGivePlayerMoney(money)
	if config.data.settings.selectedScriptStatus > 0 then
		if ((race and not race.contract) or illegalCargoDialogue.isActive) then 
			local cars = carsService.get()
			local players = playerService.get()

			local player = playerService.getByHandle(players, PLAYER_PED)
			local car = carsService.getByDriver(cars, player)

			if car and car.IsTruck() then
				-- Обновляем конфигурацию
				local profitAndLoss = ProfitAndLoss.new()
				local profitAndLossIndex, profitAndLossItem = table.unpack(profitAndLoss.getByName("Нелегальный груз"))
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + money
				config.data.settings.totalEarnings = config.data.settings.totalEarnings + money
				profitAndLoss.data[profitAndLossIndex].sum = profitAndLoss.data[profitAndLossIndex].sum + money
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				profitAndLoss.save()
				config.save()
			end
		end
		-- Проверка на аренду фуры
		lua_thread.create
		(
			function()
				wait(1000)
				if not isSuccessfulRenting then return end
				isSuccessfulRenting = false
				-- Обновляем конфигурацию
				config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + money
				config.data.settings.totalEarnings = config.data.settings.totalEarnings + money
				
				-- Обновляем значения в окне
				infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
				config.save()
				return
			end
		)
	end
end

-- Утилитные функции
function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.CenterColumnTextRgb(text)
	local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
			local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize)).x
			imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - text_width / 2)
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function explode_argb(argb)
	local a = bit.band(bit.rshift(argb, 24), 0xFF)
	local r = bit.band(bit.rshift(argb, 16), 0xFF)
	local g = bit.band(bit.rshift(argb, 8), 0xFF)
	local b = bit.band(argb, 0xFF)
	return a, r, g, b
  end

function join_argb(a, r, g, b)
	local argb = b  -- b
	argb = bit.bor(argb, bit.lshift(g, 8))  -- g
	argb = bit.bor(argb, bit.lshift(r, 16)) -- r
	argb = bit.bor(argb, bit.lshift(a, 24)) -- a
	return argb
end

function argb_to_rgba(argb)
	local a, r, g, b = explode_argb(argb)
	return join_argb(r, g, b, a)
end

function argb2abgr(argb)
    local abgr = bit.bor(
        bit.lshift(bit.band(bit.rshift(argb, 24), 0xFF), 24),
        bit.lshift(bit.band(argb, 0xFF), 16),
        bit.lshift(bit.band(bit.rshift(argb, 8), 0xFF), 8),
        bit.band(bit.rshift(argb, 16), 0xFF)
    )
    return abgr
end

function intToHex(int)
    return '{'..string.sub(bit.tohex(int), 3, 8)..'}'
end

function renderDrawLineBy3dCoords(posX, posY, posZ, posX2, posY2, posZ2, width, color, radius)
    local SposX, SposY = convert3DCoordsToScreen(posX, posY, posZ)
    local SposX2, SposY2 = convert3DCoordsToScreen(posX2, posY2, posZ2)
    if isPointOnScreen(posX, posY, posZ, radius) or isPointOnScreen(posX2, posY2, posZ2, radius) then
        renderDrawLine(SposX, SposY, SposX2, SposY2, width, color)
    end
end