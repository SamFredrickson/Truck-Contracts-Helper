local Contract = require "tch.entities.contracts.contract"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local PointsService = require "tch.services.pointsservice"
local constants = require "tch.constants"
local encoding = require "encoding"

local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"
local Volvo = require "tch.entities.vehicles.volvo"

local PortLosSantos = require "tch.entities.coords.portlossantos"
local PortSanFierro = require "tch.entities.coords.portsanfierro"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local playerService = PlayerService.new()
local carsService = CarService.new()
local pointsService = PointsService.new()

local trucks = { 
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id,
    Volvo.new().id
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

            table.sort(list, function(a, b)
                return a.sort < b.sort
            end)

            return list
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
            local data = pointsService.get()
            for _, value in pairs(data) do
                if source:find(value.point.source) and destination:find(value.point.destination) then
                    return { value.point.sort, value.point.top }
                end
            end
        end

        self.getContractByAutoloadPoint = function(point, contracts)
            if not point or #contracts <= 0 then
                return false
            end

            for _, contract in pairs(contracts) do
                if point.source:find(contract.source) then
                    return contract
                end
            end

            return false
        end

        self.CanAutotake = function(point)
            if not point then
                return false
            end

            local cars = carsService.get()
            local players = playerService.get()

            local player = playerService.getByHandle(
                players, 
                PLAYER_PED
            )

            for _, driver in pairs(players) do
                local car = carsService.getByDriver(cars, driver)
                if car 
                and in_array(car.model, trucks) 
                and driver.IsWithinDistance(point.coords, 50)
                and driver.handle ~= player.handle then
                    return false
                end
            end

            return true
        end

        return self
    end
}

ContractService.CONTRACTS = {}
return ContractService