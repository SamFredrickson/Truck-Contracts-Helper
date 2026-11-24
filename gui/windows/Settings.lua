local imgui = require "mimgui"
local Scale = require "tch.gui.scale"
local Navigation = require "tch.gui.navigation"
local ContractIcons = require "tch.gui.contracticons"
local ffi = require 'ffi'
local encoding = require "encoding"
local Config = require "tch.common.config"
local Statistics = require "tch.common.storage.statistics"
local InfoPanel = require "tch.gui.windows.info"
local ProfitAndLoss = require "tch.common.storage.profitandloss"
local Filters = require "tch.common.storage.filters"
local Hotkeys = require "tch.common.storage.hotkeys"
local Window = require "tch.gui.windows.window"
local HotKeysManager = require "tch.gui.windows.hotkeysmanager"
local Sound = require "tch.entities.sounds.sound"
local Number = require "tch.entities.number"
local LocalMessage = require "tch.entities.chat.localmessage"
local ChatService = require "tch.services.chatservice"
local PointsService = require "tch.services.pointsservice"
local RedTheme = require "tch.gui.themes.red"
local Theme = require "tch.gui.themes.theme"
local Palette = require "tch.gui.themes.palette"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local hotKeysManager = HotKeysManager.new()
local pointsService = PointsService.new()
local chatService = ChatService.new()

