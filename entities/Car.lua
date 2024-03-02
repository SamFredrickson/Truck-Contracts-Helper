local Player = require "tch.entities.player"

local Car = {
    new = function(id, name, model, health, speed, maxPassengers, isLocked, handle)
        local self = {}
        self.id = id
        self.name = name
        self.model = model
        self.health = health
        self.speed = speed
        self.maxPassengers = maxPassengers
        self.isLocked = isLocked
        self.handle = handle

        self.getDriver = function()
            local driverHandle = getDriverOfCar(self.handle)
            local isSuccess, id = sampGetPlayerIdByCharHandle(driverHandle)
            if isSuccess then
                local player = Player.new(
                    id,
                    sampGetPlayerNickname(id),
                    sampGetPlayerHealth(id),
                    sampGetPlayerArmor(id),
                    driverHandle
                )
                return player
            end
            return false
        end

        self.getPassengers = function()
            local result = {}
            for i = 1, self.maxPassengers do
                local handle = getCharInCarPassengerSeat(self.handle, i)
                local isSuccess, id = sampGetPlayerIdByCharHandle(handle)
                if isSuccess then
                    local player = Player.new(
                        id,
                        sampGetPlayerNickname(id),
                        sampGetPlayerHealth(id),
                        sampGetPlayerArmor(id),
                        handle
                    )
                    table.insert(result, player)
                end
            end
            return result
        end

        return self
    end
}

return Car