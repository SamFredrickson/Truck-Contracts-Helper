local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local constants = require "tch.constants"
local Dialogue = require "tch.samp.dialogues.dialogue"

local Menu = {
    new = function()
        local id, title = 32700, "Дальнобойщик | {AE433D}Меню"
        local self = Dialogue.new(id, title)
        return self
    end
}
return Menu
