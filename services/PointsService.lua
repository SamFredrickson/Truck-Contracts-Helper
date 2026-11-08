local Points = require "tch.common.storage.points"
local Service = require "tch.services.service"
local constants = require "tch.constants"

local trailerModels = {}
for _, model in pairs(constants.TRAILERS) do trailerModels[model] = true end

local truckModels = {}
for _, model in pairs(constants.TRUCKS) do truckModels[model] = true end

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
            local coords = point.coords
            local function isNear(x, y, z)
                return getDistanceBetweenCoords3d(x, y, z, coords.x, coords.y, coords.z) <= point.autoCheckDistance
            end

            for _, handle in ipairs(getAllVehicles()) do
                local model = getCarModel(handle)
                if trailerModels[model] then
                    if isNear(getCarCoordinates(handle)) then return false end
                elseif truckModels[model] then
                    local driver = getDriverOfCar(handle)
                    if driver and driver ~= -1 and driver ~= PLAYER_PED and sampGetPlayerIdByCharHandle(driver) then
                        if isNear(getCharCoordinates(driver)) then return false end
                    end
                end
            end

            return true
        end

        return self
    end
}

return PointsService
