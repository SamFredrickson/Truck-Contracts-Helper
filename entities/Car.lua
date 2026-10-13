local constants = require "tch.constants"
local Player = require "tch.entities.player"
local Coords = require "tch.entities.coords.coords"

local Car = {
    new = function(id, name, model, health, speed, maxPassengers, isLocked, handle)
        local self = {}
        local x, y, z = getCarCoordinates(handle)
        self.id = id
        self.name = name
        self.model = model
        self.health = health
        self.speed = speed
        self.maxPassengers = maxPassengers
        self.isLocked = isLocked
        self.handle = handle
        self.coords = Coords.new(x, y, z)
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
        self.IsWithinDistance = function(coords, distance)
            local distanceBetweenCoords = getDistanceBetweenCoords3d
            (
                self.coords.x,
                self.coords.y,
                self.coords.z,
                coords.x,
                coords.y,
                coords.z
            )
            return distanceBetweenCoords <= distance
        end
        self.IsTruck = function()
            for _, truck in pairs(constants.TRUCKS) do
                if self.model == truck then
                    return true
                end
            end
            return false
        end
        self.IsTrailer = function()
            for _, trailer in pairs(constants.TRAILERS) do
                if self.model == trailer then
                    return true
                end
            end
            return false
        end
        return self
    end
}

return Car