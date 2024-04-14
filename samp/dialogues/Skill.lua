local Dialogue = require "tch.samp.dialogues.dialogue"

local Skill = {
    new = function()
        local id, title = 32700, "Дальнобойщик | {.-}Информация"
        local self = Dialogue.new(id, title)
        return self
    end,
    FLAGS = {
        IS_PARSING = false
    }
}

return Skill