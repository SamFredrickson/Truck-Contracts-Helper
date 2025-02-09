local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local ProfitAndLoss = {
    new = function()
        local self = Json.new("pl", constants.PROFIT_AND_LOSS)
        self.save = function()
            file = io.open(self.filepath, "w")
            local json = encodeJson(self.data)
            file:write(json)
            file:close()
            return self.data
        end
        self.getByName = function(name)
            for index, item in pairs(self.data) do
                if item.name == name then
                    return { index, item }
                end
            end
            return false
        end
        return self
    end
}

return ProfitAndLoss