local Vehicle = require "tch.entities.vehicles.vehicle"

local Tanker = {
    new = function()
        local self = Vehicle.new(514)
        return self
    end
}

return Tanker