local Contract = require "tch.entities.contracts.contract"
local Service = require "tch.services.service"
local PlayerService = require "tch.services.playerservice"
local CarService = require "tch.services.carservice"
local PointsService = require "tch.services.pointsservice"
local Filters = require "tch.common.storage.filters"
local constants = require "tch.constants"
local encoding = require "encoding"
local Array = require "tch.common.array"
require "tch.common.lua-string"

local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"
local Volvo = require "tch.entities.vehicles.volvo"

local PortLosSantos = require "tch.entities.coords.portlossantos"
local OilRefineryOne = require "tch.entities.coords.oilrefineryone"
local PortSanFierro = require "tch.entities.coords.portsanfierro"
local AirportSanFierro = require "tch.entities.coords.airportsanfierro"
local AirportLasVenturas = require "tch.entities.coords.airportlasventuras"
local AirportLosSantos = require "tch.entities.coords.airportlossantos"
local PortGarageSanFierro = require "tch.entities.coords.portgaragesanfierro"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local playerService = PlayerService.new()
local carsService = CarService.new()
local pointsService = PointsService.new()
local CONTRACTS = {}
local PINS = Array({})

local trucks = { 
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id,
    Volvo.new().id
}

local oilRefineryOne = OilRefineryOne.new()
local portLosSantos = PortLosSantos.new()
local portSanFierro = PortSanFierro.new()
local airportSanFierro = AirportSanFierro.new()
local airportLasVenturas = AirportLasVenturas.new()
local airportLosSantos = AirportLosSantos.new()
local portGarageSanFierro = PortGarageSanFierro.new()

local points = {
   legal = {
    portLosSantos = portLosSantos, 
    portSanFierro = portSanFierro,
    oilRefineryOne = oilRefineryOne
   },
   illegal = {
        airportSanFierro = airportSanFierro,
        airportLasVenturas = airportLasVenturas,
        airportLosSantos = airportLosSantos,
        portGarageSanFierro = portGarageSanFierro
    }
}

