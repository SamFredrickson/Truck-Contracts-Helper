local Coords = require "tch.entities.coords.coords"

local AirportLasVenturas = {
    new = function()
        local self = Coords.new(1356.51, 1709.00, 10.82)
        return self
    end
}

return AirportLasVenturas