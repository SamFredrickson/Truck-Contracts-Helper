local Dialogue = require 'tch.samp.dialogues.dialogue'

-- Предложение о повторном взятии контракта
local Suggestion = {
    new = function()
        local id, title = 32700, "Дальнобойщик | {AE433D}Контракты"
        local self = Dialogue.new(id, title)
        return self
    end
}

return Suggestion