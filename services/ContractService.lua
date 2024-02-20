local Contract = require "tch.entities.contracts.contract"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local constants = require "tch.constants"
local encoding = require "encoding"

local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"

local PortLosSantos = require "tch.entities.coords.portlossantos"
local PortSanFierro = require "tch.entities.coords.portsanfierro"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local playerService = PlayerService.new()
local carsService = CarService.new()

local trucks = { 
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id 
}

local portLosSantos = PortLosSantos.new()
local portSanFierro = PortSanFierro.new()

local ContractService = {
    new = function()
        local self = Service.new()

        self.make = function(text)
            local list = {}
            for contract in text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS) do
                local id, source, destination, cargo, amountFirst, amountSecond, company 
                    = contract:match(constants.REGEXP.SINGLE_CONTRACT)
        
                local amount = { 
                    first = amountFirst, 
                    second = amountSecond 
                }
                
                local priorities = self.getPriorities(source, destination)
                local sort, top = table.unpack(priorities)
        
                local entity = Contract.new(
                    id,
                    sort,
                    top,
                    source,
                    destination,
                    cargo,
                    amount,
                    company
                )

                table.insert(list, entity)
            end
            return self.sort(list)
        end

        self.findById = function(id, contracts)
            for _, contract in pairs(contracts) do
                local contractId = tonumber(contract.id)
                if contractId == id then
                    return contract
                end
            end
            return false
        end

        self.findActive = function(contracts)
            for _, contract in pairs(contracts) do
                if contract.IsActive then
                    return contract
                end
            end
            return false
        end

        self.CanTake = function(contracts)
            local player = playerService.getByHandle(
                playerService.get(), 
                PLAYER_PED
            )
        
            local car = carsService.getByDriver(
                carsService.get(),
                player
            )
        
            if car and in_array(car.model, trucks) then
                return #contracts > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive(contracts)
            end
        
            return false
        end

        self.CanSearch = function(contracts)
            local player = playerService.getByHandle(
                playerService.get(), 
                PLAYER_PED
            )
        
            local car = carsService.getByDriver(
                carsService.get(),
                player
            )
        
            if car and in_array(car.model, trucks) then
                return not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive(contracts)
            end
        
            return false
        end

        self.CanUnload = function(contracts)
            local cars = carsService.get()
            local players = playerService.get()

            local player = playerService.getByHandle(
                players, 
                PLAYER_PED
            )
        
            local car = carsService.getByDriver(
                cars,
                player
            )

            if car and in_array(car.model, trucks) then
                return #contracts > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and self.findActive(contracts)
                and carsService.IsCarAttachedToTrailer(cars, car)
                and (player.IsWithinDistance(portLosSantos, constants.CONFIG.DEFAULT_SETTINGS.unloadDistance) 
                or player.IsWithinDistance(portSanFierro, constants.CONFIG.DEFAULT_SETTINGS.unloadDistance))
            end
        
            return false
        end

        self.update = function(id, fields, contracts)
            for index, contract in pairs(contracts) do
                local contractId = tonumber(contract.id)
                if contractId == id then
                    for key, value in pairs(fields) do 
                        contracts[index][key] = value 
                    end
                    return contract
                end
            end
            return false
        end

        self.getPriorities = function(source, destination)
            for _, value in pairs(constants.CONTRACTS) do
                if source:find(value.source) and destination:find(value.destination) then
                    return { value.sort, value.top }
                end
            end
            return { 10, false }
        end

        self.sort = function(contracts)
            table.sort(contracts, function(a, b)
                return a.sort < b.sort
            end)
            return contracts
        end

        return self
    end
}

ContractService.CONTRACTS = {}
return ContractService