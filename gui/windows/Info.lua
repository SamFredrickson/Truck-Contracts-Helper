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
local Statistics = require "tch.common.storage.statistics"

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
local experienceToLevel = Number.new(0).format(0, "", "{F2545B}")
local raceQuantity = config.data.settings.sessionRaceQuantity

local information = Information.new
(
    InfoEntry.new(
        "Рейс:", 
        "race", 
        "—"
    ),
    InfoEntry.new(
        "Время в рейсе:", 
        "race-time", 
        raceTime
    ),
    InfoEntry.new(
        "Нелегальный груз доступен через:", 
        "illegal-cargo-time", 
        illegalCargoAvailableAtFormatted
    ),
    InfoEntry.new(
        "Опыта за сессию:", 
        "session-experience",
        sessionExperience
    ),
    InfoEntry.new(
        "Опыта до N уровня:", 
        "experience-to-level",
        experienceToLevel
    ),
    InfoEntry.new(
        "Рейсов за сессию:",
        "session-races",
        raceQuantity
    ),
    InfoEntry.new(
        "Заработано за сессию:",
        "session-earnings",
        sessionEarnings
    ),
    InfoEntry.new(
        "Заработано за всё время:",
        "total-earnings",
        totalEarnings
    )
)

local Info = {
    new = function()
        local self = Window.new()
        self.title = u8("Информация")
        self.information = information
        self.entries = {}

        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(-2, screenY - 25)
        local size = imgui.ImVec2(5000, 10)

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
                if config.data.settings.selectedScriptStatus == 0 then return end
                if not config.data.settings.statistics then return end
                InfoTheme.new()
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)
                player.HideCursor = true

                imgui.Begin(
                    self.title, 
                    self.window, 
                    imgui.WindowFlags.NoTitleBar 
                    + imgui.WindowFlags.NoResize 
                    + imgui.WindowFlags.NoCollapse 
                    + imgui.WindowFlags.NoMove
                )

                for _, entry in pairs(information) do 
                   self.entries[entry.id] = entry
                end
                
                for _, entry in pairs(self.entries) do
                    for _, statistics in pairs(Statistics.new().data) do
                        if statistics.code == entry.code and not statistics.hidden then
                            imgui.TextColoredRGB(entry.getValue())
                            imgui.SameLine()
                        end
                    end
                end

                imgui.End()
            end
        )

        return self
    end
}

return Info