local Vehicle = require "tch.entities.vehicles.vehicle"

local Kenworth = {
    new = function()
        local self = Vehicle.new(12669)
        return self
    end
}

return Kenworth