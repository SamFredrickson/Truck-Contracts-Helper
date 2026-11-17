local Service = require "tch.services.service"
local ChatService = require "tch.services.chatservice"
local constants = require "tch.constants"
local LocalMessage = require "tch.entities.chat.localmessage"
local moonloader = require "moonloader"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local chatService = ChatService.new()
local UPDATE_CHECK_TIMEOUT = 15000

local function isReleaseVersion(content)
    if type(content) ~= "table"
    or type(content.number) ~= "number"
    or content.number < 1
    or content.number % 1 ~= 0
    or type(content.full_number) ~= "string"
    or not content.full_number:match("^v%d+%.%d+%.%d+$")
    or type(content.release_url) ~= "string" then
        return false
    end

    local prefix = constants.SCRIPT_INFO.URL .. "/releases/download/" .. content.full_number .. "/"
    if content.release_url:sub(1, #prefix) ~= prefix then return false end

    local asset = content.release_url:sub(#prefix + 1)
    return asset:match("^[A-Za-z0-9][A-Za-z0-9_.-]*%.rar$") ~= nil
        or asset:match("^[A-Za-z0-9][A-Za-z0-9_.-]*%.zip$") ~= nil
end

local HttpService = {
    new = function()
        local self = Service.new()
        self.version = nil
        local pendingCheck

        self.notifyIfUpdateAvailable = function()
            if self.version and self.version.number > constants.SCRIPT_INFO.VERSION_NUMBER then
                local messages = {
                    LocalMessage.new
                    (
                        string.format
                        (
                            " {FFFFFF}Доступна новая версия скрипта" ..
                            " {ed5a5a}Truck Contracts Helper {FFFFFF}(%s).",
                            self.version.full_number
                        ),
                        1000
                    ),
                    LocalMessage.new
                    (
                        " {FFFFFF}Введите команду {ed5a5a}/tch.update{FFFFFF}" ..
                        " чтобы начать скачивание по ссылке.",
                        1000
                    )
                }
                for _, message in pairs(messages) do chatService.send(message) end
            end
        end

        self.getAvailableUpdates = function(onComplete)
            if pendingCheck then
                if onComplete then pendingCheck.callbacks[#pendingCheck.callbacks + 1] = onComplete end
                return
            end

            local ok, path = pcall(os.tmpname)
            if not ok or not path or (doesFileExist(path) and not os.remove(path)) then
                if onComplete then onComplete(nil) end
                return
            end

            local check = { callbacks = {} }
            if onComplete then check.callbacks[1] = onComplete end
            pendingCheck = check

            local function finish(version)
                pendingCheck = nil
                os.remove(path)
                if version then self.version = version end
                if #check.callbacks == 0 then
                    if version then self.notifyIfUpdateAvailable() end
                else
                    for _, callback in ipairs(check.callbacks) do callback(version) end
                end
            end

            local started, downloadId = pcall(downloadUrlToFile, constants.SCRIPT_INFO.VERSION_URL, path, function(_, status)
                if status ~= moonloader.download_status.STATUSEX_ENDDOWNLOAD then return end
                if pendingCheck ~= check then
                    os.remove(path)
                    return
                end

                local file = io.open(path, "r")
                if not file then
                    finish(nil)
                    return
                end
                local json = file:read("*a")
                file:close()
                local decoded, content = pcall(decodeJson, json)
                finish(decoded and isReleaseVersion(content) and content or nil)
            end)

            if pendingCheck ~= check then return end
            if not started or downloadId == false then
                finish(nil)
                return
            end
            lua_thread.create(function()
                wait(UPDATE_CHECK_TIMEOUT)
                if pendingCheck == check then finish(nil) end
            end)
        end

        return self
    end
}

return HttpService