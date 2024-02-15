local Message = require "tch.entities.chat.message"

local LocalMessage = {
    new = function(text, delay, color)
        local self = Message.new(text, delay)
        self.type = "LOCAL"
        self.color = color
        return self
    end
}

return LocalMessage