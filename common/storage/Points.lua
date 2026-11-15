local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Points = {
    new = function()
        local self = Json.new("points_v2", constants.POINTS)
        return self
    end
}

return Points