local ContractService = {
    new = function()
        local self = Service.new()
        self.hasUnknownActiveContract = false

        self.parse = function(text)
            local result = Array({})
            local filters = Filters.new()
            local foundContractIdPins = Array({})
            for contract in text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS) do
                local isAllowed = false
                local singleContractRegexp = constants.REGEXP.SINGLE_CONTRACT;
                local id, source, destination, cargo, amountFirst, amountSecond, company = contract:match(singleContractRegexp)
                local amount = { first = amountFirst, second = amountSecond }
                local priorities = self.getPriorities(source, destination)
                local sort, top = table.unpack(priorities)
                local entity = Contract.new(id, sort, top, source, destination, cargo, amount, company)

                -- Проверяем является ли контракт скрытым
                local isSource = 
                (
                    function()
                        for _, filterSource in pairs(filters.data.sources) do
                            if source:find(filterSource.name) then
                               for _, filterDestination in pairs(filterSource.destinations) do
                                    local isDestination = destination:find(filterDestination.short_name)
                                    if not filterDestination.hidden and isDestination then return true end
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
                        if (filters.data.company):isblank() or (filters.data.company):isempty() then return true end
                        local companies = Array((filters.data.company):split(",")):Map(function(company) return company:trim() end)
                        return companies:Includes((entity.company):lower():trim())
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

                if (isSource and isCompany and isProperTonQuantity) or isTop then result:Push(entity) end
            end

            if (result:Length() <= 1) then return result end

             -- Синхронизация пинов
            for index, pinContract in PINS:Entries() do
                for contract in result:Values() do
                    local isDestination = contract.destination:find(pinContract.destination)
                    local isSource = contract.source:find(pinContract.source)
                    local isSecondAmount = tonumber(pinContract.amount.second) == tonumber(contract.amount.second)
                    local isCompany = pinContract.company == contract.company
                    local isFound = (isDestination and isSource and isSecondAmount and isCompany)
                    if isFound then PINS[index] = contract contract.IsPinned = true contract.sort = 0 end
                end
            end

            local contractsGroup = result:Reduce
            (
                function(acc, current)
                    if not acc[current.sort] then acc[current.sort] = Array({}) end
                    acc[current.sort]:Push(current)
                    return acc
                end, 
                Array({})
            ) or Array({})

            local contractsGroupKeys =
            (
                function()
                    local result = Array({})
                    for index, _ in pairs(contractsGroup) do result:Push(index) end
                    return result:Sort()
                end
            )()

            local result = 
            (
                function()
                    local result = Array({})
                    for _, contractsGroupKey in pairs(contractsGroupKeys) do
                        local sortedContracts = contractsGroup[contractsGroupKey]:Sort(function(a, b) return tonumber(a.amount.first) < tonumber(b.amount.first) end)
                        for _, contract in pairs(sortedContracts) do result:Push(contract) end
                    end
                    return result
                end
            )()

            return result
        end

        self.setContracts = function(contracts)
            CONTRACTS = contracts
            return CONTRACTS
        end

        self.getContracts = function(contracts)
           return CONTRACTS
        end

        self.pin = function(contract)
            PINS = PINS:Filter(function(current) return tonumber(current.id) ~= tonumber(contractId) end)
            PINS:Push(contract)
            return PINS
        end

        self.unpin = function(contractId)
            PINS = PINS:Filter(function(current) return tonumber(current.id) ~= tonumber(contractId) end)
            return PINS
        end

        self.findById = function(id)
            for _, contract in pairs(CONTRACTS) do
                local contractId = tonumber(contract.id)
                if contractId == id then return contract end
            end
            return false
        end

        self.findActive = function()
            for _, contract in pairs(CONTRACTS) do if contract.IsActive then return contract end end
            return false
        end

        self.CanTake = function()
            local cars = carsService.get()
            local players = playerService.get()
            local player = playerService.getByHandle(players, PLAYER_PED)
            local car = carsService.getByDriver(cars, player)
        
            if car and car.IsTruck() then
                return #CONTRACTS > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive()
            end
        
            return false
        end

        self.CanSearch = function()
            local cars = carsService.get()
            local players = playerService.get()
            local player = playerService.getByHandle(players, PLAYER_PED)
            local car = carsService.getByDriver(cars, player)
        
            if car and car.IsTruck() then
                return not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive()
                and not self.findAvailableToTake()
            end
        
            return false
        end

        self.CanUnload = function()
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
                if #CONTRACTS > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and self.findActive()
                and carsService.IsCarAttachedToTrailer(cars, car)
                and isWithinDistance then return true end
            end

            -- Проверка разгрузки неопределенного груза (если игрок перезагрузил скрипт во время активного контракта)
            if car and car.IsTruck() then
                if not sampIsDialogActive()
                and not sampIsChatInputActive()
                and carsService.IsCarAttachedToTrailer(cars, car)
                and isWithinDistance
                and self.hasUnknownActiveContract then return true end
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
        
            return false
        end

        self.update = function(id, fields)
            for index, contract in pairs(CONTRACTS) do
                local contractId = tonumber(contract.id)
                if contractId == id then
                    for key, value in pairs(fields) do CONTRACTS[index][key] = value end
                    return contract
                end
            end
            return false
        end

        self.getPriorities = function(source, destination)
            local data = pointsService.get()
            for _, value in pairs(data) do
                local isSource = source:find(value.point.source)
                local isDestination = destination:find(value.point.destination)
                if isSource and isDestination then return { value.point.sort, value.point.top } end
            end
        end

        self.findAvailableToTake = function()
           local player = playerService.getByHandle(playerService.get(), PLAYER_PED)
            for _, point in pairs(constants.AUTOLOAD_POINTS) do
                if player.IsWithinDistance(point.coords, point.autoTakeDistance) then
                    for _, contract in pairs(CONTRACTS) do if point.source:find(contract.source) then return contract end end
                    return false
                end
            end
            return false
        end

        return self
    end
}

return ContractService