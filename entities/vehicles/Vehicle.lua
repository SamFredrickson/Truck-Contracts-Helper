local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Vehicle = {
    new = function(id)
        local self = {}

        self.id = id

        return self
    end
}

return Vehicle