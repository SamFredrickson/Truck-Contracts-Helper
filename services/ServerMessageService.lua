local Service = require "tch.services.service"
local ServerMessage = require "tch.samp.server-messages.servermessage"

local messages = {
    ServerMessage.new(
        "�� ������� ���������� ����. ��� ������ ������ ����������� {.-}%(%( /tmenu %)%)",
        "successful-renting"
    ),
    ServerMessage.new(
        "�������� ��� �������",
        "contract-canceled"
    ),
    ServerMessage.new(
        "� ��� ��� ���� �������� ��������",
        "contract-is-active"
    ),
    ServerMessage.new(
        "��� ���������� ��������� � {.-}\"(.+)\" {.-}���� {.-}\"(.+)\" {.-}� ���������� {.-}(%d+) �.",
        "delivery-start"
    ),
    ServerMessage.new(
        "�� �������� ��������� �� ����, ����� �� �������� ����������� {.-}/showtabel",
        "receive-documents"
    ),
    ServerMessage.new(
        "�� ������� ��������� ���� {.-}\"(.+)\" {.-}� ���������� {.-}(%d+) �.",
        "delivery-success"
    ),
    ServerMessage.new(
        "��� ��������� � ������ �������� �������� {.-}(%d+)%% {.-}�������� {.-}(%d+)%$",
        "income"
    ),
    ServerMessage.new(
        "�� �������� ������������� {.-}%$(%d+) {.-}��� ����� ����� �� ��������� �����",
        "extra-income"
    ),
    ServerMessage.new(
        "�� ����������� �������� �� �������� {.-}(%d+) �����",
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