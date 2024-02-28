local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Dialogue = require "tch.samp.dialogues.dialogue"

local Documents = {
    new = function()
        local id, title = 32700, "������������ | {AE433D}��������� �� ����"
        local self = Dialogue.new(id, title)
        return self
    end
}

return Documents