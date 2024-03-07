local Points = require "tch.common.storage.points"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local encoding = require "encoding"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local playerService = PlayerService.new()

local PointsService = {
    new = function()
        local self = Service.new()

        self.getByDestination = function(destination)
            local result = {}
            for index, point in pairs(Points.new().data) do
                if point.destination:find(destination) then
                    table.insert(result, {
                        id = index, 
                        point = point 
                    })
                end
            end

            table.sort(result, function(a, b)
                return a.point.sort < b.point.sort
            end)

            return result
        end

        self.get = function()
            local result = {}
            for index, point in pairs(Points.new().data) do
                table.insert(result, {
                    id = index, 
                    point = point 
                })
            end

            table.sort(result, function(a, b)
                return a.point.sort < b.point.sort
            end)

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

        self.getPlayerAutoloadPoint = function()
            local player = playerService.getByHandle(
                playerService.get(), 
                PLAYER_PED
            )
            for _, point in pairs(constants.AUTOLOAD_POINTS) do
                if player.IsWithinDistance(point.coords, 15) then
                    return point
                end
            end
            return false
        end

        return self
    end
}

return PointsService