local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local ProfitAndLoss = {
    new = function()
        local self = Json.new("pl_v3", constants.PROFIT_AND_LOSS)
        self.getByName = function(name)
            for index, item in pairs(self.data) do
                if item.name == name then
                    return { index, item }
                end
            end
            return false
        end
        self.sumEnabled = function()
            local sum = 0
            for _, item in pairs(self.data) do
                if item.enabled then sum = sum + item.sum end
            end
            return sum
        end
        return self
    end
}

return ProfitAndLoss
