local Service = require "tch.services.service"

local ChatService = {
    new = function()
        local self = Service.new()

        self.send = function(message)
            local delay = message.delay
            local messageType = message.type
            local text = message.text
            local color = message.color

            if messageType == "GLOBAL" then
                if delay then
                    lua_thread.create(function()
                        wait(delay)
                        sampSendChat(text)
                        return
                    end)
                    return
                end
                sampSendChat(text)
                return
            end
           
            if delay then
                lua_thread.create(function()
                    wait(delay)
                    sampAddChatMessage(text, color or -1)
                    return
                end)
                return
            end
            sampAddChatMessage(text, color or -1)
        end

        return self
    end
}

return ChatService