local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Vehicle = require "tch.entities.vehicles.vehicle"

local Petrol = {
    new = function()
        local self = Vehicle.new(584)
        return self
    end
}

return Petrol