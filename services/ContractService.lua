local Contract = require "tch.entities.contracts.contract"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local PointsService = require "tch.services.pointsservice"
local Filters = require "tch.common.storage.filters"
local constants = require "tch.constants"
local encoding = require "encoding"

local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"
local Volvo = require "tch.entities.vehicles.volvo"

local PortLosSantos = require "tch.entities.coords.portlossantos"
local PortSanFierro = require "tch.entities.coords.portsanfierro"
local AirportSanFierro = require "tch.entities.coords.airportsanfierro"
local AirportLasVenturas = require "tch.entities.coords.airportlasventuras"
local AirportLosSantos = require "tch.entities.coords.airportlossantos"

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
local airportSanFierro = AirportSanFierro.new()
local airportLasVenturas = AirportLasVenturas.new()
local airportLosSantos = AirportLosSantos.new()

local points = 
{
   legal = {
        portLosSantos = portLosSantos,
        portSanFierro = portSanFierro
   },
   illegal = {
        airportSanFierro = airportSanFierro,
        airportLasVenturas = airportLasVenturas,
        airportLosSantos = airportLosSantos
   }
}

local ContractService = {
    new = function()
        local self = Service.new()

        self.parse = function(text)
            local list = {}
            local filters = Filters.new()
            for contract in text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS) do
                local isAllowed = false
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

                -- Проверяем является ли контракт скрытым
                local isSource = 
                (
                    function()
                        for _, filterSource in pairs(filters.data.sources) do
                            if source:find(filterSource.name) then
                               for _, filterDestination in pairs(filterSource.destinations) do
                                    if not filterDestination.hidden 
                                    and destination:find(filterDestination.short_name) then return true end
                               end
                            end
                        end
                        return false
                    end
                )()

                -- Проверяем на название компании
                local isCompany = 
                (
                    function()
                        if filters.data.company == nil or #string.gsub(filters.data.company, "^%s*(.-)%s*$", "%1") == 0 then return true end
                        if filters.data.company:find(entity.company:lower()) then return true end
                        return false
                    end
                )()
                
                -- Проверяем на количество тонн
                local isProperTonQuantity =
                (
                    function()
                        if tonumber(entity.amount.first) > filters.data.minTonsQuantity then return true end
                        return false
                    end
                )()

                -- Проверяем на метку топ (всегда показывать лучшие контракты)
                local isTop = 
                (
                    function()
                        if filters.data.top and entity.top then return true end
                        return false
                    end
                )()

                if (isSource and isCompany and isProperTonQuantity) or isTop then 
                    table.insert(list, entity) 
                end
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
            local cars = carsService.get()
            local players = playerService.get()

            local player = playerService.getByHandle(players, PLAYER_PED)
            local car = carsService.getByDriver(cars, player)
        
            if car and car.IsTruck() then
                return #contracts > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive(contracts)
            end
        
            return false
        end

        self.CanSearch = function(contracts)
            local cars = carsService.get()
            local players = playerService.get()

            local player = playerService.getByHandle(players, PLAYER_PED)
            local car = carsService.getByDriver(cars, player)
        
            if car and car.IsTruck() then
                return not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive(contracts)
            end
        
            return false
        end

        self.CanUnload = function(contracts)
            local cars = carsService.get()
            local players = playerService.get()

            local player = playerService.getByHandle(players, PLAYER_PED)
            local car = carsService.getByDriver(cars, player)
        
            -- Проверка разгрузки обычного груза
            local isWithinDistance = 
            (
                function()
                    local distance = constants.CONFIG.DEFAULT_SETTINGS.unloadDistance
                    for _, point in pairs(points.legal) do
                        if player.IsWithinDistance(point, distance) then return true end
                    end
                   return false
                end
            )()

            if car and car.IsTruck() then
                if #contracts > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and self.findActive(contracts)
                and carsService.IsCarAttachedToTrailer(cars, car)
                and isWithinDistance then return true end
            end

            -- Проверка разгрузки нелегального груза
            local isWithinDistance = 
            (
                function()
                    local distance = constants.CONFIG.DEFAULT_SETTINGS.unloadDistance
                    for _, point in pairs(points.illegal) do
                        if player.IsWithinDistance(point, distance) then return true end
                    end
                   return false
                end
            )()

            if car and car.IsTruck() then
                if not sampIsDialogActive()
                and not sampIsChatInputActive()
                and carsService.IsCarAttachedToTrailer(cars, car)
                and isWithinDistance then return true end
            end

            if car and car.IsTruck() then
                if not sampIsDialogActive()
                and not sampIsChatInputActive()
                and carsService.IsCarAttachedToTrailer(cars, car)
                and isWithinDistance
                and ContractService.hasUnknownActiveContract then return true end
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
            if not point or #contracts <= 0 then return false end
            for _, contract in pairs(contracts) do
                if point.source:find(contract.source) then return contract end
            end
            return false
        end

        self.CanAutotake = function(point)
            if not point then return false end
            local cars = carsService.get()
            local players = playerService.get()
            local player = playerService.getByHandle(players, PLAYER_PED)

            for _, driver in pairs(players) do
                local car = carsService.getByDriver(cars, driver)
                local isWithinDistance = driver.IsWithinDistance(point.coords, point.autoTakeDistance)

                if car
                and car.IsTruck() 
                and driver.handle ~= player.handle
                and isWithinDistance then return false end
            end

            return true
        end

        return self
    end
}

ContractService.CONTRACTS = {}
return ContractService