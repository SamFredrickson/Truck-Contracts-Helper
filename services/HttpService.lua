local Service = require "tch.services.service"
local ChatService = require "tch.services.chatservice"
local constants = require "tch.constants"
local LocalMessage = require "tch.entities.chat.localmessage"
local moonloader = require "moonloader"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local chatService = ChatService.new()

local HttpService = {
    new = function()
        local self = Service.new()
        self.version = nil

        self.getAvailableUpdates = function()
            local path = os.tmpname()
            if doesFileExist(fpath) then
                os.remove(fpath)
            end
            downloadUrlToFile(
                constants.SCRIPT_INFO.VERSION_URL,
                path,
                function(_, status, _, _)
                    if status == moonloader.download_status.STATUSEX_ENDDOWNLOAD then
                        if not doesFileExist(path) then
                            return false
                        end
                        local file = io.open(path, "r")
                        if not file then
                            return false
                        end
                        local content = decodeJson(file:read("*a"))
                        self.version = content
                        file:close()
                        os.remove(path)

                        if content.number > constants.SCRIPT_INFO.VERSION_NUMBER then
                            chatService.send(
                                LocalMessage.new(
                                    string.format(
                                        " {FFFFFF}Доступна новая версия скрипта " .. 
                                        " {ed5a5a}Truck Contracts Helper {FFFFFF}(%s).", 
                                        content.full_number
                                    )
                                )
                            )
                            chatService.send(
                                LocalMessage.new(
                                    " {FFFFFF}Введите команду {ed5a5a}/tch.update {FFFFFF}" .. 
                                    " чтобы начать скачивание по ссылке."
                                )
                            )
                        end

                        return true
                    end
                end
            )
        end

        return self
    end
}

return HttpService