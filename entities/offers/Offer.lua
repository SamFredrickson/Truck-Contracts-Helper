local encoding = require "encoding"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Offer = {
    new = function(id, title, initiator, start, finish)
        local self = {}
        self.id = id
        self.title = title
        self.initiator = initiator
        self.start = start
        self.finish = finish
        return self
    end
}

return Offer