local encoding = require "encoding"
local constants = require "tch.constants"
local inicfg = require "inicfg"
local ffi = require "ffi"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local instance

ffi.cdef[[
    void* __stdcall GetCurrentProcess(void);
    unsigned long __stdcall GetCurrentProcessId(void);
    int __stdcall GetProcessTimes(void *process, void *creation, void *exit, void *kernel, void *user);
]]

local kernel32 = ffi.load("kernel32")

local function getGameSessionId()
    local times = ffi.new("unsigned long[4][2]")
    if kernel32.GetProcessTimes(kernel32.GetCurrentProcess(), times[0], times[1], times[2], times[3]) == 0 then
        return nil
    end
    return string.format("gta-%d-%08x%08x", kernel32.GetCurrentProcessId(), times[0][1], times[0][0])
end

local Config = {
    new = function()
        if instance then return instance end

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

        local sessionId = getGameSessionId()
        if sessionId and self.data.settings.sessionEarningsGame ~= sessionId then
            self.data.settings.sessionEarnings = 0
            self.data.settings.sessionRaceQuantity = 0
            self.data.settings.sessionEarningsGame = sessionId
        end

        instance = self
        return instance
    end
}

return Config
