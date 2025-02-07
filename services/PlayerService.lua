local Player = require "tch.entities.player"
local Service = require "tch.services.service"

local PlayerService = {
    new = function()
        local self = Service.new()

        self.get = function()
            local result = {}
            for _, handle in pairs(getAllChars()) do
                local isSuccess, id = sampGetPlayerIdByCharHandle(handle)
                if isSuccess then
                    local player = Player.new
                    (
                        id,
                        sampGetPlayerNickname(id),
                        sampGetPlayerHealth(id),
                        sampGetPlayerArmor(id),
                        handle
                    )
                    table.insert(result, player)
                end
            end
            return result
        end

        self.getNpc = function()
            local result = {}
            for _, handle in pairs(getAllChars()) do
                if select(2, sampGetPlayerIdByCharHandle(handle)) == -1 and handle ~= PLAYER_PED then
                    table.insert(result, handle)
                end
            end
            return result
        end

        self.getByHandle = function(players, handle)
            for _, player in pairs(players) do
                if player.handle == handle then
                    local isSuccess, id = sampGetPlayerIdByCharHandle(handle)
                    if isSuccess then
                        local player = Player.new(
                            id,
                            sampGetPlayerNickname(id),
                            sampGetPlayerHealth(id),
                            sampGetPlayerArmor(id),
                            handle
                        )
                        return player
                    end
                end
            end
            return false
        end

        return self
    end
}

return PlayerService