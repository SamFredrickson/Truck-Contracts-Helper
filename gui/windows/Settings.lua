local imgui = require "mimgui"
local ffi = require 'ffi'
local encoding = require "encoding"
local Config = require "tch.common.config"
local Statistics = require "tch.common.storage.statistics"
local Filters = require "tch.common.storage.filters"
local Hotkeys = require "tch.common.storage.hotkeys"
local Window = require "tch.gui.windows.window"
local HotKeysManager = require "tch.gui.windows.hotkeysmanager"
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

local hotKeys = Hotkeys.new()
local hotKeysManager = HotKeysManager.new()
local pointsService = PointsService.new()
local driverCoordinatesService = DriverCoordinatesEntryService.new()
local chatService = ChatService.new()
local filters = Filters.new()

local Settings = {
    new = function()
        local self = Window.new()
        self.title = u8(
            string.format(
                "������� ���� (v%s)", 
                constants.SCRIPT_INFO.VERSION
            )
        )

        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(screenX / 2, screenY / 2)
        local size = imgui.ImVec2(620, 450)

        local active = 1
        local tabs = {
            "��������",
            "������� � ������� \n         �������",
            "���������",
            "����������",
            "�������������� �\n       ��������"
        }

        local clists = imgui.new['const char*'][#constants.COLOR_LIST](constants.COLOR_LIST)
        local selectedClist = imgui.new.int(config.data.settings.clistChoice)
        local scriptStatuses = imgui.new['const char*'][#constants.SCRIPT_STATUSES](constants.SCRIPT_STATUSES)
        self.selectedScriptStatus = imgui.new.int(config.data.settings.selectedScriptStatus)
        local autorepairPrice = imgui.new.int(config.data.settings.repairPrice)
        local autorefillPrice = imgui.new.int(config.data.settings.refillPrice)
        local hotPrice = imgui.new.int(config.data.settings.hotPrice)
        local company = imgui.new.char[256](u8(filters.data.company))
        local minTonsQuantity = imgui.new.int(filters.data.minTonsQuantity)
        local linesWidth = imgui.new.int(config.data.settings.linesWidth)

        local convertedToFloat4 = imgui.ColorConvertU32ToFloat4(config.data.settings.linesColor)
        local color = imgui.new.float[4](convertedToFloat4.x, convertedToFloat4.y, convertedToFloat4.z, convertedToFloat4.w)

        local isAnyItemActive = false
        local isAnyItemActiveMoreOneSecond = false
        local currentTime = nil

        -- ������� ����� ��� �������� �� ������� ������ ����� ��� ������ � ������� ���� ������
        -- ����� �������� �������� ��� ��������� ������� ������� ����.
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
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
                imgui.Begin(self.title, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
                imgui.BeginChild("##Buttons", imgui.ImVec2(150, 410), true)
                    for index, name in pairs(tabs) do
                       if active == index then
                            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.90, 0.26, 0.26, 1.00))
                            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
                            if imgui.Button(u8(name), imgui.ImVec2(140, 45)) then
                                active = index
                            end
                            imgui.PopStyleVar()
                            imgui.PopStyleColor(1)
                       end
                       if active ~= index then
                            imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 6)
                            if imgui.Button(u8(name), imgui.ImVec2(140, 45)) then
                                active = index
                            end
                            imgui.PopStyleVar()
                       end
                    end
                imgui.EndChild()
                imgui.SetCursorPos(imgui.ImVec2(160, 28))
                if imgui.BeginChild('##Main' .. active, imgui.ImVec2(453, 410), true) then
                    if active == 1 then
                        imgui.BeginChild('##ClistChild', imgui.ImVec2(275, 400), false)
                            imgui.Text(u8"���� ���� �� ����� ������:")
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
                            imgui.Text(u8"������ ������ �������:")
                            if imgui.Combo
                            (
                                "##ScriptStatus", 
                                self.selectedScriptStatus, 
                                scriptStatuses, 
                                #constants.SCRIPT_STATUSES
                            ) then
                                config.data.settings.selectedScriptStatus = self.selectedScriptStatus[0]
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"� ������� ������� ������ ����� �������� / ��������� ������� �������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 55))
                        imgui.BeginChild('##UnloadChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ������������� ����"), imgui.new.bool(config.data.settings.autounload)) then
                                config.data.settings.autounload = not config.data.settings.autounload
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������������� ���������� ����� \n��� �������� � ���� �� ������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 85))
                        imgui.BeginChild('##LockUnlockChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ������������ ����"), imgui.new.bool(config.data.settings.autolock)) then
                                config.data.settings.autolock = not config.data.settings.autolock
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                               imgui.SetTooltip(u8"������������� ��������� ����, \n���� ��������� ��� � ���.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 55))
                        imgui.BeginChild('##DocumentsChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" �������� ���� ���������� �� ����"), imgui.new.bool(config.data.settings.documentsDialogue)) then
                                config.data.settings.documentsDialogue = not config.data.settings.documentsDialogue
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"�������� ���� � ����������� � ������ ����� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 85))
                        imgui.BeginChild('##Drift', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ���������� ������������� (drift)"), imgui.new.bool(config.data.settings.drift)) then
                                config.data.settings.drift = not config.data.settings.drift
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"��� ������� ������� \"Shift\" ������� ������ \n������ ������ �������, ��� ������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 115))
                        imgui.BeginChild('##AutohideContractsList', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ������������ ������"), imgui.new.bool(config.data.settings.autohideContractsList)) then
                                config.data.settings.autohideContractsList = not config.data.settings.autohideContractsList
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������� ������ ����������, \n���� ���� �������� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 115))
                        imgui.BeginChild('##Autoload', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ������������ ����"), imgui.new.bool(config.data.settings.autoload)) then
                                config.data.settings.autoload = not config.data.settings.autoload
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������������� ����� ����� �������� \n�������� � �������� ���� �� ����� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 145))
                        imgui.BeginChild('##Statistics', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ���������� ���������"), imgui.new.bool(config.data.settings.statistics)) then
                                config.data.settings.statistics = not config.data.settings.statistics
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������������� ��������� ���� �� ����������� \n� ������ ����������� �� ����� ������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 145))
                        imgui.BeginChild('##TransparentContracts', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ���������� ���������"), imgui.new.bool(config.data.settings.transparentContracts)) then
                                config.data.settings.transparentContracts = not config.data.settings.transparentContracts
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������ ������ ���������� ���������� ��� ���������� ������� ����.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 175))
                        imgui.BeginChild('##TransparentCorpses', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ���������� �����"), imgui.new.bool(config.data.settings.transparentCorpses)) then
                                config.data.settings.transparentCorpses = not config.data.settings.transparentCorpses
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"��������� ������������ � ������� �� ������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 175))
                        imgui.BeginChild("##CameraLinesCheckbox", imgui.ImVec2(190, 100), false)
                            if imgui.Checkbox(u8(" ������������ ������"), imgui.new.bool(config.data.settings.cameraLines)) then
                                config.data.settings.cameraLines = not config.data.settings.cameraLines
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������������ ������� ����� ������� � ������������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 210))
                        imgui.BeginChild("##CameraLinesColorText")
                            imgui.Text(u8(" ���� �����"))
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 240))
                        imgui.BeginChild("##CameraLinesWidthText")
                            imgui.Text(u8(" ������ �����"))
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 205))
                        imgui.BeginChild("##CameraLinesColorEdit4")
                            imgui.PushItemWidth(250)
                            if imgui.ColorEdit4(u8("##color"), color) then
                                config.data.settings.linesColor = imgui.ColorConvertFloat4ToU32(
                                    imgui.ImVec4(color[0], color[1], color[2], color[3])
                                )
                                config.save()
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 235))
                        imgui.BeginChild("##�ameraLinesChild")
                            imgui.PushItemWidth(200)
                            if imgui.SliderInt
                            (
                                "##cameraLinesWidth", 
                                linesWidth, 
                                constants.CAMERA_LINES.MIN_WIDTH, 
                                constants.CAMERA_LINES.MAX_WIDTH
                            ) then
                                config.data.settings.linesWidth = linesWidth[0]
                                config.save()
                            end
                            imgui.PopItemWidth()
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(400, 235))
                        imgui.BeginChild("##CameraLinesButtons")
                            if imgui.Button("+ ##CameraLinesPlusButton", imgui.ImVec2(20, 0)) then
                                linesWidth[0] = (
                                    linesWidth[0] >= constants.CAMERA_LINES.MAX_WIDTH 
                                    and constants.CAMERA_LINES.MAX_WIDTH 
                                    or linesWidth[0] + 1
                                )
                                config.data.settings.linesWidth = linesWidth[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    linesWidth[0] = (
                                        linesWidth[0] >= constants.CAMERA_LINES.MAX_WIDTH 
                                        and constants.CAMERA_LINES.MAX_WIDTH 
                                        or linesWidth[0] + 1
                                    )
                                    config.data.settings.linesWidth = linesWidth[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ����������� \n��� �������������� ��������� ��������.")
                            end
                            imgui.SameLine()
                            if imgui.Button("- ##CameraLinesMinusButton", imgui.ImVec2(20, 0)) then
                                linesWidth[0] = (
                                    linesWidth[0] <= constants.CAMERA_LINES.MIN_WIDTH 
                                    and constants.CAMERA_LINES.MIN_WIDTH 
                                    or linesWidth[0] - 1
                                )
                                config.data.settings.linesWidth = linesWidth[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    linesWidth[0] = (
                                        linesWidth[0] <= constants.CAMERA_LINES.MIN_WIDTH 
                                        and constants.CAMERA_LINES.MIN_WIDTH 
                                        or linesWidth[0] - 1
                                    )
                                    config.data.settings.linesWidth = linesWidth[0]
                                    config.save()
                                end
                            end
                            if imgui.IsItemActivated() then
                                isAnyItemActiveMoreOneSecond = false
                                isAnyItemActive = false
                                currentTime = nil
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ��������� \n��� �������������� ��������� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 270))
                        imgui.BeginChild("##AutomechanicSuggestionsText")
                            imgui.Text(u8(" ��������� �����������"))
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"������������� ��������� ����������� �� ��������� ��� ���-�������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 265))
                        imgui.BeginChild("##AutomechanicSuggestions")
                            if imgui.Checkbox(u8(" �������"), imgui.new.bool(config.data.settings.autorepair)) then
                                config.data.settings.autorepair = not config.data.settings.autorepair
                                config.save()
                            end
                            imgui.SameLine()
                            if imgui.Checkbox(u8(" ��������"), imgui.new.bool(config.data.settings.autorefill)) then
                                config.data.settings.autorefill = not config.data.settings.autorefill
                                config.save()
                            end
                            imgui.SameLine()
                            if imgui.Checkbox(u8(" ����"), imgui.new.bool(config.data.settings.autoHotDog)) then
                                config.data.settings.autoHotDog = not config.data.settings.autoHotDog
                                config.save()
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 295))
                        imgui.BeginChild("##AutomechanicSuggestionsRepairConditionText")
                            imgui.TextColoredRGB(" ���� ���� �������")
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"���� ���� ������� ������ ���� ����� ���������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 295))
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
                        imgui.SetCursorPos(imgui.ImVec2(400, 295))
                        imgui.BeginChild("##AutomechanicSuggestionsRepairButtons")
                            if imgui.Button("+ ##AutomechanicSuggestionsRepairPlusButton", imgui.ImVec2(20, 0)) then
                                autorepairPrice[0] = (
                                    autorepairPrice[0] >= constants.MECHANIC.MAX_REPAIR_PRICE
                                    and constants.MECHANIC.MAX_REPAIR_PRICE
                                    or autorepairPrice[0] + 1
                                )
                                config.data.settings.repairPrice = autorepairPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorepairPrice[0] = (
                                        autorepairPrice[0] >= constants.MECHANIC.MAX_REPAIR_PRICE
                                        and constants.MECHANIC.MAX_REPAIR_PRICE
                                        or autorepairPrice[0] + 1
                                    )
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
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ����������� \n��� �������������� ��������� ��������.")
                            end
                            imgui.SameLine()
                            if imgui.Button("- ##AutomechanicSuggestionsRepairMinusButton", imgui.ImVec2(20, 0)) then
                                autorepairPrice[0] = (
                                    autorepairPrice[0] <= constants.MECHANIC.MIN_REPIAR_PRICE
                                    and constants.MECHANIC.MIN_REPIAR_PRICE
                                    or autorepairPrice[0] - 1
                                )
                                config.data.settings.repairPrice = autorepairPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorepairPrice[0] = (
                                        autorepairPrice[0] <= constants.MECHANIC.MIN_REPIAR_PRICE
                                        and constants.MECHANIC.MIN_REPIAR_PRICE
                                        or autorepairPrice[0] - 1
                                    )
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
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ��������� \n��� �������������� ��������� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 325))
                        imgui.BeginChild("##AutomechanicSuggestionsRefillConditionText")
                            imgui.TextColoredRGB(" ���� ���� ��������")
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"���� ���� �������� ������ ���� ����� ���������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 325))
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
                        imgui.SetCursorPos(imgui.ImVec2(400, 325))
                        imgui.BeginChild("##AutomechanicSuggestionsRefillButtons")
                            if imgui.Button("+ ##AutomechanicSuggestionsRefillPlusButton", imgui.ImVec2(20, 0)) then
                                autorefillPrice[0] = (
                                    autorefillPrice[0] >= constants.MECHANIC.MAX_REFILL_PRICE
                                    and constants.MECHANIC.MAX_REFILL_PRICE
                                    or autorefillPrice[0] + 1
                                )
                                config.data.settings.refillPrice = autorefillPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorefillPrice[0] = (
                                        autorefillPrice[0] >= constants.MECHANIC.MAX_REFILL_PRICE
                                        and constants.MECHANIC.MAX_REFILL_PRICE
                                        or autorefillPrice[0] + 1
                                    )
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
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ����������� \n��� �������������� ��������� ��������.")
                            end
                            imgui.SameLine()
                            if imgui.Button("- ##AutomechanicSuggestionsRefillMinusButton", imgui.ImVec2(20, 0)) then
                                autorefillPrice[0] = (
                                    autorefillPrice[0] <= constants.MECHANIC.MIN_REFILL_PRICE
                                    and constants.MECHANIC.MIN_REFILL_PRICE
                                    or autorefillPrice[0] - 1
                                )
                                config.data.settings.refillPrice = autorefillPrice[0]
                                config.save()
                            end
                            if imgui.IsItemActive() then
                                isAnyItemActive = true
                                if isAnyItemActiveMoreOneSecond then
                                    autorefillPrice[0] = (
                                        autorefillPrice[0] <= constants.MECHANIC.MIN_REFILL_PRICE
                                        and constants.MECHANIC.MIN_REFILL_PRICE
                                        or autorefillPrice[0] - 1
                                    )
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
                                imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ��������� \n��� �������������� ��������� ��������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(5, 355))
                        imgui.BeginChild("##AutoHotDoggerSuggestionText")
                            imgui.TextColoredRGB(" ���� ���� ���-����")
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"���� ���� ���-���� ������ ���� ����� ���������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(195, 355))
                        imgui.BeginChild("##AutoHotDoggerSuggestionPrice")
                        imgui.PushItemWidth(200)
                            if imgui.SliderInt
                            (
                                "##hotPrice", 
                                hotPrice, 
                                constants.HOTDOG.MIN_PRICE, 
                                constants.HOTDOG.MAX_PRICE
                            ) then
                                config.data.settings.hotPrice = hotPrice[0]
                                config.save()
                            end
                        imgui.PopItemWidth()
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(400, 355))
                        imgui.BeginChild("##AutoHotDoggerSuggestionButtons")
                        if imgui.Button("+ ##AutoHotDoggerPlusButton", imgui.ImVec2(20, 0)) then
                            hotPrice[0] = (
                                hotPrice[0] >= constants.HOTDOG.MAX_PRICE
                                and constants.HOTDOG.MAX_PRICE
                                or hotPrice[0] + 1
                            )
                            config.data.settings.hotPrice = hotPrice[0]
                            config.save()
                        end
                        if imgui.IsItemActive() then
                            isAnyItemActive = true
                            if isAnyItemActiveMoreOneSecond then
                                hotPrice[0] = (
                                    hotPrice[0] >= constants.HOTDOG.MAX_PRICE
                                    and constants.HOTDOG.MAX_PRICE
                                    or hotPrice[0] + 1
                                )
                                config.data.settings.hotPrice = hotPrice[0]
                                config.save()
                            end
                        end
                        if imgui.IsItemActivated() then
                            isAnyItemActiveMoreOneSecond = false
                            isAnyItemActive = false
                            currentTime = nil
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ����������� \n��� �������������� ��������� ��������.")
                        end
                        imgui.SameLine()
                        if imgui.Button("- ##AutoHotDoggerSuggestionMinusButton", imgui.ImVec2(20, 0)) then
                            hotPrice[0] = (
                                hotPrice[0] <= constants.HOTDOG.MIN_PRICE
                                and constants.HOTDOG.MIN_PRICE
                                or hotPrice[0] - 1
                            )
                            config.data.settings.hotPrice = hotPrice[0]
                            config.save()
                        end
                        if imgui.IsItemActive() then
                            isAnyItemActive = true
                            if isAnyItemActiveMoreOneSecond then
                                hotPrice[0] = (
                                    hotPrice[0] <= constants.HOTDOG.MIN_PRICE
                                    and constants.HOTDOG.MIN_PRICE
                                    or hotPrice[0] - 1
                                )
                                config.data.settings.hotPrice = hotPrice[0]
                                config.save()
                            end
                        end
                        if imgui.IsItemActivated() then
                            isAnyItemActiveMoreOneSecond = false
                            isAnyItemActive = false
                            currentTime = nil
                        end
                        if imgui.IsItemHovered() then
                            imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ��������� \n��� �������������� ��������� ��������.")
                        end
                    imgui.EndChild()
                    end
                    if active == 2 then
                        imgui.SetCursorPos(imgui.ImVec2(10, 5))
                        imgui.BeginChild("##HotKeyAndCommandsIntro")
                            imgui.TextColoredRGB("{AAAAAA}� ������ ������� ����� ������ ������������ ������� ������� � \n{AAAAAA}���������� ������� �������.")
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(10, 45))
                        imgui.BeginChild("##Commands")
                            imgui.TextColoredRGB("{F4CBC6}��������� �������: ")
                            for _, command in pairs(constants.SCRIPT_COMMANDS) do imgui.TextColoredRGB(command) end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(10, 218))
                        imgui.BeginChild("##HotKeysTitle")
                            imgui.TextColoredRGB("{F4CBC6}��������� ������� �������: ")
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(190, 240))
                        imgui.BeginChild("##HotKeysButtons")
                            for index, hotkey in pairs(Hotkeys.new().data) do
                                local text = string.format("%s##%d", u8(hotkey.buttonText), index)
                                if imgui.Button(text, imgui.ImVec2(250, 25)) then
                                    hotKeysManager.changed = false
                                    hotKeysManager.menu = self
                                    hotKeysManager.previousHotKey = { index, hotkey }
                                    self.deactivate()
                                    hotKeysManager.activate()
                                end
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(10, 240))
                        imgui.BeginChild("##HotKeysTexts", imgui.ImVec2(200, 150))
                            for _, hotkey in pairs(Hotkeys.new().data) do
                                local x, y = table.unpack(hotkey.position)
                                imgui.SetCursorPosY(y)
                                imgui.Text(u8(hotkey.text))
                            end
                        imgui.EndChild()
                    end
                    if active == 3 then
                        if imgui.BeginTabBar("Contract Tabs") then
                            if imgui.BeginTabItem(u8"����������") then
                                imgui.Columns(4)
                                imgui.CenterColumnText(u8'�����') imgui.SetColumnWidth(-1, 225)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'���') imgui.SetColumnWidth(-1, 40)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'����.') imgui.SetColumnWidth(-1, 40)
                                imgui.NextColumn()
                                imgui.CenterColumnText(u8'�����')
                                imgui.Columns(1)
                                imgui.Separator()
                                for index, data in pairs(pointsService.get()) do
                                    imgui.Columns(4)
                                    imgui.CenterColumnText(string.format("%s -> %s", u8(data.point.source), u8(data.point.destination)))
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8(data.point.top and "��" or "���"))
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(tostring(data.point.sort))
                                    imgui.NextColumn()
                                    if imgui.Button(u8"����##" .. data.id) then
                                        if data.point.sort > constants.MIN_CONTRACTS_SIZE then
                                                local previous = pointsService.findBySort(data.point.sort - 1)
                                                local current = data.point
                                                pointsService.update(data.id, { sort = previous.point.sort })
                                                pointsService.update(previous.id, { sort = current.sort })
                                            end
                                        end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"���������� ������ ���� �� ������.")
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(u8"����##" .. data.id) then
                                        if data.point.sort < constants.MAX_CONTRACTS_SIZE then
                                            local next = pointsService.findBySort(data.point.sort + 1)
                                            local current = data.point
                                            pointsService.update(data.id, { sort = next.point.sort })
                                            pointsService.update(next.id, { sort = current.sort })
                                        end
                                    end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"���������� ������ ���� �� ������.")
                                    end
                                    imgui.SameLine()
                                    if imgui.Button(u8"���##" .. data.id) then
                                        pointsService.update(data.id, { top = not data.point.top })
                                    end
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"������ / ������� ����� \"TOP\" � ������.")
                                    end
                                    imgui.Columns(1)
                                end
                                imgui.EndTabItem()
                            end
                            if imgui.BeginTabItem(u8("����������")) then
                                imgui.SetCursorPos(imgui.ImVec2(5, 40))
                                imgui.BeginChild("##CompanyName")
                                    imgui.Text(u8(" ������������ ��������:"))
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip
                                        (
                                            u8"���� ���� ���������, �� ���������� ������ �� ���������, ������� ����������� ��������� � ������ ��." ..
                                            u8"\n��� ����������� ���������� ����� ���������� �� ���������� ������� ������ �� �������� ����� �������: dealers, kontora." ..
                                            u8"\n�����: ���� �������� �� �� �������, �� ��� ������ �������� ��������� � ���, ��� � ������ ����������, ������� �������."
                                         )
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
                                    imgui.Text(u8(" ����������� ���-�� ����:"))
                                    if imgui.IsItemHovered() then
                                        imgui.SetTooltip(u8"�������� ��������� � ������� ������� \n������ ���� ����� ���������� ��������.")
                                    end
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 65))
                                imgui.BeginChild("##MinTonsQuantitySlider")
                                    imgui.PushItemWidth(220)
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
                                imgui.SetCursorPos(imgui.ImVec2(400, 65))
                                imgui.BeginChild("##MinTonsQuantityButtons")
                                if imgui.Button("+ ##MinTonsQuantityPlusButton", imgui.ImVec2(20, 0)) then
                                    minTonsQuantity[0] = (
                                        minTonsQuantity[0] >= constants.MAX_TONS_QUANTITY
                                        and constants.MAX_TONS_QUANTITY
                                        or minTonsQuantity[0] + 1
                                    )
                                    filters.data.minTonsQuantity = minTonsQuantity[0]
                                    filters.save()
                                end
                                if imgui.IsItemActive() then
                                    isAnyItemActive = true
                                    if isAnyItemActiveMoreOneSecond then
                                        minTonsQuantity[0] = (
                                            minTonsQuantity[0] >= constants.MAX_TONS_QUANTITY
                                            and constants.MAX_TONS_QUANTITY
                                            or minTonsQuantity[0] + 1
                                        )
                                        filters.data.minTonsQuantity = minTonsQuantity[0]
                                        filters.save()
                                    end
                                end
                                if imgui.IsItemActivated() then
                                    isAnyItemActiveMoreOneSecond = false
                                    isAnyItemActive = false
                                    currentTime = nil
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ����������� \n��� �������������� ��������� ��������.")
                                end
                                imgui.SameLine()
                                if imgui.Button("- ##MinTonsQuantityMinusButton", imgui.ImVec2(20, 0)) then
                                    minTonsQuantity[0] = (
                                        minTonsQuantity[0] <= constants.MIN_TONS_QUANTITY
                                        and constants.MIN_TONS_QUANTITY
                                        or minTonsQuantity[0] - 1
                                    )
                                    filters.data.minTonsQuantity = minTonsQuantity[0]
                                    filters.save()
                                end
                                if imgui.IsItemActive() then
                                    isAnyItemActive = true
                                    if isAnyItemActiveMoreOneSecond then
                                        minTonsQuantity[0] = (
                                        minTonsQuantity[0] <= constants.MIN_TONS_QUANTITY
                                            and constants.MIN_TONS_QUANTITY
                                            or minTonsQuantity[0] - 1
                                        )
                                        filters.data.minTonsQuantity = minTonsQuantity[0]
                                        filters.save()
                                    end
                                end
                                if imgui.IsItemActivated() then
                                    isAnyItemActiveMoreOneSecond = false
                                    isAnyItemActive = false
                                    currentTime = nil
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"����������� � ������� ���� ������, ����� �������� ��������� \n��� �������������� ��������� ��������.")
                                end
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(5, 115))
                                imgui.BeginChild("##OtherFiltersText")
                                    imgui.Text(u8(" ������� ��� ���� ������:"))
                                imgui.EndChild()
                                imgui.SetCursorPos(imgui.ImVec2(175, 96))
                                imgui.BeginChild('##AllowedDestinations')
                                if imgui.Checkbox(u8(" ���� ���-������ "), imgui.new.bool(not filters.data.destinations[1].hidden)) then
                                    filters.data.destinations[1].hidden = not filters.data.destinations[1].hidden
                                    for index, source in pairs(filters.data.sources) do
                                        filters.data.sources[index].destinations[1].hidden 
                                            = filters.data.destinations[1].hidden
                                    end
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"���������� ��������� � ���� ���-������.")
                                end
                                imgui.SameLine()
                                if imgui.Checkbox(u8(" ���� ���-������"), imgui.new.bool(not filters.data.destinations[2].hidden)) then
                                    filters.data.destinations[2].hidden = not filters.data.destinations[2].hidden
                                    for index, source in pairs(filters.data.sources) do
                                        filters.data.sources[index].destinations[2].hidden 
                                            = filters.data.destinations[2].hidden
                                    end
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"���������� ��������� � ���� ���-������.")
                                end
                                if imgui.Checkbox(u8(" ������ ���������� ������� (���.)"), imgui.new.bool(filters.data.top)) then
                                    filters.data.top = not filters.data.top
                                    filters.save()
                                end
                                if imgui.IsItemHovered() then
                                    imgui.SetTooltip(u8"������������ ��� ������� � ������ ����, \n���� �������� �������� ������� (TOP).")
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
                    if active == 4 then
                        imgui.Columns(2)
                        imgui.CenterColumnText(u8'��������') imgui.SetColumnWidth(-1, 285)
                        imgui.NextColumn()
                        imgui.CenterColumnText(u8'���������')
                        imgui.Columns(1)
                        imgui.Separator()
                        for index, item in pairs(Statistics.new().data) do
                            imgui.Columns(2)
                            imgui.CenterColumnText(u8(item.short_name)) 
                            imgui.NextColumn()
                            if imgui.Button(u8(item.hidden and "����������##" or "��������##") .. index, imgui.ImVec2(155, 0)) then
                                local statistics = Statistics.new()
                                statistics.data[index].hidden = not item.hidden
                                statistics.save()
                            end
                            imgui.Columns(1)
                        end
                    end
                    if active == 5 then
                       if imgui.BeginTabBar("Players Tab") then
                            if imgui.BeginTabItem(u8"����������") then
                                if #DriverCoordinatesEntryService.ENTRIES <= 0 then
                                    imgui.Text(u8"������ ��������� ����.")
                                end
                                if #DriverCoordinatesEntryService.ENTRIES > 0 then
                                    imgui.Columns(3)
                                    imgui.CenterColumnText(u8'�����������') imgui.SetColumnWidth(-1, 130)
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8'���������') imgui.SetColumnWidth(-1, #DriverCoordinatesEntryService.ENTRIES <= 12 and 226 or 218)
                                    imgui.NextColumn()
                                    imgui.CenterColumnText(u8'�����')
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
                                        if imgui.Button(u8"���.##" .. tostring(id)) then
                                            Sound.new("mark.wav", 80).play()
                                            removeBlip(entry.blip)
                                            entry.blip = addSpriteBlipForCoord(entry.x, entry.y, entry.z, 41)
                                            local localMessage = LocalMessage.new("����� ����������� �� �����", nil, constants.COLORS.GOLD)
                                            chatService.send(localMessage)
                                        end
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8"��������� ����� �� �����.")
                                        end
                                        imgui.SameLine()
                                        if imgui.Button(u8"����.##" .. tostring(id)) then
                                            removeBlip(entry.blip)
                                            driverCoordinatesService.delete(DriverCoordinatesEntryService.ENTRIES, id)
                                        end
                                        if imgui.IsItemHovered() then
                                            imgui.SetTooltip(u8"������� ������ � ����� �� �����.")
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