local imgui = require "mimgui"
local encoding = require "encoding"
local Config = require "tch.common.config"
local Statistics = require "tch.common.storage.statistics"
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

        local truckRentedChoices = imgui.new['const char*'][#constants.TRUCK_RENTED_CHOICES](constants.TRUCK_RENTED_CHOICES)
        local selectedTruckRentedChoice = imgui.new.int(config.data.settings.truckRentedChoice)

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
                            if imgui.Combo(
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
                        imgui.BeginChild('##ContractsChild', imgui.ImVec2(385, 400), false)
                            imgui.Text(u8"Открывать список контрактов, если:")
                            if imgui.Combo(
                                "##Contracts", 
                                selectedTruckRentedChoice, 
                                truckRentedChoices, 
                                #constants.TRUCK_RENTED_CHOICES
                            ) then
                                config.data.settings.truckRentedChoice = selectedTruckRentedChoice[0]
                                config.save()
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
                                        if data.point.sort > 1 then
                                                local previous = pointsService.findBySort(data.point.sort - 1)
                                                local current = data.point

                                                pointsService.update(
                                                    data.id, 
                                                    { sort = previous.point.sort }
                                                )

                                                pointsService.update(
                                                    previous.id, 
                                                    { sort = current.sort }
                                                )
                                            end
                                        end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"Перемещает запись выше по списку.")
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(u8"Ниже##" .. data.id) then
                                        if data.point.sort < 16 then
                                            local next = pointsService.findBySort(data.point.sort + 1)
                                            local current = data.point
                                            pointsService.update(
                                                data.id, 
                                                { sort = next.point.sort }
                                            )
                                            pointsService.update(
                                                next.id, 
                                                { sort = current.sort }
                                            )
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
                            end
                        end
                    end
                    if active == 3 then
                        if imgui.BeginTabBar("Statistics") then
                            imgui.Columns(2)
                            imgui.CenterColumnText(u8'Название') imgui.SetColumnWidth(-1, 285)
                            imgui.NextColumn()
                            imgui.CenterColumnText(u8'Видимость')
                            imgui.Columns(1)
                            imgui.Separator()
                        end

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
                                            entry.blip = addSpriteBlipForCoord(
                                                entry.x, 
                                                entry.y, 
                                                entry.z, 
                                                41
                                            )
                                            local localMessage = LocalMessage.new(
                                                "Метка установлена на карте",
                                                nil,
                                                constants.COLORS.GOLD
                                            )
                                            chatService.send(localMessage)
                                        end
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8"Поставить метку на карте.")
                                        end
                                        imgui.SameLine()
                                        if imgui.Button(u8"Удал.##" .. tostring(id)) then
                                            removeBlip(entry.blip)
                                            driverCoordinatesService.delete(
                                                DriverCoordinatesEntryService.ENTRIES, 
                                                id
                                            )
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