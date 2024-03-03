local Vehicle = require "tch.entities.vehicles.vehicle"

local Linerunner = {
    new = function()
        local self = Vehicle.new(403)
        return self
    end
}

return Linerunner