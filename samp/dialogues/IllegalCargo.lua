local Dialogue = require "tch.samp.dialogues.dialogue"

local IllegalCargo = {
    new = function()
        local id, title = 32700, "������������ | {.-}����������� ����"
        local self = Dialogue.new(id, title)
        self.isActive = false
        return self
    end
}

return IllegalCargo