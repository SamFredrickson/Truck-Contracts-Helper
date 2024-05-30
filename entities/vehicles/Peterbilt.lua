local Vehicle = require "tch.entities.vehicles.vehicle"

local Peterbilt = {
    new = function()
        local self = Vehicle.new(12556)
        return self
    end
}

return Peterbilt