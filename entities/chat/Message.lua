local Message = {
    new = function(text, delay)
        local self = {}
        self.type = "GLOBAL"
        self.text  = text
        self.delay = delay
        return self
    end
}

return Message