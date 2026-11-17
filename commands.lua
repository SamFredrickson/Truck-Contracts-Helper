return function(dependencies)
	local config=dependencies.config
	local infoWindow=dependencies.infoWindow
	local mainWindow=dependencies.mainWindow
	local settingsWindow=dependencies.settingsWindow
	local imgui=dependencies.imgui
	local chatService=dependencies.chatService
	local LocalMessage=dependencies.LocalMessage
	local contractsService=dependencies.contractsService
	local httpService=dependencies.httpService
	local constants=dependencies.constants
	local playerService=dependencies.playerService
	local Message=dependencies.Message
	local updating = false

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
					chatService.send(LocalMessage.new("{ed5a5a}/tch.pin{FFFFFF} [номер контракта]"))
					return false
				end
				local contract = contractsService.findById(contractId)
				if not contract then
					chatService.send(LocalMessage.new(" Контракт {ed5a5a}не найден!{FFFFFF} Повторите {ed5a5a}попытку{FFFFFF} после обновления списка"))
					return false
				end
				contractsService.pin(contract)
				chatService.send(LocalMessage.new(" Контракт успешно {ed5a5a}закреплен{FFFFFF}. Изменения {ed5a5a}вступят{FFFFFF} в силу после автообновления списка"))
				return true
			end
        )

		sampRegisterChatCommand
		(
            "tch.unpin",
			function(contractId)
				contractId = tonumber(contractId)
				if contractId == nil or contractId == "" then
					chatService.send(LocalMessage.new("{ed5a5a}/tch.unpin{FFFFFF} [номер контракта]"))
					return false
				end
				local contract = contractsService.findById(contractId)
				if not contract then
					chatService.send(LocalMessage.new(" Контракт {ed5a5a}не найден!{FFFFFF} Повторите {ed5a5a}попытку{FFFFFF} после обновления списка"))
					return false
				end
				contractsService.unpin(contractId)
				chatService.send(LocalMessage.new(" Контракт успешно {ed5a5a}откреплен{FFFFFF}. Изменения {ed5a5a}вступят{FFFFFF} в силу после автообновления "))
				return true
			end
        )

		sampRegisterChatCommand
		(
            "tch.update",
			function()
				if updating then return end
				updating = true
				chatService.send(LocalMessage.new(" {FFFFFF}Проверяю версию TCH…"))
				httpService.getAvailableUpdates(function(version)
					if not version then
						updating = false
						local localMessage = LocalMessage.new(" {FFFFFF}Не удалось проверить версию TCH. Попробуйте {ed5a5a}/tch.update{FFFFFF} ещё раз.")
						chatService.send(localMessage)
						return
					end

					if version.number <= constants.SCRIPT_INFO.VERSION_NUMBER then
						updating = false
						local localMessage = LocalMessage.new("{FFFFFF}У вас уже установлена {ed5a5a}" .. "актуальная {FFFFFF}версия скрипта.")
						chatService.send(localMessage)
						return
					end

					lua_thread.create
					(
						function()
							local messages = {
								LocalMessage.new(" {FFFFFF}Не забудьте распаковать {ed5a5a}архив {FFFFFF}в папке " .. " {ed5a5a}moonloader {FFFFFF}с заменой старых файлов." ),
								LocalMessage.new(" {FFFFFF}Переход по ссылке для скачивания через {ed5a5a}3 секунды..." )
							}
							local commands = {
								string.format('start "" "%s"', version.release_url),
								string.format('start "" "%s"', constants.SCRIPT_INFO.CHANGELOG_URL)
							}
							for _, message in pairs(messages) do chatService.send(message) end
							wait(3000)
							for _, command in ipairs(commands) do os.execute(command) end
							updating = false
							return
						end
					)
				end)
			end
        )

		sampRegisterChatCommand
		(
            "tch.sos",
			function(args) 
				if config.data.settings.selectedScriptStatus > 0 then
					local player = playerService.getLocalPlayer()
					if not player then return end
					local message = Message.new
					(
						string.format(
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

		
end
