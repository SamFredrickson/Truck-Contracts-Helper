local imgui = require "mimgui"
local encoding = require "encoding"
local InfoEntry = require "tch.entities.infoentry"
local Information = require "tch.entities.information"
local Time = require "tch.entities.time"
local Number = require "tch.entities.number"
local Window = require "tch.gui.windows.window"
local InfoTheme = require "tch.gui.themes.info"
local constants = require "tch.constants"
local Config = require "tch.common.config"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local TWO_HOURS = 3600 * 2
local raceTime = Time.new(0).toString()
local illegalCargoAvailableAt = config.data.settings.lastIllegalCargoUnloadedAt + TWO_HOURS
local illegalCargoAvailableAtFormatted = Time.new(os.difftime(illegalCargoAvailableAt, os.time())).toString()
local sessionEarnings = Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}")
local totalEarnings = Number.new(config.data.settings.totalEarnings).format(0, "", "{F2545B}")
local sessionExperience = Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}")
local raceQuantity = config.data.settings.sessionRaceQuantity

local information = Information.new(
    InfoEntry.new("����:", "�"),
    InfoEntry.new("����� � �����:", raceTime),
    InfoEntry.new("����������� ���� �������� �����:", illegalCargoAvailableAtFormatted),
    InfoEntry.new("����� �� ������:", sessionExperience),
    InfoEntry.new("������ �� ������:", raceQuantity),
    InfoEntry.new("���������� �� ������:", sessionEarnings),
    InfoEntry.new("���������� �� �� �����:", totalEarnings)
)

local Info = {
    new = function()
        local self = Window.new()
        self.title = u8("����������")
        self.information = information

        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(-2, screenY - 25)
        local size = imgui.ImVec2(5000, 10)

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
                InfoTheme.new()
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
                imgui.Begin(
                    self.title, 
                    self.window, 
                    imgui.WindowFlags.NoTitleBar 
                    + imgui.WindowFlags.NoResize 
                    + imgui.WindowFlags.NoCollapse 
                    + imgui.WindowFlags.NoMove
                )
                player.HideCursor = true

                imgui.TextColoredRGB(
                    string.format(
                        "{FFFFFF}%s %s{FFFFFF} |", 
                        information.race.title, 
                        information.race.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        information.raceTime.value == "00:00:00" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |", 
                        information.raceTime.title, 
                        information.raceTime.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        information.cargo.value ~= "00:00:00" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |",
                        information.cargo.title, 
                        information.cargo.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        information.sessionExperience.value == "0" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |",  
                        information.sessionExperience.title, 
                        information.sessionExperience.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        information.raceQuantity.value > 0 and "{FFFFFF}%s {32CD32}%s{FFFFFF} |" or "{FFFFFF}%s {F2545B}%s{FFFFFF} |", 
                        information.raceQuantity.title, 
                        information.raceQuantity.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        "{FFFFFF}%s {32CD32}%s${FFFFFF} |", 
                        information.sessionEarnings.title, 
                        information.sessionEarnings.value
                    )
                )
                imgui.SameLine()
                imgui.TextColoredRGB(
                    string.format(
                        "{FFFFFF}%s {32CD32}%s$", 
                        information.totalEarnings.title, 
                        information.totalEarnings.value
                    )
                )
                imgui.End()
            end
        )

        return self
    end
}

return Info