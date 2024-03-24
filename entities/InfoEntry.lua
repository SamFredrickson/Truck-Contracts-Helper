local InfoEntry = {
    new = function(title, value)
        local self = {}
        self.title = title
        self.value = value
        return self
    end
}

return InfoEntry