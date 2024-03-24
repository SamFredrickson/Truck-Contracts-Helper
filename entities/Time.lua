local Time = {
    new = function(seconds)
        local self = {}
        self.seconds = seconds

        self.toString = function()
            local data = tonumber(self.seconds)
            local format = "%02.f"

            if data <= 0 then
                data = 0
            end

            local hours = string.format(format, math.floor(data / 3600))
            local minutes = string.format(format, math.floor(data / 60 - (hours * 60)))
            local seconds = string.format(format, math.floor(data - hours * 3600 - minutes * 60))

            return string.format("%s:%s:%s", hours, minutes, seconds)
        end
        return self
    end
}

return Time