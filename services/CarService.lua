local Car = require "tch.entities.car"
local Service = require "tch.services.service"
local constants = require "tch.constants"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local truckModels = {}
for _, model in pairs(constants.TRUCKS) do truckModels[model] = true end

local CarService = {
    new = function()
        local self = Service.new()

        self.getDrivenTruck = function()
            if not isCharInAnyCar(PLAYER_PED) then return nil end

            local handle = storeCarCharIsInNoSave(PLAYER_PED)
            if getDriverOfCar(handle) == PLAYER_PED and truckModels[getCarModel(handle)] then
                return handle
            end
        end

        self.hasAttachedTrailer = function(car)
            for _, handle in ipairs(getAllVehicles()) do
                if handle ~= car and isTrailerAttachedToCab(handle, car) then return true end
            end
            return false
        end

        self.get = function()
            local result = {}
            for _, handle in ipairs(getAllVehicles()) do
                local _, id = sampGetVehicleIdByCarHandle(handle)
                local model = getCarModel(handle)
                local name = getNameOfVehicleModel(model)
                local health = getCarHealth(handle)
                local speed = getCarSpeed(handle) 
                local maxPassengers = getMaximumNumberOfPassengers(handle)
                local isLocked = getCarDoorLockStatus(handle)

                local car = Car.new
                (
                    id,
                    name and name:lower() or "unknown",
                    model,
                    health,
                    speed,
                    maxPassengers,
                    isLocked,
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

        self.getByVehicleId = function(cars, vehicleId)
            for _, car in pairs(cars) do
                if car.id == vehicleId then
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