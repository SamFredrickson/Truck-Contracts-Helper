local Dialogue = require 'tch.samp.dialogues.dialogue'

-- ����������� � ��������� ������ ���������
local Suggestion = {
    new = function()
        local id, title = 32700, "������������ | {AE433D}�����������"
        local self = Dialogue.new(id, title)
        return self
    end
}

return Suggestion