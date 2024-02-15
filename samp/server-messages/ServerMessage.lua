local ServerMessage = {
    new = function(message, code)
        local self = {}
        self.message = message
        self.code = code
        return self
    end
}

return ServerMessage