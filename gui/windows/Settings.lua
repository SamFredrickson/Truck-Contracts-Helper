local imgui = require "mimgui"
local ffi = require 'ffi'
local encoding = require "encoding"
local Config = require "tch.common.config"
local Statistics = require "tch.common.storage.statistics"
local Filters = require "tch.common.storage.filters"
local Window = require "tch.gui.windows.window"
local Sound = require "tch.entities.sounds.sound"
local LocalMessage = require "tch.entities.chat.localmessage"
local DriverCoordinatesEntry = require "tch.entities.coords.drivercoordinatesentry"
local DriverCoordinatesEntryService = require "tch.services.drivercoordinatesentryservice"
local ChatService = require "tch.services.chatservice"
local PointsService = require "tch.services.pointsservice"
local RedTheme = require "tch.gui.themes.red"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local pointsService = PointsService.new()
local driverCoordinatesService = DriverCoordinatesEntryService.new()
local chatService = ChatService.new()
local filters = Filters.new()

local Settings = {
    new = function()
        local self = Window.new()
        self.title = u8(
            string.format(
                "Главное меню (v%s)", 
                constants.SCRIPT_INFO.VERSION
            )
        )

        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(screenX / 2, screenY / 2)
        local size = imgui.ImVec2(620, 450)

        local active = 1
        local tabs = {
            "Основное", 
            "Контракты",
            "Статистика",
            "Взаимодействие с\n       игроками"
        }

        local clists = imgui.new['const char*'][#constants.COLOR_LIST](constants.COLOR_LIST)
        local selectedClist = imgui.new.int(config.data.settings.clistChoice)
        local scriptStatuses = imgui.new['const char*'][#constants.SCRIPT_STATUSES](constants.SCRIPT_STATUSES)
        local selectedScriptStatus = imgui.new.int(config.data.settings.selectedScriptStatus)
        local autorepairPrice = imgui.new.int(config.data.settings.repairPrice)
        local autorefillPrice = imgui.new.int(config.data.settings.refillPrice)
        local company = imgui.new.char[256](u8(filters.data.company))
        local minTonsQuantity = imgui.new.int(filters.data.minTonsQuantity)

        local isAnyItemActive = false
        local isAnyItemActiveMoreOneSecond = false
        local currentTime = nil

        -- Создаем поток для проверки на зажатие кнопок плюса или минуса в течении двух секунд
        -- чтобы избежать итерацию при единичном нажатии клавиши мыши.
        lua_thread.create
        (
            function()
                while true do
                    wait(0)
                    if isAnyItemActive then
                        currentTime = currentTime or os.time()
                        local difftime = os.difftime(os.time(), currentTime)
                        if difftime >= 2 then isAnyItemActiveMoreOneSecond = true end
                    end
                end
            end
        )

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
                RedTheme.new()
                imgui.SetNextWindowPos(
                    position, 
                    imgui.Cond.FirstUseEver, 
                    imgui.ImVec2(0.5, 0.5)
                )
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
                imgui.Begin(self.title, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
                imgui.BeginChild("##Buttons", imgui.ImVec2(150, 410), true)
                    for index, name in pairs(tabs) do
                        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
                        if imgui.Button(u8(name), imgui.ImVec2(140, 45)) then
                            active = index
                        end
                        imgui.PopStyleVar()
                    end
                imgui.EndChild()
                imgui.SetCursorPos(imgui.ImVec2(160, 28))
                if imgui.BeginChild('##Main' .. active, imgui.ImVec2(453, 410), true) then
                    if active == 1 then
                        imgui.BeginChild('##ClistChild', imgui.ImVec2(275, 400), false)
                            imgui.Text(u8"Цвет ника во время работы:")
                            if imgui.Combo
                            (
                                "##Clist", 
                                selectedClist, 
                                clists, 
                                #constants.COLOR_LIST
                            ) then
                                config.data.settings.clistChoice = selectedClist[0]
                                config.save()
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 5))
                        imgui.BeginChild('##ScriptStatus', imgui.ImVec2(385, 400), false)
                            imgui.Text(u8"Статус работы скрипта:")
                            if imgui.Combo
                            (
                                "##ScriptStatus", 
                                selectedScriptStatus, 
                                scriptStatuses, 
                                #constants.SCRIPT_STATUSES
                            ) then
                                config.data.settings.selectedScriptStatus = selectedScriptStatus[0]
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"С помощью статуса работы можно включить / выключить функции скрипта.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 55))
                        imgui.BeginChild('##UnloadChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Авторазгрузка фуры"), imgui.new.bool(config.data.settings.autounload)) then
                                config.data.settings.autounload = not config.data.settings.autounload
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Автоматически разгружать товар \nпри прибытии в один из портов.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 85))
                        imgui.BeginChild('##LockUnlockChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Автозакрытие фуры"), imgui.new.bool(config.data.settings.autolock)) then
                                config.data.settings.autolock = not config.data.settings.autolock
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                               imgui.SetTooltip(u8"Автоматически закрывать фуру, \nесли перснонаж сел в нее.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 55))
                        imgui.BeginChild('##DocumentsChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Скрывать окно документов на груз"), imgui.new.bool(config.data.settings.documentsDialogue)) then
                                config.data.settings.documentsDialogue = not config.data.settings.documentsDialogue
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Скрывать раздраюащее окно документов \nпосле покупки товара.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 85))
                        imgui.BeginChild('##Drift', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Улучшенная манёвренность (drift)"), imgui.new.bool(config.data.settings.drift)) then
                                config.data.settings.drift = not config.data.settings.drift
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"При зажатой клавише \"Shift\" двигает задней \nчастью машины быстрее, чем обычно.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 115))
                        imgui.BeginChild('##AutohideContractsList', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Автозакрытие списка"), imgui.new.bool(config.data.settings.autohideContractsList)) then
                                config.data.settings.autohideContractsList = not config.data.settings.autohideContractsList
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Прятать список контрактов, \nесли есть активный контракт.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 115))
                        imgui.BeginChild('##Autoload', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Автозагрузка фуры"), imgui.new.bool(config.data.settings.autoload)) then
                                config.data.settings.autoload = not config.data.settings.autoload
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Автоматически брать самый выгодный \nконракт и получать груз на точке загрузки.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 145))
                        imgui.BeginChild('##Statistics', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Статистика заработка"), imgui.new.bool(config.data.settings.statistics)) then
                                config.data.settings.statistics = not config.data.settings.statistics
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Автоматически открывать окно со статистикой \nи прочей информацией во время работы")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 145))
                        imgui.BeginChild('##TransparentContracts', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" Прозрачные контракты"), imgui.new.bool(config.data.settings.transparentContracts)) then
                                config.data.settings.transparentContracts = not config.data.settings.transparentContracts
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Делать список контрактов прозрачным при неактивном курсоре мыши")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 180))
                        imgui.BeginChild("##AutomechanicSuggestionsText")
                            imgui.Text(u8(" Принимать предложения"))
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Автоматически принимать предложения от механиков")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 175))
                        imgui.BeginChild("##AutomechanicSuggestions")
                            if imgui.Checkbox(u8(" Ремонта"), imgui.new.bool(config.data.settings.autorepair)) then
                                config.data.settings.autorepair = not config.data.settings.autorepair
                                config.save()
                            end
                            imgui.SameLine()
                            if imgui.Checkbox(u8(" Заправки"), imgui.new.bool(config.data.settings.autorefill)) then
                                config.data.settings.autorefill = not config.data.settings.autorefill
                                config.save()
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 210))
                        imgui.BeginChild("##AutomechanicSuggestionsRepairConditionText")
                            imgui.TextColoredRGB(" Если цена ремонта")
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Если цена ремонта меньше либо равна выбранной")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 210))
                        imgui.BeginChild("##AutomechanicSuggestionsRepairPrice")
                            imgui.PushItemWidth(200)
                            if imgui.SliderInt
                            (
                                "##repairPrice", 
                                autorepairPrice, 
                                constants.MECHANIC.MIN_REPIAR_PRICE, 
                                constants.MECHANIC.MAX_REPAIR_PRICE
                            ) then
                                config.data.settings.repairPrice = autorepairPrice[0]
                                config.save()
                            end
                            imgui.PopItemWidth()
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(400, 210))
                        imgui.BeginChild("##AutomechanicSuggestionsRepairButtons")
                            if imgui.Button("+ ##AutomechanicSuggestionsRepairPlusButton", imgui.ImVec2(20, 0)) then
                                autorepairPrice[0] = autorepairPrice[0] + 1
                                config.data.settings.repairPrice = autorepairPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorepairPrice[0] = autorepairPrice[0] + 1
                                    config.data.settings.repairPrice = autorepairPrice[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Удерживайте в течении двух секунд, чтобы ускорить прибавление \nили воспользуйтесь единичным нажатием.")
                            end
                            imgui.SameLine()
                            if imgui.Button("- ##AutomechanicSuggestionsRepairMinusButton", imgui.ImVec2(20, 0)) then
                                autorepairPrice[0] = autorepairPrice[0] - 1
                                config.data.settings.repairPrice = autorepairPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorepairPrice[0] = autorepairPrice[0] - 1
                                    config.data.settings.repairPrice = autorepairPrice[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Удерживайте в течении двух секунд, чтобы ускорить вычитание \nили воспользуйтесь единичным нажатием.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 240))
                        imgui.BeginChild("##AutomechanicSuggestionsRefillConditionText")
                            imgui.TextColoredRGB(" Если цена заправки")
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Если цена заправки меньше либо равна выбранной")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 240))
                        imgui.BeginChild("##AutomechanicSuggestionsRefillPrice")
                            imgui.PushItemWidth(200)
                            if imgui.SliderInt
                            (
                                "##refillPrice", 
                                autorefillPrice, 
                                constants.MECHANIC.MIN_REFILL_PRICE, 
                                constants.MECHANIC.MAX_REFILL_PRICE
                            ) then
                                config.data.settings.refillPrice = autorefillPrice[0]
                                config.save()
                            end
                            imgui.PopItemWidth()
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(400, 240))
                        imgui.BeginChild("##AutomechanicSuggestionsRefillButtons")
                            if imgui.Button("+ ##AutomechanicSuggestionsRefillPlusButton", imgui.ImVec2(20, 0)) then
                                autorefillPrice[0] = autorefillPrice[0] + 1
                                config.data.settings.refillPrice = autorefillPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorefillPrice[0] = autorefillPrice[0] + 1
                                    config.data.settings.refillPrice = autorefillPrice[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Удерживайте в течении двух секунд, чтобы ускорить прибавление \nили воспользуйтесь единичным нажатием.")
                            end
                            imgui.SameLine()
                            if imgui.Button("- ##AutomechanicSuggestionsRefillMinusButton", imgui.ImVec2(20, 0)) then
                                autorefillPrice[0] = autorefillPrice[0] - 1
                                config.data.settings.refillPrice = autorefillPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorefillPrice[0] = autorefillPrice[0] - 1
                                    config.data.settings.refillPrice = autorefillPrice[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"Удерживайте в течении двух секунд, чтобы ускорить вычитание \nили воспользуйтесь единичным нажатием.")
                            end
                        imgui.EndChild()
                    end
                    if active == 2 then
                        if imgui.BeginTabBar("Contract Tabs") then
                            if imgui.BeginTabItem(u8"Сортировка") then
                                imgui.Columns(4)
                                imgui.CenterColumnText(u8'Место') imgui.SetColumnWidth(-1, 225)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'Топ') imgui.SetColumnWidth(-1, 40)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'Сорт.') imgui.SetColumnWidth(-1, 40)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'Опции')
                                imgui.Columns(1)
                                imgui.Separator()
                                for index, data in pairs(pointsService.get()) do
                                    imgui.Columns(4)
                                    imgui.CenterColumnText(string.format("%s -> %s", u8(data.point.source), u8(data.point.destination)))
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8(data.point.top and "Да" or "Нет"))
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(tostring(data.point.sort))
                                    imgui.NextColumn()
                                    if imgui.Button(u8"Выше##" .. data.id) then
                                        if data.point.sort > constants.MIN_CONTRACTS_SIZE then
                                                local previous = pointsService.findBySort(data.point.sort - 1)
                                                local current = data.point
                                                pointsService.update(data.id, { sort = previous.point.sort })
                                                pointsService.update(previous.id, { sort = current.sort })
                                            end
                                        end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Перемещает запись выше по списку.")
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(u8"Ниже##" .. data.id) then
                                        if data.point.sort < constants.MAX_CONTRACTS_SIZE then
                                            local next = pointsService.findBySort(data.point.sort + 1)
                                            local current = data.point
                                            pointsService.update(data.id, { sort = next.point.sort })
                                            pointsService.update(next.id, { sort = current.sort })
                                        end
                                    end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Перемещает запись ниже по списку.")
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(u8"Топ##" .. data.id) then
                                        pointsService.update(data.id, { top = not data.point.top })
                                    end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Ставит / убирает метку \"TOP\" у записи.")
                                    end
                                    imgui.Columns(1)
                                end
                                imgui.EndTabItem()
                            end
                            if imgui.BeginTabItem(u8("Фильтрация")) then
                                imgui.SetCursorPos(imgui.ImVec2(5, 40))
                                imgui.BeginChild("##CompanyName")
                                    imgui.Text(u8(" Транспортная компания:"))
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Показывать контракты, которые принадлежат указанной компании")
                                    end
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 35))
                                imgui.BeginChild("##CompanyNameField")
                                    imgui.PushItemWidth(270)
                                    if imgui.InputText(u8("##company"), company, ffi.sizeof(company)) then
                                        filters.data.company = u8:decode(ffi.string(company):lower())
                                        filters.save()
                                    end
                                    imgui.PopItemWidth()
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                                imgui.BeginChild("##MinTonsQuantityText")
                                    imgui.Text(u8(" Минимальное кол-во тонн:"))
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Скрывать контракты у которых остаток \nменьше либо равен выбранному значению")
                                    end
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 65))
                                imgui.BeginChild("##MinTonsQuantitySlider")
                                    imgui.PushItemWidth(270)
                                    if imgui.SliderInt
                                    (
                                        "##tonsQuantity", 
                                        minTonsQuantity, 
                                        constants.MIN_TONS_QUANTITY, 
                                        constants.MAX_TONS_QUANTITY
                                    ) then
                                        filters.data.minTonsQuantity = minTonsQuantity[0]
                                        filters.save()
                                    end
                                    imgui.PopItemWidth()
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(5, 115))
                                imgui.BeginChild("##OtherFiltersText")
                                    imgui.Text(u8(" Фильтры для всех портов:"))
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 96))
                                imgui.BeginChild('##AllowedDestinations')
                                if imgui.Checkbox(u8(" Порт Лос-Сантос "), imgui.new.bool(not filters.data.destinations[1].hidden)) then
                                    filters.data.destinations[1].hidden = not filters.data.destinations[1].hidden
                                    for index, source in pairs(filters.data.sources) do
                                        filters.data.sources[index].destinations[1].hidden 
                                            = filters.data.destinations[1].hidden
                                    end
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"Показывать контракты в порт Лос-Сантос")
                                end
                                imgui.SameLine()
                                if imgui.Checkbox(u8(" Порт Сан-Фиерро"), imgui.new.bool(not filters.data.destinations[2].hidden)) then
                                    filters.data.destinations[2].hidden = not filters.data.destinations[2].hidden
                                    for index, source in pairs(filters.data.sources) do
                                        filters.data.sources[index].destinations[2].hidden 
                                            = filters.data.destinations[2].hidden
                                    end
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"Показывать контракты в порт Сан-Фиерро")
                                end
                                if imgui.Checkbox(u8(" Всегда показывать топовые (рек.)"), imgui.new.bool(filters.data.top)) then
                                    filters.data.top = not filters.data.top
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"Игнорировать все фильтры в данном окне, \nесли контракт является топовым (TOP)")
                                end
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 155))
                                imgui.BeginChild("##SourceCheckboxes")
                                    for index, source in pairs(filters.data.sources) do
                                        local portLosSantos = string.format(" %s##%d", source.destinations[1].name, index)
                                        local portSanFierro = string.format(" %s##%d", source.destinations[2].name, index)
                                        if imgui.Checkbox
                                        (
                                            u8(portLosSantos), 
                                            imgui.new.bool(not source.destinations[1].hidden)
                                        ) then
                                            filters.data.sources[index].destinations[1].hidden 
                                                = not source.destinations[1].hidden
                                            filters.save()
                                        end
                                        imgui.SameLine()
                                        imgui.SetCursorPosX(137)
                                        if imgui.Checkbox
                                        (
                                            u8(portSanFierro), 
                                            imgui.new.bool(not source.destinations[2].hidden)
                                        ) then
                                            filters.data.sources[index].destinations[2].hidden 
                                                = not source.destinations[2].hidden
                                            filters.save()
                                        end
                                    end
                                imgui.EndChild()
                                for index, source in pairs(filters.data.sources) do
                                    imgui.SetCursorPos(imgui.ImVec2(source.x, source.y))
                                    imgui.BeginChild("##SourceNames" .. index, imgui.ImVec2(145, 0), false)
                                        imgui.Text(u8(source.name))
                                    imgui.EndChild()
                                end
                                imgui.EndTabItem()
                            end
                        end
                    end
                    if active == 3 then
                        imgui.Columns(2)
                        imgui.CenterColumnText(u8'Название') imgui.SetColumnWidth(-1, 285)
                        imgui.NextColumn()
                        imgui.CenterColumnText(u8'Видимость')
                        imgui.Columns(1)
                        imgui.Separator()
                        for index, item in pairs(Statistics.new().data) do
                            imgui.Columns(2)
                            imgui.CenterColumnText(u8(item.short_name)) 
                            imgui.NextColumn()
                            if imgui.Button(u8(item.hidden and "Показывать##" or "Скрывать##") .. index, imgui.ImVec2(155, 0)) then
                                local statistics = Statistics.new()
                                statistics.data[index].hidden = not item.hidden
                                statistics.save()
                            end
                            imgui.Columns(1)
                        end
                    end
                    if active == 4 then
                       if imgui.BeginTabBar("Players Tab") then
                            if imgui.BeginTabItem(u8"Координаты") then
                                if #DriverCoordinatesEntryService.ENTRIES <= 0 then
                                    imgui.Text(u8"Список координат пуст.")
                                end
                                if #DriverCoordinatesEntryService.ENTRIES > 0 then
                                    imgui.Columns(3)
                                    imgui.CenterColumnText(u8'Отправитель') imgui.SetColumnWidth(-1, 130)
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8'Сообщение') imgui.SetColumnWidth(-1, #DriverCoordinatesEntryService.ENTRIES <= 12 and 226 or 218)
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8'Опции')
                                    imgui.Columns(1)
                                    imgui.Separator()

                                    for id, entry in pairs(DriverCoordinatesEntryService.ENTRIES) do
                                        imgui.Columns(3)
                                        imgui.CenterColumnText(entry.getNickname())
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8(entry.nickname))
                                        end
                                        imgui.NextColumn()
                                        imgui.CenterColumnText(u8(entry.getMessage()))
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8(entry.message))
                                        end
                                        imgui.NextColumn()
                                        if imgui.Button(u8"Мет.##" .. tostring(id)) then
                                            Sound.new("mark.wav", 80).play()
                                            removeBlip(entry.blip)
                                            entry.blip = addSpriteBlipForCoord(entry.x, entry.y, entry.z, 41)
                                            local localMessage = LocalMessage.new("Метка установлена на карте", nil, constants.COLORS.GOLD)
                                            chatService.send(localMessage)
                                        end
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8"Поставить метку на карте.")
                                        end
                                        imgui.SameLine()
                                        if imgui.Button(u8"Удал.##" .. tostring(id)) then
                                            removeBlip(entry.blip)
                                            driverCoordinatesService.delete(DriverCoordinatesEntryService.ENTRIES, id)
                                        end
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8"Удалить запись и метку на карте.")
                                        end
                                        imgui.Columns(1)
                                    end
                                end
                            end
                       end
                    end
                    imgui.EndChild()
                end
                imgui.End()
            end
        )
        return self
    end
}

return Settings