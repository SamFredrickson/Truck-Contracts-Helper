local Service = require "tch.services.service"
local ServerMessage = require "tch.samp.server-messages.servermessage"
local constants = require "tch.constants"

local ServerMessageService = {
    new = function()
        local self = Service.new()

        self.get = function()
            local result = {}
            for _, entry in pairs(constants.SERVER_MESSAGES) do
                local serverMessage = ServerMessage.new(
                    entry.message,
                    entry.code
                )
                table.insert(
                    result, 
                    serverMessage
                )
            end
            return result
        end

        self.findByCode = function(code)
            for _, entry in pairs(self.get()) do
                if entry.code == code then
                    return entry
                end
            end
            return false
        end
        
        return self
    end
}

return ServerMessageService