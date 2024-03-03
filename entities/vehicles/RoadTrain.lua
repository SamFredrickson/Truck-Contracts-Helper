local Vehicle = require "tch.entities.vehicles.vehicle"

local RoadTrain = {
    new = function()
        local self = Vehicle.new(515)
        return self
    end
}

return RoadTrain