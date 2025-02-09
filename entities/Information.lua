local ProfitAndLoss = require "tch.common.storage.profitandloss"
local Array = require "tch.common.array"
local Number = require "tch.entities.number"

local Information = {
    new = function(race, raceTime, cargo, sessionExperience, experienceToLevel, raceQuantity, sessionEarnings, totalEarnings)
        local self = {}

        self.race = {
            id = 1,
            code = race.code,
            setValue = function(value)
                race.value = value
            end,
            getValue = function()
                return string.format(
                    "{FFFFFF}%s %s{FFFFFF} |", 
                    race.title, 
                    race.value
                )
            end
        }

        self.raceTime = {
            id = 2,
            code = raceTime.code,
            setValue = function(value)
                raceTime.value = value
            end,
            getValue = function()
                return string.format(
                    raceTime.value == "00:00:00" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |", 
                    raceTime.title, 
                    raceTime.value
                )
            end
        }

        self.cargo = {
            id = 3,
            code = cargo.code,
            setValue = function(value)
                cargo.value = value
            end,
            getValue = function()
                return string.format(
                    cargo.value ~= "00:00:00" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |",
                    cargo.title, 
                    cargo.value
                )
            end
        }

        self.sessionExperience = {
            id = 4,
            code = sessionExperience.code,
            setValue = function(value)
                sessionExperience.value = value
            end,
            getValue = function()
                return string.format(
                    sessionExperience.value == "0" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |",  
                    sessionExperience.title, 
                    sessionExperience.value
                )
            end
        }

        self.experienceToLevel = {
            id = 5,
            code = experienceToLevel.code,
            setValue = function(value)
                experienceToLevel.value = value
            end,
            setTitle = function(title)
                experienceToLevel.title = title
            end,
            getValue = function()
                return string.format(
                   experienceToLevel.value == "0" and "{FFFFFF}%s {F2545B}%s{FFFFFF} |" or "{FFFFFF}%s {32CD32}%s{FFFFFF} |",  
                   experienceToLevel.title, 
                   experienceToLevel.value
                )
            end
        }

        self.raceQuantity = {
            id = 6,
            code = raceQuantity.code,
            setValue = function(value)
                raceQuantity.value = value
            end,
            getValue = function()
                return string.format(
                    raceQuantity.value > 0 and "{FFFFFF}%s {32CD32}%s{FFFFFF} |" or "{FFFFFF}%s {F2545B}%s{FFFFFF} |", 
                    raceQuantity.title, 
                    raceQuantity.value
                )
            end
        }

        self.sessionEarnings = {
            id = 7,
            code = sessionEarnings.code,
            setValue = function(value)
                sessionEarnings.value = value
            end,
            getValue = function()
                return string.format(
                    "{FFFFFF}%s {32CD32}%s${FFFFFF} |", 
                    sessionEarnings.title, 
                    sessionEarnings.value
                )
            end
        }

        self.totalEarnings = {
            id = 8,
            code = totalEarnings.code,
            setValue = function(value)
                totalEarnings.value = value
            end,
            getValue = function()
                local sum = Array(ProfitAndLoss.new().data)
                :Filter(function(element) return element.enabled end)
                :Map(function(element) return element.sum end)
                :Reduce(function(accumulator, element) return accumulator + element end)

                local sumFormatted = Number
                .new(sum or 0)
                .format(0, "", "{F2545B}")

                return string.format
                (
                    "{FFFFFF}%s {32CD32}%s$", 
                    totalEarnings.title, 
                    sumFormatted
                )
            end
        }

        return self
    end
}

return Information