local Service = {
    new = function()
        local self = {}

        self.get = function()
            error("Abstract method 'get' is not callable")
        end

        return self
    end
}
return Service