local Service = require "tch.services.service"
local ServerMessage = require "tch.samp.server-messages.servermessage"
local ServerMessages = require "tch.common.storage.servermessages"

local ServerMessageService = {
    new = function()
        local self = Service.new()
        self.messages = ServerMessages.new()

        self.get = function()
            local result = {}
            for _, entry in pairs(self.messages.data) do
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
            for _, message in pairs(self.get()) do
                if message.code == code then
                    return message
                end
            end
            return false
        end
        
        return self
    end
}

return ServerMessageService