local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Hotkeys = {
    new = function()
        local self = Json.new("hotkeys2", constants.HOTKEYS)

        self.save = function()
            file = io.open(self.filepath, "w")
            local json = encodeJson(self.data)
            file:write(json)
            file:close()
            return self.data
        end

        self.getByName = function(name)
            for index, hotkey in pairs(self.data) do
                if hotkey.name == name then
                    return { index, hotkey }
                end
            end
            return false
        end

        return self
    end
}

return Hotkeys