local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Article = require "tch.entities.vehicles.trailers.articles.article"

local Flat = {
    new = function()
        local self = Article.new(450)
        return self
    end
}

return Flat