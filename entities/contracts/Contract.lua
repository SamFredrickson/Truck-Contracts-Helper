local encoding = require "encoding"
local constants = require "tch.constants"
local Config = require "tch.common.config"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local Contract = {
    new = function(id, sort, top, source, destination, cargo, amount, company, IsActive)
        local self = {}
        self.id = id
        self.sort = sort -- ����� ����� ��� ����������
        self.top = top -- �������� �� �������� �������
        self.source = source
        self.destination = destination
        self.cargo = cargo
        self.amount = amount
        self.company = company
        self.IsActive = IsActive or false

        local isPinned = constants.PINS:Includes(tonumber(self.id))
        self.sort = isPinned and 0 or self.sort

        self.toString = function()
            return string.format
            (
                (config.data.settings.contractWindowTypes + 1) == 3 and "%s%d. %s -> %s" or "%s%d. %s -> %s[%d / %d]",
                isPinned and "[PIN] " or self.top and "[TOP] " or "",
                self.id, 
                self.source, 
                self.destination,
                self.amount.first,
                self.amount.second
            )
        end

        return self
    end
}
return Contract