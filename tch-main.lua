local constants = require "tch.constants"
local encoding = require "encoding"
local vkeys = require "vkeys"
local sampev = require "samp.events"
local imgui = require "mimgui"

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
local RepairSuggestion = require "tch.samp.dialogues.repairsuggestion"
local RefillSuggestion = require "tch.samp.dialogues.refillsuggestion"

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
local repairSuggestion = RepairSuggestion.new()
local refillSuggestion = RefillSuggestion.new()

local contract = Contract.new()
local mainWindow = MainWindow.new()
local settingsWindow = SettingsWindow.new()
local infoWindow = InfoWindow.new()

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
local hasActiveContract = false
local isSuccessfulRenting = false
local race = nil

local unloading = {
	active = false, 
	time = nil,
	notified = false
}

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end

		sampAddChatMessage(
			" {FFFFFF}Меню настроек - {ed5a5a}/tch.menu{FFFFFF}, страница скрипта: {ed5a5a}" .. 
			thisScript().url, 0xFFFFFF
		)

		httpService.getAvailableUpdates()

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
            "tch.coords.send",
			function(args) 
				if config.data.settings.selectedScriptStatus > 0 then
					if args == nil or args == "" then
						local localMessage = LocalMessage.new("{ed5a5a}/tch.coords.send{FFFFFF} [текст сообщения]")
						chatService.send(localMessage)
						return
					end
	
					local player = playerService.getByHandle(
						playerService.get(), 
						PLAYER_PED
					)
	
					local message = Message.new
					(
						string.format
						(
							"/j %s %f|%f|%f", 
							args, 
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
					and not hasActiveContract
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
					and (race and race.contract)
					and not unloading.active then
						local message = Message.new(constants.COMMANDS.UNLOAD)
						chatService.send(message)
						unloading.active = true
						wait(1000)
					end

					if config.data.settings.autounload
					and canUnload
					and unloading.active
					and (race and race.contract)
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
					and (race and race.contract)
					and unloading.active
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
					and (race and not race.contract)
					and not unloading.active then
						local message = Message.new(constants.COMMANDS.UNLOAD)
						chatService.send(message)
						unloading.active = true
						wait(1000)
					end

					if config.data.settings.autounload
					and canUnload
					and unloading.active
					and (race and not race.contract)
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
					if isKeyDown(vkeys.VK_SHIFT) and isKeyDown(vkeys.VK_C) then
						while isKeyDown(vkeys.VK_SHIFT) and isKeyDown(vkeys.VK_C) do wait(80) end
						mainWindow.hideCursor = not mainWindow.hideCursor
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
					if isCharInAnyCar(PLAYER_PED) then
						local car = storeCarCharIsInNoSave(PLAYER_PED)
						local speed = getCarSpeed(car)
						setCarCollision(car, true)
						if isKeyDown(vkeys.VK_SHIFT) 
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
				if config.data.settings.selectedScriptStatus > 0 then
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
						
						if contract and not contractsService.CanAutotake(point) then
							local messages = {
								LocalMessage.new(" {FFFFFF}Рядом находятся другие {ed5a5a}дальнобойщики"),
								LocalMessage.new(" {FFFFFF}Подождите {ed5a5a}5 секунд{FFFFFF} или возьмите груз вручную {ed5a5a}(( /tch.list » Взять контракт и загрузить ))")
							}
							for _, message in pairs(messages) do
								chatService.send(message)
							end
							wait(5000)
							return
						end

						if contract then
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

		-- Проверка на активное предложение от механика
		scheduleService.create
		(
			function()
				if config.data.settings.selectedScriptStatus > 0 then
					if repairSuggestion.active then setGameKeyState(11, 255) end
					if refillSuggestion.active then setGameKeyState(11, 255) end
				end
			end,
			10
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

		if config.data.settings.autorepair 
		and title:find(repairSuggestion.title) 
		and repairSuggestion.active then
			sampSendDialogResponse(id, 1, _, _)
			return false
		end

		if config.data.settings.autorefill 
		and title:find(refillSuggestion.title) 
		and refillSuggestion.active then
			sampSendDialogResponse(id, 1, _, _)
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
			illegalCargoDialogue.isActive = true
		end

		if not title:find(illegalCargoDialogue.title) then
			illegalCargoDialogue.isActive = false
		end
	end
end

function sampev.onSendDialogResponse(dialogId, button, list, input)
	if illegalCargoDialogue.isActive and button == 1 then
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
end

function sampev.onServerMessage(color, text)
	if config.data.settings.selectedScriptStatus > 0 then
		-- Логика при появлении собщения в чате, что контракт отменен
		if text:find(serverMessageService.findByCode("contract-canceled").message) then
			MenuDialogue.FLAGS.CONTRACT.IS_LOADING = false
			hasActiveContract = false
			unloading.active = false
			unloading.time = nil
			unloading.notified = false
			
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
			ContractService.CONTRACTS = {}
			hasActiveContract = true

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
			hasActiveContract = false
			unloading.active = false
			unloading.time = nil
			unloading.notified = false

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
			hasActiveContract = false
			unloading.active = false
			unloading.time = nil
			unloading.notified = false

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
		if text:find(serverMessageService.findByCode("fine").message) then
			local fine = text:match(serverMessageService.findByCode("fine").message)

			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings - fine
			config.data.settings.totalEarnings = config.data.settings.totalEarnings - fine
			
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			infoWindow.information.totalEarnings.setValue(Number.new(config.data.settings.totalEarnings).format(0, "", "{F2545B}"))

			config.save()
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

		if config.data.settings.autorepair and text:find(serverMessageService.findByCode("repair-suggestion").message) then
			local name, price = text:match(serverMessageService.findByCode("repair-suggestion").message)
			if tonumber(price) <= config.data.settings.repairPrice then
				repairSuggestion.active = true
			end
		end

		if config.data.settings.autorefill and text:find(serverMessageService.findByCode("refill-suggestion").message) then
			local name, liters, price = text:match(serverMessageService.findByCode("refill-suggestion").message)
			if tonumber(price) <= config.data.settings.refillPrice then
				refillSuggestion.active = true
			end
		end

		if text:find(serverMessageService.findByCode("repair-accepted").message) then
			repairSuggestion.active = false
		end

		if text:find(serverMessageService.findByCode("repair-already").message) then
			repairSuggestion.active = false
		end

		if text:find(serverMessageService.findByCode("repair-not-required").message) then
			repairSuggestion.active = false
		end

		if text:find(serverMessageService.findByCode("refill-accepted").message) then
			refillSuggestion.active = false
		end

		if config.data.settings.autounload and text:find(serverMessageService.findByCode("no-cargo-attached").message) then
			return false
		end

		-- Проверка на аренду фуры, чтобы учесть статистику
		if text:find(serverMessageService.findByCode("successful-renting").message) then isSuccessfulRenting = true end
			
		-- Проверка на отправленные в рацию координаты
		if text:find(serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message) then
			local nickname, message, x, y, z = text:match(
				serverMessageService.findByCode("truck-driver-chat-new-message-with-coords").message
			)

			local player = playerService.getByHandle(
				playerService.get(), 
				PLAYER_PED
			)

			if player.name ~= nickname then
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

				local localMessage = LocalMessage.new(
					" {FFFFFF}Координаты успешно внесены в список " ..
					"{ed5a5a}(( /tch.menu » Взаимодействие с игроками ))",
					500
				)

				chatService.send(localMessage)
				Sound.new("tick.wav", 100).play()
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
		local cars = carsService.get()
		local players = playerService.get()

		local player = playerService.getByHandle(players, PLAYER_PED)
		local car = carsService.getByDriver(cars, player)

		if car and car.IsTruck() then
			-- Обновляем конфигурацию
			config.data.settings.sessionEarnings = config.data.settings.sessionEarnings + money
			config.data.settings.totalEarnings = config.data.settings.totalEarnings + money
			
			-- Обновляем значения в окне
			infoWindow.information.sessionEarnings.setValue(Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}"))
			infoWindow.information.totalEarnings.setValue(Number.new(config.data.settings.totalEarnings).format(0, "", "{F2545B}"))

			config.save()
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
				infoWindow.information.totalEarnings.setValue(Number.new(config.data.settings.totalEarnings).format(0, "", "{F2545B}"))

				config.save()
				return
			end
		)
	end
end

-- Утилитные функции
in_array = function(needle, array)
    for _, value in pairs(array) do
        if needle == value then
            return true
        end
    end
    return false
end

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