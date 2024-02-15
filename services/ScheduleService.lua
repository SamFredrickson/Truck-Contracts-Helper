local Service = require "tch.services.service"

local ScheduleService = {
    new = function()
        local self = Service.new()

        self.create = function(anonymousFunction, seconds)
            return lua_thread.create_suspended(function()
                while true do
                    wait(seconds or 0)
                    anonymousFunction()
                end
            end)
        end

        return self
    end
}

return ScheduleService