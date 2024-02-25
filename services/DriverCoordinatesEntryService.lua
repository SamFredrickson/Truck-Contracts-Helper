local Service = require "tch.services.service"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local DriverCoordinatesEntryService = {
    new = function()
        local self = Service.new()
        
        self.get = function(entries)
            return entries
        end

        self.create = function(entries, entry)
            table.insert(entries, entry)
        end
        
        self.update = function(entries, id, fields)
            for index, entry in pairs(entries) do
                if index == id then
                    for field, value in pairs(fields) do
                        entries[index][field] = value
                    end
                    return entry
                end
            end
            return false
        end

        self.delete = function(entries, id)
            table.remove(entries, id)
        end

        self.findByNickname = function(entries, nickname)
            for index, entry in pairs(entries) do
                if entry.nickname == nickname then
                    return { id = index, item = entry }
                end
            end
            return false
        end

        return self
    end
}

DriverCoordinatesEntryService.ENTRIES = {}

return DriverCoordinatesEntryService