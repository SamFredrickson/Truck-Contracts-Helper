local moonloader = require "moonloader"

local Command = {
    new = function(title)
        local self = {}

        self.title = title
        self.active = false

        return self
    end
}

return Command