local InfoEntry = {
    new = function(title, code, value)
        local self = {}
        self.title = title
        self.code = code
        self.value = value
        return self
    end
}

return InfoEntry