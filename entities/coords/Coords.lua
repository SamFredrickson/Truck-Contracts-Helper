local Coords = {
    new = function(x, y, z)
        local self = {}

        self.x = x
        self.y = y
        self.z = z

        return self
    end
}

return Coords