local Dialogue = require "tch.samp.dialogues.dialogue"

local Accept = {
    new = function()
        local id, title = 20302, "{.-}Принять"
        local self = Dialogue.new(id, title)
        self.isActive = false
        return self
    end
}

return Accept