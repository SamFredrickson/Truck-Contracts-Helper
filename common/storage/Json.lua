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

        self.save = function()
            local file, openError = io.open(self.filepath, "w")
            if not file then return false, openError end

            local json = encodeJson(self.data)
            if not json then
                file:close()
                return false, "Failed to encode JSON"
            end

            local written, writeError = file:write(json)
            local closed, closeError = file:close()
            if not written then return false, writeError end
            if not closed then return false, closeError end
            return self.data
        end

        local file = io.open(self.filepath, "r")
        if file then
            local json = file:read("*a")
            file:close()
            local ok, decoded = pcall(decodeJson, json)
            if ok and type(decoded) == "table" then
                self.data = decoded
            else
                self.data = self.defaultJson
                self.loadError = "Invalid JSON in " .. self.filepath
            end
        elseif doesFileExist(self.filepath) then
            self.data = self.defaultJson
            self.loadError = "Unable to read " .. self.filepath
        else
            self.data = self.defaultJson
            local saved, saveError = self.save()
            if not saved then self.loadError = saveError end
        end

        return self
    end
}

return Json
