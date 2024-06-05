local String = {
    new = function(string)
        local self = {}
        self.string = string
        return self
    end
}

String.includes = function(needle, array)
    for _, value in pairs(array) do
        if needle == value then
            return true
        end
    end
    return false
end

return String