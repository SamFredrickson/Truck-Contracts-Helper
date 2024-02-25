local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Json = {
    new = function(filename, defaultJson)
        local self = {}
        self.workingDirectory = getWorkingDirectory()
        self.defaultJson = defaultJson
        self.filename = string.format("%s.json", filename or "default")
        self.filepath = self.workingDirectory .. "/config/tch/" .. self.filename

        if not doesDirectoryExist(self.workingDirectory .. "/config") then
            createDirectory(self.workingDirectory .. "/config")
        end

        if not doesDirectoryExist(self.workingDirectory .. "/config/tch") then
            createDirectory(self.workingDirectory .. "/config/tch")
        end

        local file = io.open(self.filepath, "r")

        if file then
            local json = file:read("*a")
            self.data = decodeJson(json)
            file:close()
        end

        if not file then
            file = io.open(self.filepath, "w")
            local json = encodeJson(self.defaultJson)
            file:write(json)
            file:close()
            self.data = self.defaultJson
        end

        return self
    end
}

return Json