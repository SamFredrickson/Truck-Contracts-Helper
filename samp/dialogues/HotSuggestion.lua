local Dialogue = require "tch.samp.dialogues.dialogue"

local HotSuggestion = {
    new = function()
        local id, title = 2016, "хот%-дог | {.-}Предложение"
        local self = Dialogue.new(id, title)
        self.active = false
        return self
    end
}

return HotSuggestion