local encoding = require "encoding"
local ffi = require "ffi"

ffi.cdef[[
    int __stdcall MoveFileExA(const char *source, const char *destination, unsigned long flags);
    unsigned long __stdcall GetCurrentProcessId(void);
    unsigned long __stdcall GetLastError(void);
]]

local kernel32 = ffi.load("kernel32")
local MOVEFILE_REPLACE_EXISTING = 1
local tempSuffix = string.format(".%d.tmp", kernel32.GetCurrentProcessId())

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
            local ok, json = pcall(encodeJson, self.data)
            if not ok or type(json) ~= "string" or json == "" then
                return false, "Failed to encode JSON"
            end

            local path = self.filepath:gsub("/", "\\")
            local tempPath = path .. tempSuffix
            local file, openError = io.open(tempPath, "w")
            if not file then return false, openError end

            local written, writeError = file:write(json)
            local closed, closeError = file:close()
            if not written or not closed then
                os.remove(tempPath)
                return false, writeError or closeError
            end

            if kernel32.MoveFileExA(tempPath, path, MOVEFILE_REPLACE_EXISTING) == 0 then
                local errorCode = kernel32.GetLastError()
                os.remove(tempPath)
                return false, "Unable to replace " .. self.filepath .. " (error " .. errorCode .. ")"
            end
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
