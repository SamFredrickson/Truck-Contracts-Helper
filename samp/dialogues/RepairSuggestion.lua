local Dialogue = require "tch.samp.dialogues.dialogue"

local RepairSuggestion = {
    new = function()
        local id, title = 2016, "Ремонт | {.-}Предложение"
        local self = Dialogue.new(id, title)
        self.active = false
        return self
    end
}

return RepairSuggestion