local Service = require "tch.services.service"
local ServerMessage = require "tch.samp.server-messages.servermessage"

local messages = {
    ServerMessage.new(
        "Вы успешно арендовали фуру. Для начала работы используйте {.-}%(%( /tmenu %)%)",
        "successful-renting"
    ),
    ServerMessage.new(
        "Контракт был отменен",
        "contract-canceled"
    ),
    ServerMessage.new(
        "У Вас уже есть активный контракт",
        "contract-is-active"
    ),
    ServerMessage.new(
        "Вам необходимо доставить в {.-}\"(.+)\" {.-}груз {.-}\"(.+)\" {.-}в количестве {.-}(%d+) т.",
        "delivery-start"
    ),
    ServerMessage.new(
        "Вы получили документы на груз, чтобы их показать используйте {.-}/showtabel",
        "receive-documents"
    ),
    ServerMessage.new(
        "Вы успешно доставили груз {.-}\"(.+)\" {.-}в количестве {.-}(%d+) т.",
        "delivery-success"
    ),
    ServerMessage.new(
        "Ваш заработок с учетом комиссии компании {.-}(%d+)%% {.-}составил {.-}(%d+)%$",
        "income"
    ),
    ServerMessage.new(
        "Вы получили дополнительно {.-}%$(%d+) {.-}при сдаче груза за улучшение семьи",
        "extra-income"
    ),
    ServerMessage.new(
        "За выполненный контракт Вы получили {.-}(%d+) опыта",
        "experience"
    ),
}

local ServerMessageService = {
    new = function()
        local self = Service.new()

        self.findByCode = function(code)
            for _, message in pairs(messages) do
                if message.code == code then
                    return message
                end
            end
            return false
        end
        
        return self
    end
}

return ServerMessageService