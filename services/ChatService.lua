local Service = require "tch.services.service"

local ChatService = {
    new = function()
        local self = Service.new()

        self.send = function(message)
            local delay = message.delay
            local messageType = message.type
            local text = message.text

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
                    sampAddChatMessage(text)
                    return
                end)
                return
            end
            sampAddChatMessage(text)
        end

        return self
    end
}

return ChatService