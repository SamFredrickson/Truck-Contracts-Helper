local Information = {
    new = function(race, raceTime, cargo, sessionExperience, raceQuantity, sessionEarnings, totalEarnings)
        local self = {}
        self.race = race
        self.raceTime = raceTime
        self.cargo = cargo
        self.sessionExperience = sessionExperience
        self.raceQuantity = raceQuantity
        self.sessionEarnings = sessionEarnings
        self.totalEarnings = totalEarnings
        return self
    end
}

return Information