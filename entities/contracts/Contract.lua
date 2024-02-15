local encoding = require "encoding"
local constants = require "tch.constants"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Contract = {
    new = function(id, sort, top, source, destination, cargo, amount, company, IsActive)
        local self = {}
        self.id = id
        self.sort = sort -- ÷елое число дл€ сортировки
        self.top = top -- явл€етс€ ли контракт топовым
        self.source = source
        self.destination = destination
        self.cargo = cargo
        self.amount = amount
        self.company = company
        self.IsActive = IsActive or false

        self.toString = function()
            return string.format(
                "%s%d. %s -> %s[%d / %d]", 
                self.top and "[TOP] " or "",
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