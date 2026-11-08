local encoding = require "encoding"
local constants = require "tch.constants"
local Json = require "tch.common.storage.json"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local activeHotkeys

local function indexHotkeys(data)
    local byName = {}
    for _, hotkey in pairs(data) do
        if type(hotkey) == "table" and hotkey.name then
            local copy = {}
            for key, value in pairs(hotkey) do copy[key] = value end
            byName[hotkey.name] = copy
        end
    end
    return byName
end

local defaultHotkeys = indexHotkeys(constants.HOTKEYS)

local Hotkeys = {
    new = function()
        local self = Json.new("hotkeys2", constants.HOTKEYS)
        local save = self.save
        self.save = function()
            local saved, err = save()
            if saved then activeHotkeys = indexHotkeys(self.data) end
            return saved, err
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

function Hotkeys.getActive(name)
    if not activeHotkeys then activeHotkeys = indexHotkeys(Hotkeys.new().data) end
    return activeHotkeys[name] or defaultHotkeys[name]
end

return Hotkeys
