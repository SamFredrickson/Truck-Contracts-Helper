local encoding = require "encoding"
local constants = require 'tch.constants'

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Contract = {
    new = function(id, source, destination, cargo, amount, company)
        local self = {}

        self.id = id
        -- self.top = top -- явл€етс€ ли контракт топовым
        -- self.sort = sort -- ÷елое число дл€ сортировки
        self.source = source
        self.destination = destination
        self.cargo = cargo
        self.amount = amount
        self.company = company

        return self
    end
}

Contract.makeListFromText = function(text)
    local list = {}
    for contract in text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS) do
        local id, source, destination, cargo, amountFirst, amountSecond, company = contract:match(constants.REGEXP.SINGLE_CONTRACT)
        local amount = { first = amountFirst, second = amountSecond }
        table.insert(list, Contract.new(id, source, destination, cargo, amount, company))
    end
    return list
end

return Contract