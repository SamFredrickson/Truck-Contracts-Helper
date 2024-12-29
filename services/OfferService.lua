local Offer = require "tch.entities.offers.offer"
local Service = require "tch.services.service"
local encoding = require "encoding"
local constants = require "tch.constants"
local Array = require "tch.common.array"
require "tch.common.lua-string"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local OfferService = {
    new = function()
        local self = Service.new()
        self.parse = function(text)
            local text = text:gsub("Истекает", "")
            local result = Array({})
            local id = 0
            for offer in text:gmatch(constants.REGEXP.MULTIPLE_OFFERS) do
                id = id + 1
                local title, initiator, start, finish = offer:match(constants.REGEXP.SINGLE_OFFER)
                local entity = Offer.new(id, title, initiator, start, finish)
                result:Push(entity)
            end
            return result
        end
        return self
    end
}

return OfferService