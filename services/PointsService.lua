local Points = require "tch.common.storage.points"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local encoding = require "encoding"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local playerService = PlayerService.new()
local carsService = CarService.new()

local PointsService = {
    new = function()
        local self = Service.new()

        self.getByDestination = function(destination)
            local result = {}
            for index, point in pairs(Points.new().data) do
                if point.destination:find(destination) then table.insert(result, { id = index, point = point }) end
            end

            table.sort(result, function(a, b) return a.point.sort < b.point.sort end)
            return result
        end

        self.get = function()
            local result = {}
            for index, point in pairs(Points.new().data) do table.insert(result, { id = index, point = point }) end
            table.sort(result, function(a, b) return a.point.sort < b.point.sort end)
            return result
        end

        self.update = function(id, fields)
            local points = Points.new()
            for key, value in pairs(fields) do
                points.data[id][key] = value
            end
            return points.save()
        end

        self.findBySort = function(sort)
            local data = self.get()
            for index, item in pairs(data) do
                if item.point.sort == sort then
                    return { id = item.id, point = item.point }
                end
            end
            return false
        end

        self.validateSourcePointAvailability = function(point)
            local cars = carsService.get()
            local players = playerService.get()
            local player = playerService.getByHandle(players, PLAYER_PED)

            for _, car in pairs(cars) do
                if car.IsTrailer() then
                    local isWithinDistance = car.IsWithinDistance(point.coords, point.autoTakeDistance)
                    if isWithinDistance then return false end
                end
            end

            for _, driver in pairs(players) do
                local car = carsService.getByDriver(cars, driver)
                local isWithinDistance = driver.IsWithinDistance(point.coords, point.autoTakeDistance)
                if car and car.IsTruck() and driver.handle ~= player.handle and isWithinDistance then return false end
            end

            return true
        end

        return self
    end
}

return PointsService