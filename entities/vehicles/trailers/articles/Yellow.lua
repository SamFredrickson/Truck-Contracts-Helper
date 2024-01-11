local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Article = require "tch.entities.vehicles.trailers.articles.article"

local Yellow = {
    new = function()
        local self = Article.new(435)
        return self
    end
}

return Yellow