local Settings = {
    new = function()
        local self = Window.new()
        self.isEditingHotkey = function() return hotKeysManager.window[0] end
        self.title = u8(string.format("Главное меню (v%s)", constants.SCRIPT_INFO.VERSION))
        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(screenX / 2, screenY / 2)
        local lastScale
        local lastWindowHeight
        local generalContentHeight
        local contractsContentHeight
        local statisticsContentHeight
        local statisticsDisplayActive = true
        local active = 1
        local themeLabels = {}
        local themeIndex = 0
        for i, palette in ipairs(Palette.options) do
            themeLabels[i] = u8(palette.name)
            if palette.id == Palette.current().id then themeIndex = i - 1 end
        end
        local themeNames = imgui.new['const char*'][#themeLabels](themeLabels)
        local selectedTheme = imgui.new.int(themeIndex)
        local scaleLabels, scaleIndex = {}, 0
        for i, percent in ipairs(Scale.options) do
            scaleLabels[i] = percent .. "%"
            if percent == Scale.percent() then scaleIndex = i - 1 end
        end
        local scaleNames = imgui.new['const char*'][#scaleLabels](scaleLabels)
        local selectedScale = imgui.new.int(scaleIndex)
        local infoAlignmentLabels = { u8("Слева"), u8("По центру"), u8("Справа") }
        local initialInfoAlignment = tonumber(config.data.settings.infoPanelAlignment) or 0
        if initialInfoAlignment ~= 1 and initialInfoAlignment ~= 2 then initialInfoAlignment = 0 end
        local selectedInfoAlignment = imgui.new.int(initialInfoAlignment)
        local pendingScale
        local tabs = {
            "Основное",
            "Команды и\nклавиши",
            "Контракты",
            "Статистика"
        }

        local clists = imgui.new['const char*'][#constants.COLOR_LIST](constants.COLOR_LIST)
        local contractWindowTypes = imgui.new['const char*'][#constants.CONTRACT_LIST_WINDOW_TYPES](constants.CONTRACT_LIST_WINDOW_TYPES)
        local selectedContractWindowTypes = imgui.new.int(config.data.settings.contractWindowTypes)
        local selectedClist = imgui.new.int(config.data.settings.clistChoice)
        local scriptStatuses = imgui.new['const char*'][#constants.SCRIPT_STATUSES](constants.SCRIPT_STATUSES)
        self.selectedScriptStatus = imgui.new.int(config.data.settings.selectedScriptStatus)
        local initialFilters = Filters.new()
        local company = imgui.new.char[256](u8(initialFilters.data.company))
        local minTonsQuantity = imgui.new.int(initialFilters.data.minTonsQuantity)
        local linesWidth = imgui.new.int(config.data.settings.linesWidth)

        local convertedToFloat4 = imgui.ColorConvertU32ToFloat4(config.data.settings.linesColor)
        local color = imgui.new.float[4](convertedToFloat4.x, convertedToFloat4.y, convertedToFloat4.z, convertedToFloat4.w)

        local pendingCamera
        local pendingMinTons
        local resetProfitEntry

        local function saveSetting(key, value)
            local settings = config.data.settings
            local previous = settings[key]
            if previous == value then return true end
            settings[key] = value
            if Window.reportSave(config.save()) then return true end
            settings[key] = previous
            return false
        end

        local function beginCameraEdit()
            if not pendingCamera then
                local settings = config.data.settings
                pendingCamera = { color = settings.linesColor, width = settings.linesWidth }
            end
        end

        local function saveCamera()
            if not pendingCamera then return end
            local settings = config.data.settings
            if (settings.linesColor ~= pendingCamera.color or settings.linesWidth ~= pendingCamera.width)
            and not Window.reportSave(config.save()) then
                settings.linesColor, settings.linesWidth = pendingCamera.color, pendingCamera.width
                local restored = imgui.ColorConvertU32ToFloat4(settings.linesColor)
                color[0], color[1], color[2], color[3] = restored.x, restored.y, restored.z, restored.w
                linesWidth[0] = settings.linesWidth
            end
            pendingCamera = nil
        end

        local function saveMinTons(filters)
            if not pendingMinTons then return end
            filters = filters or Filters.new()
            if filters.data.minTonsQuantity ~= minTonsQuantity[0] then
                local previous = filters.data.minTonsQuantity
                filters.data.minTonsQuantity = minTonsQuantity[0]
                if not Window.reportSave(filters.save()) then
                    filters.data.minTonsQuantity = previous
                    minTonsQuantity[0] = previous
                end
            end
            pendingMinTons = false
        end

        local function drawGeneralSettings()
            local function hint(text)
                if not imgui.IsItemHovered() then return end
                imgui.BeginTooltip()
                local screenWidth = getScreenResolution()
                imgui.PushTextWrapPos(math.min(Scale.px(280), screenWidth - 20))
                imgui.TextUnformatted(u8(text))
                imgui.PopTextWrapPos()
                imgui.EndTooltip()
            end
            local function checkbox(key, label, tooltip)
                if imgui.Checkbox(u8(label .. "##General" .. key), imgui.new.bool(config.data.settings[key])) then
                    saveSetting(key, not config.data.settings[key])
                end
                hint(tooltip)
            end
            local function columns(id)
                local halfWidth = imgui.GetContentRegionAvail().x / 2
                imgui.Columns(2, id, false)
                imgui.SetColumnWidth(0, halfWidth)
            end
            local function field(label, control)
                columns("GeneralField" .. label)
                local y = imgui.GetCursorPosY()
                imgui.SetCursorPosY(y + Scale.px(4))
                imgui.Text(u8(label))
                imgui.NextColumn()
                imgui.PushItemWidth(-1)
                control()
                imgui.PopItemWidth()
                imgui.Columns(1)
            end
            columns("GeneralWorkStatus")
            imgui.Text(u8("Статус скрипта"))
            imgui.PushItemWidth(-1)
            if imgui.Combo("##ScriptStatus", self.selectedScriptStatus, scriptStatuses, #constants.SCRIPT_STATUSES) then
                if not saveSetting("selectedScriptStatus", self.selectedScriptStatus[0]) then
                    self.selectedScriptStatus[0] = config.data.settings.selectedScriptStatus
                end
            end
            hint("Включает или приостанавливает работу скрипта.")
            imgui.PopItemWidth()
            imgui.NextColumn()
            imgui.Text(u8("Цвет ника во время работы"))
            imgui.PushItemWidth(-1)
            if imgui.Combo("##Clist", selectedClist, clists, #constants.COLOR_LIST) then
                if not saveSetting("clistChoice", selectedClist[0]) then selectedClist[0] = config.data.settings.clistChoice end
            end
            hint("Цвет ника, который применяется, когда вы садитесь за руль фуры.")
            imgui.PopItemWidth()
            imgui.Columns(1)
            columns("GeneralWorkOptions")
            checkbox("autoload", "Автозагрузка фуры", "Берёт доступный контракт у точки загрузки и загружает фуру. Если контракт уже взят, начинает загрузку при подъезде к его точке.")
            checkbox("autolock", "Запирать фуру", "Автоматически запирает двери фуры, когда вы садитесь за руль.")
            checkbox("autohideContractsList", "Скрывать список", "Автоматически скрывает список контрактов, когда вы берёте контракт.")
            checkbox("statistics", "Нижняя панель", "Показывает маршрут, таймеры и статистику внизу экрана. Состав и положение панели настраиваются в разделе «Статистика».")
            checkbox("cameraLines", "Подсветка камер", "Показывает линии зон контроля дорожных камер. Цвет и толщину линий можно настроить ниже.")
            imgui.NextColumn()
            checkbox("autounload", "Авторазгрузка фуры", "Начинает разгрузку, когда фура с грузом находится у подходящей точки разгрузки в порту.")
            checkbox("documentsDialogue", "Скрывать документы", "Скрывает серверный диалог с документами на груз после загрузки фуры.")
            checkbox("drift", "Манёвренность (drift)", "Помогает быстрее поворачивать машину при движении. Удерживайте клавишу дрифта, назначенную в разделе «Команды и клавиши».")
            checkbox("transparentContracts", "Прозрачный список", "Делает фон списка контрактов полупрозрачным, когда курсор управления списком выключен.")
            checkbox("transparentCorpses", "Проезд сквозь тела", "Позволяет проезжать сквозь тела погибших персонажей, чтобы они не мешали движению.")
            imgui.Columns(1)

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            field("Тема интерфейса", function()
                if imgui.Combo("##InterfaceTheme", selectedTheme, themeNames, #themeLabels) then
                    if saveSetting("theme", Palette.options[selectedTheme[0] + 1].id) then Theme.apply()
                    else selectedTheme[0] = themeIndex end
                    themeIndex = selectedTheme[0]
                end
                hint("Меняет цвета окон, кнопок и текста скрипта. Выбранная тема сохраняется.")
            end)
            field("Масштаб интерфейса", function()
                if imgui.Combo("##InterfaceScale", selectedScale, scaleNames, #scaleLabels) then pendingScale = Scale.options[selectedScale[0] + 1] end
                hint("Меняет размер текста и элементов интерфейса. 100% — обычный размер; большее значение увеличивает окна и нижнюю панель.")
            end)
            field("Размер списка контрактов", function()
                if imgui.Combo("##ContractWindowTypesList", selectedContractWindowTypes, contractWindowTypes, #constants.CONTRACT_LIST_WINDOW_TYPES) then
                    if not saveSetting("contractWindowTypes", selectedContractWindowTypes[0]) then selectedContractWindowTypes[0] = config.data.settings.contractWindowTypes end
                end
                hint("Маленький — компактные строки с меню действий по нажатию. Средний и большой — раскрывающиеся пункты с кнопками.")
            end)

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            local cameraEnabled = config.data.settings.cameraLines
            if not cameraEnabled then imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, imgui.GetStyle().Alpha * 0.45) end
            field("Цвет линий", function()
                if cameraEnabled then
                    if imgui.ColorEdit4("##color", color) then
                        beginCameraEdit()
                        config.data.settings.linesColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color[0], color[1], color[2], color[3]))
                    end
                    hint("Задаёт цвет и прозрачность линий камер. A: 0 — невидимые линии, 255 — полностью непрозрачные.")
                else
                    imgui.TextColored(Theme.color("muted"), string.format("R:%d  G:%d  B:%d  A:%d", math.floor(color[0]*255+0.5), math.floor(color[1]*255+0.5), math.floor(color[2]*255+0.5), math.floor(color[3]*255+0.5)))
                end
            end)
            field("Толщина линий", function()
                if cameraEnabled then
                    imgui.PushItemWidth(math.max(Scale.px(50), imgui.GetContentRegionAvail().x - Scale.px(56)))
                    if imgui.SliderInt("##cameraLinesWidth", linesWidth, constants.CAMERA_LINES.MIN_WIDTH, constants.CAMERA_LINES.MAX_WIDTH) then
                        beginCameraEdit()
                        config.data.settings.linesWidth = linesWidth[0]
                    end
                    imgui.PopItemWidth()
                    hint("Меняет толщину линий дорожных камер.")
                    imgui.SameLine()
                    if imgui.Button("+##CameraLinesPlusButton", Scale.vec(22, 0)) then
                        beginCameraEdit()
                        linesWidth[0] = math.min(constants.CAMERA_LINES.MAX_WIDTH, linesWidth[0] + 1)
                        config.data.settings.linesWidth = linesWidth[0]
                    end
                    imgui.SameLine()
                    if imgui.Button("-##CameraLinesMinusButton", Scale.vec(22, 0)) then
                        beginCameraEdit()
                        linesWidth[0] = math.max(constants.CAMERA_LINES.MIN_WIDTH, linesWidth[0] - 1)
                        config.data.settings.linesWidth = linesWidth[0]
                    end
                else
                    imgui.TextColored(Theme.color("muted"), tostring(linesWidth[0]))
                end
            end)
            if not cameraEnabled then imgui.PopStyleVar() end
            generalContentHeight = (imgui.GetCursorPosY() + Scale.px(12)) / Scale.factor()
        end
        local function drawHotkeys()
            local hotkeys = Hotkeys.new().data
            imgui.SetCursorPos(Scale.vec(10, 5))
            imgui.BeginChild("##HotKeyAndCommandsIntro")
                imgui.TextColoredRGB("{AAAAAA}В данном разделе можно узнать существующие команды скрипта и \n{AAAAAA}установить горячие клавиши.")
            imgui.EndChild()
            imgui.SetCursorPos(Scale.vec(10, 45))
            imgui.BeginChild("##Commands")
                imgui.TextColoredRGB("{F4CBC6}Доступные команды: ")
                for _, command in pairs(constants.SCRIPT_COMMANDS) do imgui.TextColoredRGB(command) end
            imgui.EndChild()
            imgui.SetCursorPos(Scale.vec(10, 218))
            imgui.BeginChild("##HotKeysTitle")
                imgui.TextColoredRGB("{F4CBC6}Доступные горячие клавиши: ")
            imgui.EndChild()
            imgui.SetCursorPos(Scale.vec(190, 240))
            imgui.BeginChild("##HotKeysButtons")
                for index, hotkey in ipairs(hotkeys) do
                    local caption = hotkey.buttonText ~= "" and hotkey.buttonText or "Не назначено"
                    local text = string.format("%s##%d", u8(caption), index)
                    if imgui.Button(text, Scale.vec(250, 25)) then
                        hotKeysManager.changed = false
                        hotKeysManager.menu = self
                        hotKeysManager.previousHotKey = { index, hotkey }
                        self.deactivate()
                        hotKeysManager.activate()
                    end
                end
            imgui.EndChild()
            imgui.SetCursorPos(Scale.vec(10, 240))
            imgui.BeginChild("##HotKeysTexts", Scale.vec(180, 190))
                for _, hotkey in ipairs(hotkeys) do
                    local x, y = table.unpack(hotkey.position)
                    imgui.SetCursorPosY(Scale.px(y))
                    imgui.Text(u8(hotkey.text))
                end
            imgui.EndChild()
        end

        local function drawContracts()
            local filtersDrawn = false
            if imgui.BeginTabBar("Contract Tabs") then
                if imgui.BeginTabItem(u8"Сортировка") then
                    imgui.Columns(2)
                    imgui.CenterColumnText(u8'Место') imgui.SetColumnWidth(-1, Scale.px(370))
                    imgui.NextColumn()
                    imgui.CenterColumnText(u8'Сорт.')
                    imgui.Columns(1)
                    imgui.Separator()
                    local pendingMove
                    for _, data in ipairs(pointsService.get()) do
                        imgui.Separator()
                        imgui.Columns(2)
                        imgui.BeginGroup()
                        imgui.Button("##MoveRoute" .. data.id, Scale.vec(20, 22))
                        local first, last = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                        local draw = imgui.GetWindowDrawList()
                        local handleColor = imgui.ColorConvertFloat4ToU32(Theme.color("muted"))
                        for line = -1, 1 do
                            local y = (first.y + last.y) / 2 + Scale.px(line * 3)
                            draw:AddLine(imgui.ImVec2(first.x + Scale.px(5), y),
                                imgui.ImVec2(last.x - Scale.px(5), y), handleColor, Scale.px(1))
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8"Зажмите и перетащите маршрут на нужное место в списке.")
                        end
                        if imgui.BeginDragDropSource() then
                            local payload = ffi.new("int[1]", data.id)
                            imgui.SetDragDropPayload("TCH_ROUTE_ORDER", payload, ffi.sizeof(payload))
                            imgui.Text(u8(data.point.source .. " -> " .. data.point.destination))
                            imgui.EndDragDropSource()
                        end
                        imgui.SameLine()
                        if imgui.Button("##TopRoute" .. data.id, Scale.vec(20, 22)) then
                            local selected = not data.point.top
                            if Window.reportSave(pointsService.update(data.id, { top = selected })) then
                                data.point.top = selected
                            end
                        end
                        local starMin = imgui.GetItemRectMin()
                        ContractIcons.star(imgui.ImVec2(starMin.x + Scale.px(2), starMin.y), Scale.px(22), data.point.top)
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8(data.point.top and "Убрать маршрут из приоритетных." or "Сделать маршрут приоритетным."))
                        end
                        imgui.SameLine()
                        imgui.Text(u8(data.point.source .. " -> " .. data.point.destination))
                        imgui.EndGroup()
                        local rowMin, rowMax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                        if imgui.BeginDragDropTarget() then
                            local payload = imgui.AcceptDragDropPayload("TCH_ROUTE_ORDER",
                                imgui.DragDropFlags.AcceptBeforeDelivery + imgui.DragDropFlags.AcceptNoDrawDefaultRect)
                            if payload ~= nil and payload.DataSize == ffi.sizeof("int") then
                                local sourceId = tonumber(ffi.cast("int*", payload.Data)[0])
                                if sourceId ~= data.id then
                                    local after = imgui.GetMousePos().y >= (rowMin.y + rowMax.y) / 2
                                    local y = after and rowMax.y or rowMin.y
                                    draw:AddLine(imgui.ImVec2(rowMin.x, y), imgui.ImVec2(rowMax.x, y),
                                        imgui.ColorConvertFloat4ToU32(Theme.color("accent")), Scale.px(2))
                                    if payload.Delivery then pendingMove = { sourceId, data.id, after } end
                                end
                            end
                            imgui.EndDragDropTarget()
                        end
                        imgui.NextColumn()
                        imgui.Spacing()
                        imgui.CenterColumnText(tostring(data.point.sort))
                        imgui.Columns(1)
                    end
                    if pendingMove then Window.reportSave(pointsService.move(unpack(pendingMove))) end
                    contractsContentHeight = (imgui.GetCursorPosY() + Scale.px(12)) / Scale.factor()
                    imgui.EndTabItem()
                end
                if imgui.BeginTabItem(u8("Фильтрация")) then
                    filtersDrawn = true
                    local filters = Filters.new()
                    local changed = false
                    if not pendingMinTons then minTonsQuantity[0] = filters.data.minTonsQuantity end
                    imgui.Text(u8("Компании"))
                    imgui.PushItemWidth(Scale.width(-1))
                    if imgui.InputText("##company", company, ffi.sizeof(company)) then
                        filters.data.company = u8:decode(ffi.string(company):lower())
                        changed = true
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip(u8"Оставьте поле пустым, чтобы показывать все компании.\nНесколько названий разделяйте запятыми.\nРусские названия должны совпадать с серверными, включая регистр.")
                    end
                    imgui.PopItemWidth()
                    imgui.TextColoredRGB("{AAAAAA}Например: dealers, kontora")
                    imgui.Spacing()
                    imgui.Text(u8("Остаток груза, т"))
                    imgui.SameLine()
                    imgui.PushItemWidth(Scale.px(140))
                    if imgui.InputInt("##tonsQuantity", minTonsQuantity, 1, 10) then
                        minTonsQuantity[0] = math.max(constants.MIN_TONS_QUANTITY,
                            math.min(constants.MAX_TONS_QUANTITY, minTonsQuantity[0]))
                        pendingMinTons = true
                    end
                    imgui.PopItemWidth()
                    imgui.TextColoredRGB("{AAAAAA}Показывать контракты с остатком больше указанного.")
                    if imgui.Checkbox(u8("Приоритетные — независимо от фильтров"), imgui.new.bool(filters.data.top)) then
                        filters.data.top = not filters.data.top
                        changed = true
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip(u8"Маршруты с золотой звездой показываются независимо\nот компании, остатка груза и галочек в таблицах ниже.")
                    end
                    imgui.Spacing()
                    if imgui.Button(u8("Включить все##Routes")) then
                        for _, source in ipairs(filters.data.sources) do
                            for _, destination in ipairs(source.destinations) do destination.hidden = false end
                        end
                        for _, destination in ipairs(filters.data.destinations) do destination.hidden = false end
                        changed = true
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Выключить все##Routes")) then
                        for _, source in ipairs(filters.data.sources) do
                            for _, destination in ipairs(source.destinations) do destination.hidden = true end
                        end
                        for _, destination in ipairs(filters.data.destinations) do destination.hidden = true end
                        changed = true
                    end
                    local groups = {}
                    for index, source in ipairs(filters.data.sources) do
                        -- Group by actual destinations, preserving saved row indices and flags.
                        local key = source.destinations[1].name .. "|" .. source.destinations[2].name
                        local group
                        for _, item in ipairs(groups) do if item.key == key then group = item; break end end
                        if not group then
                            group = { key = key, rows = {}, destinations = source.destinations }
                            groups[#groups + 1] = group
                        end
                        group.rows[#group.rows + 1] = { index = index, source = source }
                    end
                    for groupIndex, group in ipairs(groups) do
                        imgui.Spacing()
                        imgui.Separator()
                        imgui.Columns(3, "FilterRoutes" .. groupIndex, false)
                        imgui.SetColumnWidth(0, Scale.px(225))
                        imgui.SetColumnWidth(1, Scale.px(100))
                        imgui.Text(u8("Точка загрузки"))
                        imgui.NextColumn()
                        for column, destination in ipairs(group.destinations) do
                            local allEnabled = true
                            for _, row in ipairs(group.rows) do
                                if row.source.destinations[column].hidden then allEnabled = false; break end
                            end
                            local name = destination.short_name:gsub("Нефтезавод", "НПЗ")
                            if imgui.Checkbox(u8(name .. "##All" .. groupIndex .. "_" .. column), imgui.new.bool(allEnabled)) then
                                for _, row in ipairs(group.rows) do
                                    row.source.destinations[column].hidden = allEnabled
                                end
                                -- Retain the existing summary fields for port filters.
                                for _, summary in ipairs(filters.data.destinations) do
                                    if summary.name == destination.short_name then summary.hidden = allEnabled end
                                end
                                changed = true
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8("Включить или выключить все маршруты в " .. destination.name .. " в этой таблице."))
                            end
                            imgui.NextColumn()
                        end
                        imgui.Columns(1)
                        imgui.Separator()
                        for _, row in ipairs(group.rows) do
                            imgui.Columns(3, "FilterRoutes" .. groupIndex, false)
                            imgui.Text(u8(row.source.name))
                            imgui.NextColumn()
                            for column, destination in ipairs(row.source.destinations) do
                                if imgui.Checkbox("##RouteFilter" .. row.index .. "_" .. column, imgui.new.bool(not destination.hidden)) then
                                    destination.hidden = not destination.hidden
                                    changed = true
                                end
                                imgui.NextColumn()
                            end
                            imgui.Columns(1)
                        end
                    end
                    if changed and not Window.reportSave(filters.save()) then
                        filters = Filters.new()
                        ffi.fill(company, ffi.sizeof(company))
                        ffi.copy(company, u8(filters.data.company):sub(1, ffi.sizeof(company) - 1))
                    end
                    if not imgui.IsAnyItemActive() and not imgui.IsMouseDown(0) then saveMinTons(filters) end
                    contractsContentHeight = (imgui.GetCursorPosY() + Scale.px(12)) / Scale.factor()
                    imgui.EndTabItem()
                end
                imgui.EndTabBar()
            end
            return filtersDrawn
        end

        local function drawStatistics()
            if imgui.BeginTabBar("Statistics") then
                if imgui.BeginTabItem(u8("Параметры отображения")) then
                    statisticsDisplayActive = true
                    imgui.TextColored(Theme.color("accent"), u8("Показатели нижней панели"))
                    imgui.Spacing()
                    imgui.Text(u8("Положение панели"))
                    for index, label in ipairs(infoAlignmentLabels) do
                        if index > 1 then imgui.SameLine() end
                        local selected = selectedInfoAlignment[0] == index - 1
                        if selected then imgui.PushStyleColor(imgui.Col.Button, Theme.color("active")) end
                        if imgui.Button(label .. "##PanelAlignment" .. index, Scale.vec(135, 26)) then
                            if saveSetting("infoPanelAlignment", index - 1) then selectedInfoAlignment[0] = index - 1 end
                        end
                        if selected then imgui.PopStyleColor(1) end
                    end
                    imgui.Spacing()
                    imgui.Separator()
                    local statistics = Statistics.new()
                    local visible = {}
                    local function checkbox(code, label)
                        for _, item in ipairs(statistics.data) do
                            if item.code == code then
                                if imgui.Checkbox(u8(label .. "##PanelField" .. code), imgui.new.bool(item.show)) then
                                    local previous = item.show
                                    item.show = not previous
                                    if not Window.reportSave(statistics.save()) then item.show = previous end
                                end
                                visible[code] = item.show
                                return
                            end
                        end
                    end
                    imgui.Columns(2, "PanelFieldGroups", false)
                    imgui.TextColored(Theme.color("accent"), u8("Рейс и таймеры"))
                    checkbox("race", "Текущий маршрут")
                    checkbox("race-time", "Время в рейсе")
                    checkbox("illegal-cargo-time", "Таймер нелегалки")
                    imgui.NextColumn()
                    imgui.TextColored(Theme.color("accent"), u8("Статистика сессии"))
                    checkbox("session-earnings", "Заработано за сессию")
                    checkbox("session-races", "Рейсов за сессию")
                    checkbox("session-experience", "Опыт за сессию")
                    imgui.Columns(1)
                    imgui.Spacing()
                    imgui.TextColored(Theme.color("accent"), u8("Общие показатели"))
                    checkbox("total-earnings", "Общий заработок")
                    checkbox("experience-to-level", "Опыт до следующего уровня")
                    imgui.Spacing()
                    imgui.Separator()
                    imgui.TextColored(Theme.color("muted"), u8("Предпросмотр — текущие значения"))
                    local width = imgui.GetContentRegionAvail().x
                    local padding, gap = Scale.px(8), Scale.px(14)
                    local lineHeight = imgui.GetTextLineHeight() + Scale.px(6)
                    local items, x, row, usedWidth = {}, 0, 0, 0
                    for _, entry in ipairs(InfoPanel.previewEntries()) do
                        if visible[entry.code] then
                            local label = entry.label ~= "" and entry.label .. " " or ""
                            local labelWidth = imgui.CalcTextSize(u8(label)).x
                            local itemWidth = labelWidth + imgui.CalcTextSize(u8(entry.value)).x + Scale.px(2)
                            if x > 0 and x + itemWidth > width - padding * 2 then x, row = 0, row + 1 end
                            items[#items + 1] = { x = x, row = row, label = label, labelWidth = labelWidth,
                                value = entry.value, role = entry.role }
                            usedWidth = math.max(usedWidth, x + itemWidth)
                            x = x + itemWidth + gap
                        end
                    end
                    if #items == 0 then
                        imgui.TextColored(Theme.color("muted"), u8("Выберите хотя бы один показатель."))
                    else
                        local height = (row + 1) * lineHeight + padding * 2 - Scale.px(6)
                        local start = imgui.GetCursorScreenPos()
                        local draw = imgui.GetWindowDrawList()
                        draw:AddRectFilled(start, imgui.ImVec2(start.x + width, start.y + height),
                            imgui.ColorConvertFloat4ToU32(Theme.color("surface")), Scale.px(3))
                        local offset = selectedInfoAlignment[0] == 1 and 0.5 or (selectedInfoAlignment[0] == 2 and 1 or 0)
                        local inset = math.max(0, width - padding * 2 - usedWidth) * offset
                        for _, item in ipairs(items) do
                            local ix, iy = start.x + padding + inset + item.x, start.y + padding + item.row * lineHeight
                            draw:AddText(imgui.ImVec2(ix, iy), imgui.ColorConvertFloat4ToU32(Theme.color("muted")), u8(item.label))
                            draw:AddText(imgui.ImVec2(ix + item.labelWidth, iy), imgui.ColorConvertFloat4ToU32(Theme.color(item.role)), u8(item.value))
                        end
                        imgui.Dummy(imgui.ImVec2(width, height))
                    end
                    statisticsContentHeight = (imgui.GetCursorPosY() + Scale.px(12)) / Scale.factor()
                    imgui.EndTabItem()
                end
                if imgui.BeginTabItem(u8("Доходы / Расходы")) then
                    statisticsDisplayActive = false
                    imgui.TextColoredRGB("{AAAAAA}В общий заработок входят только включённые статьи.")
                    imgui.Spacing()
                    local profitAndLoss = ProfitAndLoss.new()
                    local function money(sum)
                        return (sum < 0 and "-" or "") .. Number.new(math.abs(sum)).format(0, "", "") .. "$"
                    end
                    local function sumColor(item)
                        return Theme.color(not item.enabled and "muted" or (item.sum < 0 and "error" or "success"))
                    end
                    local headingX = imgui.GetCursorPosX()
                    local headingWidth = imgui.GetContentRegionAvail().x - imgui.GetStyle().ScrollbarSize
                    imgui.SetCursorPosX(headingX + Scale.px(66))
                    imgui.Text(u8("Статья"))
                    imgui.SameLine()
                    imgui.SetCursorPosX(headingX + headingWidth - Scale.px(6) - imgui.CalcTextSize(u8("Сумма")).x)
                    imgui.Text(u8("Сумма"))
                    imgui.Separator()
                    local listHeight = math.max(Scale.px(60), imgui.GetContentRegionAvail().y - Scale.px(40))
                    imgui.BeginChild("##StatisticsPlRows", imgui.ImVec2(0, listHeight), false,
                        imgui.WindowFlags.AlwaysVerticalScrollbar)
                    local rowHeight = math.max(Scale.px(28), imgui.GetFrameHeight() + Scale.px(4))
                    for index, item in ipairs(profitAndLoss.data) do
                        local x, y = imgui.GetCursorPosX(), imgui.GetCursorPosY()
                        local width = imgui.GetContentRegionAvail().x
                        local screen = imgui.GetCursorScreenPos()
                        local draw = imgui.GetWindowDrawList()
                        if index % 2 == 0 then
                            draw:AddRectFilled(screen, imgui.ImVec2(screen.x + width, screen.y + rowHeight),
                                imgui.ColorConvertFloat4ToU32(Theme.color("surface", 0.45)))
                        end
                        if imgui.Checkbox("##EnableProfit" .. index, imgui.new.bool(item.enabled)) then
                            local previous = item.enabled
                            item.enabled = not previous
                            if not Window.reportSave(profitAndLoss.save()) then item.enabled = previous end
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8(item.enabled and "Не учитывать эту статью в общем заработке." or "Учитывать эту статью в общем заработке."))
                        end
                        imgui.SetCursorPos(imgui.ImVec2(x + Scale.px(66), y + Scale.px(4)))
                        imgui.TextColored(Theme.color(item.enabled and "text" or "muted"), u8(item.name))
                        local value = money(item.sum)
                        local valueWidth = imgui.CalcTextSize(value).x
                        imgui.SetCursorPos(imgui.ImVec2(x + width - Scale.px(6) - valueWidth, y + Scale.px(4)))
                        imgui.TextColored(sumColor(item), value)
                        imgui.SetCursorPos(imgui.ImVec2(x + Scale.px(32), y))
                        if imgui.Button("##ResetProfit" .. index, Scale.vec(24, 24)) then
                            resetProfitEntry = item.name
                            imgui.OpenPopup("##ConfirmProfitReset")
                        end
                        local first, last = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                        local cx, cy = (first.x + last.x) / 2, (first.y + last.y) / 2
                        local iconColor = imgui.ColorConvertFloat4ToU32(Theme.color("muted"))
                        local radius = Scale.px(6)
                        local previous
                        for step = 0, 16 do
                            local angle = -math.pi / 3 + step * math.pi * 1.65 / 16
                            local point = imgui.ImVec2(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius)
                            if previous then draw:AddLine(previous, point, iconColor, Scale.px(1.4)) end
                            previous = point
                        end
                        draw:AddTriangleFilled(imgui.ImVec2(cx + Scale.px(2), cy - Scale.px(7)),
                            imgui.ImVec2(cx + Scale.px(7), cy - Scale.px(7)),
                            imgui.ImVec2(cx + Scale.px(5), cy - Scale.px(2)), iconColor)
                        if imgui.IsItemHovered() then imgui.SetTooltip(u8("Обнулить сумму: " .. item.name)) end
                        imgui.SetCursorPos(imgui.ImVec2(x, y + rowHeight))
                        imgui.Dummy(imgui.ImVec2(width, 0))
                    end
                    if imgui.BeginPopupModal("##ConfirmProfitReset", nil, imgui.WindowFlags.AlwaysAutoResize) then
                        imgui.Text(u8("Обнулить сумму статьи?"))
                        imgui.TextColored(Theme.color("accent"), u8(resetProfitEntry or ""))
                        imgui.Text(u8("Текущая сумма будет сброшена до нуля."))
                        if imgui.Button(u8("Обнулить"), Scale.vec(110, 0)) then
                            -- Read again so confirmation cannot overwrite newer game earnings.
                            local latest = ProfitAndLoss.new()
                            local match = latest.getByName(resetProfitEntry)
                            if match then
                                local entry = match[2]
                                local previous = entry.sum
                                entry.sum = 0
                                if Window.reportSave(latest.save()) then
                                    profitAndLoss = latest
                                    resetProfitEntry = nil
                                    imgui.CloseCurrentPopup()
                                else
                                    entry.sum = previous
                                end
                            else
                                resetProfitEntry = nil
                                imgui.CloseCurrentPopup()
                            end
                        end
                        imgui.SameLine()
                        if imgui.Button(u8("Отмена"), Scale.vec(110, 0)) then
                            resetProfitEntry = nil
                            imgui.CloseCurrentPopup()
                        end
                        imgui.EndPopup()
                    end
                    imgui.EndChild()
                    imgui.Separator()
                    imgui.Text(u8("Итого"))
                    imgui.SameLine()
                    local total = profitAndLoss.sumEnabled()
                    local formatted = money(total)
                    imgui.SetCursorPosX(imgui.GetWindowWidth() - Scale.px(12) - imgui.CalcTextSize(formatted).x)
                    imgui.TextColored(Theme.color(total < 0 and "error" or "success"), formatted)
                    imgui.EndTabItem()
                end
                imgui.EndTabBar()
            end
        end

        local drawTab = { drawGeneralSettings, drawHotkeys, drawContracts, drawStatistics }

        imgui.OnFrame(
            function()
                if not self.window[0] then
                    saveCamera()
                    saveMinTons()
                end
                return self.window[0]
            end,
            function(player)
                local filtersDrawn = false
                RedTheme.new()
                local height = 520
                if active == 1 then
                    height = math.max(420, (generalContentHeight or 450) + 40)
                elseif active == 4 and statisticsDisplayActive then
                    height = math.max(360, (statisticsContentHeight or 380) + 40)
                elseif active == 3 then
                    local contentHeight = contractsContentHeight
                        or (constants.MAX_CONTRACTS_SIZE * 34 + 105)
                    height = math.max(height, contentHeight + 40)
                end
                local size = Scale.windowSize(620, height)
                local scale = Scale.percent()
                if lastScale ~= scale or lastWindowHeight ~= size.y then
                    local screenX, screenY = getScreenResolution()
                    position = imgui.ImVec2(screenX / 2, screenY / 2)
                    imgui.SetNextWindowPos(position, imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
                end
                lastScale = scale
                lastWindowHeight = size.y
                imgui.SetNextWindowSize(size, imgui.Cond.Always)
                imgui.Begin(self.title, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.HorizontalScrollbar)
                imgui.BeginChild("##Buttons", imgui.ImVec2(Scale.px(150), math.max(100, size.y - Scale.px(40))), true)
                    for index, name in ipairs(tabs) do
                        if Navigation.button(index, u8(name), active == index) then active = index end
                    end
                imgui.EndChild()
                imgui.SetCursorPos(Scale.vec(160, 28))
                local remainingHeight = math.max(100, imgui.GetWindowHeight() - Scale.px(40))
                if imgui.BeginChild('##Main' .. active, imgui.ImVec2(Scale.px(453), remainingHeight), true) then
                    filtersDrawn = drawTab[active]()
                end
                imgui.EndChild()
                if active ~= 1 or (not imgui.IsAnyItemActive() and not imgui.IsMouseDown(0)) then
                    saveCamera()
                end
                if not filtersDrawn then saveMinTons() end
                imgui.End()
                if pendingScale then
                    if not saveSetting("uiScale", pendingScale) then selectedScale[0] = scaleIndex end
                    scaleIndex = selectedScale[0]
                    pendingScale = nil
                end
            end
        )
        return self
    end
}

return Settings