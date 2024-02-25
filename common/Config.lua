local encoding = require "encoding"
local constants = require "tch.constants"
local inicfg = require "inicfg"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Config = {
    new = function()
        local self = {}
        self.workingDirectory = getWorkingDirectory()

        if not doesDirectoryExist(self.workingDirectory .. "/config") then
            createDirectory(self.workingDirectory .. "/config")
        end

        if not doesDirectoryExist(self.workingDirectory .. "/config/tch") then
            createDirectory(self.workingDirectory .. "/config/tch")
        end

        self.data = inicfg.load(
            { settings = constants.CONFIG.DEFAULT_SETTINGS },
            constants.CONFIG.PATH
        )

        self.save = function()
            return inicfg.save(
                self.data, 
                constants.CONFIG.PATH
            )
        end

        return self
    end
}

return Config