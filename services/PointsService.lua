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
            if points.loadError then return false, points.loadError end
            local point = points.data[id]
            if not point then return false, "Route not found" end
            for key, value in pairs(fields) do
                point[key] = value
            end
            return points.save()
        end

        self.move = function(id, targetId, after)
            local points = Points.new()
            if points.loadError then return false, points.loadError end
            if not points.data[id] or not points.data[targetId] then return false, "Route not found" end
            if id == targetId then return true end
            local ordered, priorities = {}, {}
            for key, point in pairs(points.data) do
                if type(point.sort) ~= "number" or priorities[point.sort] then
                    return false, "Invalid route priority"
                end
                priorities[point.sort] = true
                ordered[#ordered + 1] = { id = key, point = point }
            end
            table.sort(ordered, function(a, b) return a.point.sort < b.point.sort end)
            local sourceIndex
            for index, item in ipairs(ordered) do if item.id == id then sourceIndex = index; break end end
            local source = table.remove(ordered, sourceIndex)
            local targetIndex
            for index, item in ipairs(ordered) do if item.id == targetId then targetIndex = index; break end end
            local insertIndex = targetIndex + (after and 1 or 0)
            if insertIndex == sourceIndex then return true end
            table.insert(ordered, insertIndex, source)
            for index, item in ipairs(ordered) do item.point.sort = index end
            return points.save()
        end
        self.swapPriority = function(id, offset)
            local points = Points.new()
            if points.loadError then return false, points.loadError end

            local current = points.data[id]
            if not current or type(current.sort) ~= "number" then
                return false, "Invalid route priority"
            end

            local neighbor
            for _, point in pairs(points.data) do
                if point.sort == current.sort + offset then
                    if neighbor then return false, "Duplicate route priority" end
                    neighbor = point
                end
            end
            if not neighbor then return false, "Neighboring route priority not found" end

            current.sort, neighbor.sort = neighbor.sort, current.sort
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
