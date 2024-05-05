local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Filters = {
    new = function()
        local self = Json.new("filters", constants.CONTRACT_FILTERS)

        self.save = function()
            file = io.open(self.filepath, "w")
            local json = encodeJson(self.data)
            file:write(json)
            file:close()
            return self.data
        end

        return self
    end
}

return Filters