local Vehicle = require "tch.entities.vehicles.vehicle"

local Volvo = {
    new = function()
        local self = Vehicle.new(12528)
        return self
    end
}

return Volvo