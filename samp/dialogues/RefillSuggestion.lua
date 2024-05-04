local Dialogue = require "tch.samp.dialogues.dialogue"

local RefillSuggestion = {
    new = function()
        local id, title = 2016, "Заправка | {.-}Предложение"
        local self = Dialogue.new(id, title)
        self.active = false
        return self
    end
}

return RefillSuggestion