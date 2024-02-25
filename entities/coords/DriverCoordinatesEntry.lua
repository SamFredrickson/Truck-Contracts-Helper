local Coords = require "tch.entities.coords.coords"

local DriverCoordinatesEntry = {
    new = function(nickname, message, x, y, z)
        local self = Coords.new(x, y, z)
        self.nickname = nickname
        self.message = message
        self.blip = nil

        self.getNickname = function()
            if string.len(self.nickname) > 12 then
                return string.format(
                    "%s...",
                    string.sub(self.nickname, 1, 12)
                )
            end
            return self.nickname
        end

        self.getMessage = function()
            if string.len(self.message) > 30 then
                return string.format(
                    "%s...",
                    string.sub(self.message, 1, 30)
                )
            end
            return self.message
        end

        return self
    end
}

return DriverCoordinatesEntry