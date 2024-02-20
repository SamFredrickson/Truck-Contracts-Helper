local Coords = require "tch.entities.coords.coords"

local Player = {
    new = function(id, name, health, armor, handle)
        local self = {}
        local x, y, z = getCharCoordinates(handle)

        self.id = id
        self.name = name
        self.health = health
        self.armor = armor
        self.coords = Coords.new(x, y, z)
        self.handle = handle

        self.IsWithinDistance = function(coords, distance)
            local distanceBetweenCoords = getDistanceBetweenCoords3d(
                self.coords.x,
                self.coords.y,
                self.coords.z,
                coords.x,
                coords.y,
                coords.z
            )
            return distanceBetweenCoords <= distance
        end

        return self
    end
}

return Player