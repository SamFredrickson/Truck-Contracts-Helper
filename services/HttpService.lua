local Service = require "tch.services.service"
local ChatService = require "tch.services.chatservice"
local constants = require "tch.constants"
local LocalMessage = require "tch.entities.chat.localmessage"
local moonloader = require "moonloader"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local chatService = ChatService.new()

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

        self.getAvailableUpdates = function()
            local path = os.tmpname()
            if not path then return false end
            if doesFileExist(path) and not os.remove(path) then return false end

            downloadUrlToFile
            (
                constants.SCRIPT_INFO.VERSION_URL,
                path,
                function(_, status, _, _)
                    if status == moonloader.download_status.STATUSEX_ENDDOWNLOAD then
                        local file = io.open(path, "r")
                        if not file then
                            os.remove(path)
                            return false
                        end

                        local json = file:read("*a")
                        file:close()
                        os.remove(path)
                        if not json or json == "" then return false end

                        local ok, content = pcall(decodeJson, json)
                        if not ok or not isReleaseVersion(content) then return false end
                        self.version = content

                        self.notifyIfUpdateAvailable()

                        return true
                    end
                end
            )
        end

        return self
    end
}

return HttpService