local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Dialogue = require 'tch.samp.dialogues.dialogue'

local Menu = {
    new = function()
        local id, title = 32700, "Дальнобойщик | {AE433D}Меню"
        local self = Dialogue.new(id, title)
        return self
    end,
    FLAGS = {
		IS_PARSING_CONTRACTS_LAST_STEP = false,
        IS_PARSING_CONTRACTS = false
	}
}

return Menu