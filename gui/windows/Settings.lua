local imgui = require "mimgui"
local encoding = require "encoding"
local Config = require "tch.common.config"
local Window = require "tch.gui.windows.window"
local constants = require "tch.constants"
local PointsService = require "tch.services.pointsservice"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()
local pointsService = PointsService.new()

local Settings = {
    new = function()
        local self = Window.new()
        self.title = u8("��������� � ��������")

        local resX, resY = getScreenResolution()
        local windowPosition = imgui.ImVec2(resX / 2, resY / 2)
        local size = imgui.ImVec2(600, 450)

        local active = 1
        local tabs = {
            "��������", 
            "���������", 
            "�������������� �\n       ��������"
        }

        local clists = imgui.new['const char*'][#constants.COLOR_LIST](constants.COLOR_LIST)
        local selectedClist = imgui.new.int(config.data.settings.clistChoice)

        local truckRentedChoices = imgui.new['const char*'][#constants.TRUCK_RENTED_CHOICES](constants.TRUCK_RENTED_CHOICES)
        local selectedTruckRentedChoice = imgui.new.int(config.data.settings.truckRentedChoice)

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
                imgui.SetNextWindowPos(
                    windowPosition, 
                    imgui.Cond.FirstUseEver, 
                    imgui.ImVec2(0.5, 0.5)
                )
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
                imgui.Begin(self.title, self.window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
                for index, name in pairs(tabs) do
                    if imgui.Button(u8(name), imgui.ImVec2(150, 40)) then
                        active = index
                    end
                end
                imgui.SetCursorPos(imgui.ImVec2(160, 28))
                if imgui.BeginChild('##Main' .. active, imgui.ImVec2(435, 410), true) then
                    if active == 1 then
                        imgui.BeginChild('##ClistChild', imgui.ImVec2(260, 400), false)
                            imgui.Text(u8"���� ���� �� ����� ������:")
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
                        imgui.SetCursorPos(imgui.ImVec2(180, 5))
                        imgui.BeginChild('##ContractsChild', imgui.ImVec2(385, 400), false)
                            imgui.Text(u8"��������� ���� ����������, ����:")
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
                        imgui.SetCursorPos(imgui.ImVec2(179, 55))
                        imgui.BeginChild('##DocumentsChild', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" �������� ���� ���������� �� ����"), imgui.new.bool(config.data.settings.documentsDialogue)) then
                                config.data.settings.documentsDialogue = not config.data.settings.documentsDialogue
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"�������� ����������� ���� ���������� \n����� ������� ������.")
                            end
                        imgui.EndChild()
                        imgui.SetCursorPos(imgui.ImVec2(179, 85))
                        imgui.BeginChild('##Drift', imgui.ImVec2(250, 100), false)
                            if imgui.Checkbox(u8(" ���������� ������������ (drift)"), imgui.new.bool(config.data.settings.drift)) then
                                config.data.settings.drift = not config.data.settings.drift
                                config.save()
                            end
                            if imgui.IsItemHovered() then
                                imgui.SetTooltip(u8"��� ������� ������� \"Shift\" ������� ������ \n������ ������ �������, ��� ������.")
                            end
                        imgui.EndChild()
                    end
                    if active == 2 then
                        imgui.Columns(4)
                        imgui.CenterColumnText(u8'�����') imgui.SetColumnWidth(-1, 240)
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
                            if imgui.Button(u8"up##" .. data.id) then
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
                            imgui.SameLine()
                            if imgui.Button(u8"dwn##" .. data.id) then
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
                            imgui.SameLine()
                            if imgui.Button(u8"top##" .. data.id) then
                                pointsService.update(data.id, { top = not data.point.top })
                            end
                            imgui.Columns(1)
                            imgui.Separator()
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