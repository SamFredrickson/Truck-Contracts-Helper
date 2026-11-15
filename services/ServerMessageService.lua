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

        local byCode = {}
        for _, entry in ipairs(self.get()) do
            byCode[entry.code] = byCode[entry.code] or entry
        end

        self.findByCode = function(code)
            return byCode[code] or false
        end
        
        self.match = function(text, code)
            local entry = byCode[code]
            if not entry then return nil end
            return text:match(entry.message)
        end

        return self
    end
}

return ServerMessageService
