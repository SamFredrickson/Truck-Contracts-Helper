local encoding = require "encoding"
local constants = require 'tch.constants'

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Contract = {
    new = function(id, sort, top, source, destination, cargo, amount, company)
        local self = {}

        self.id = id
        self.sort = sort -- ÷елое число дл€ сортировки
        self.top = top -- явл€етс€ ли контракт топовым
        self.source = source
        self.destination = destination
        self.cargo = cargo
        self.amount = amount
        self.company = company

        return self
    end
}

Contract.getPriorities = function(source, destination)
    for _, value in pairs(constants.CONTRACTS) do
        if source:find(value.source) and destination:find(value.destination) then
            return { value.sort, value.top }
        end
    end
    return { 8, false }
end

Contract.sort = function(contracts)
    table.sort(contracts, function(a, b)
        return a.sort < b.sort
    end)
    return contracts
end

Contract.makeListFromText = function(text)
    local list = {}

    for contract in text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS) do
        local id, source, destination, cargo, amountFirst, amountSecond, company = contract:match(constants.REGEXP.SINGLE_CONTRACT)
        local amount = { first = amountFirst, second = amountSecond }
        local sort, top = table.unpack(Contract.getPriorities(source, destination))

        local entity = Contract.new(
            id,
            sort,
            top,
            source,
            destination,
            cargo,
            amount,
            company
        )

        table.insert(list, entity)
    end

    return Contract.sort(list)
end

return Contract