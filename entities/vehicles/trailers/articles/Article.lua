local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Vehicle = require "tch.entities.vehicles.vehicle"

local Article = {
    new = function(id)
        local self = Vehicle.new(id)
        return self
    end
}

return Article