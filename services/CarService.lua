local Car = require "tch.entities.car"
local Service = require "tch.services.service"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local CarService = {
    new = function()
        local self = Service.new()

        self.get = function()
            local result = {}
            for _, handle in ipairs(getAllVehicles()) do
                local model = getCarModel(handle)
                local name = getNameOfVehicleModel(model):lower()
                local health = getCarHealth(handle)
                local speed = getCarSpeed(handle) 
                local maxPassengers = getMaximumNumberOfPassengers(handle)

                local car = Car.new(
                    name,
                    model,
                    health,
                    speed,
                    maxPassengers,
                    handle
                )
        
                table.insert(result, car)
            end
            return result
        end

        self.getByDriver = function(cars, driver)
            for _, car in pairs(cars) do
                local carDriver = car.getDriver()
                if carDriver and carDriver.handle == driver.handle then
                    return car
                end
            end
            return false
        end

        self.IsCarAttachedToTrailer = function(trailers, car)
            for _, trailer in pairs(trailers) do
                local isAttached = isTrailerAttachedToCab(trailer.handle, car.handle)
                if isAttached then
                    return true
                end
            end
            return false
        end

        return self
    end
}

return CarService