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

local function eachContractRow(text)
    local rows = text:gmatch(constants.REGEXP.MULTIPLE_CONTRACTS)
    return function()
        for row in rows do
            local id, source, destination, cargo, first, second, company = row:match(constants.REGEXP.SINGLE_CONTRACT)
            if id then return tonumber(id), source, destination, cargo, first, second, company end
        end
    end
end

local function allowsRoute(filters, source, destination)
    for _, filterSource in pairs(filters.sources) do
        if source:find(filterSource.name) then
            for _, filterDestination in pairs(filterSource.destinations) do
                if not filterDestination.hidden and destination:find(filterDestination.short_name) then return true end
            end
        end
    end
    return false
end

local function restorePins(contracts)
    for index, pin in PINS:Entries() do
        local match
        for _, contract in ipairs(contracts) do
            if not contract.IsPinned and contract.destination:find(pin.destination)
            and contract.source:find(pin.source) and tonumber(pin.amount.second) == tonumber(contract.amount.second)
            and pin.company == contract.company then
                match = match or contract
                if contract.id == pin.id then
                    match = contract
                    break
                end
            end
        end
        if match then
            PINS[index] = match
            match.IsPinned = true
            match.sort = 0
        end
    end
end

local function sortContracts(contracts)
    local originalOrder = {}
    for i, contract in ipairs(contracts) do originalOrder[contract] = i end
    table.sort(contracts, function(a, b)
        if a.sort ~= b.sort then return a.sort < b.sort end
        local firstA, firstB = tonumber(a.amount.first), tonumber(b.amount.first)
        if firstA ~= firstB then return firstA < firstB end
        return originalOrder[a] < originalOrder[b]
    end)
end

local ContractService = {
    new = function()
        local self = Service.new()
        self.hasUnknownActiveContract = false

        self.parse = function(text)
            local result = Array({})
            local filters = Filters.new().data
            local routePoints = pointsService.get()
            local companies
            if not filters.company:isblank() and not filters.company:isempty() then
                companies = {}
                for _, company in ipairs(filters.company:split(",")) do
                    companies[company:trim()] = true
                end
            end
            for id, source, destination, cargo, first, second, company in eachContractRow(text) do
                local sort, top = table.unpack(self.getPriorities(source, destination, routePoints))
                if (filters.top and top) or (tonumber(first) > filters.minTonsQuantity
                and (not companies or companies[company:lower():trim()]) and allowsRoute(filters, source, destination)) then
                    result:Push(Contract.new(id, sort, top, source, destination, cargo, { first = first, second = second }, company))
                end
            end
            restorePins(result)
            sortContracts(result)
            return result
        end

        self.findMatchingContract = function(selected)
            local current = self.findById(tonumber(selected.id))
            if current and current.source == selected.source and current.destination == selected.destination
            and current.cargo == selected.cargo and tonumber(current.amount.second) == tonumber(selected.amount.second)
            and current.company:trim() == selected.company:trim() then
                return current
            end
        end

        self.findDialogRow = function(text, selected)
            for id, source, destination, cargo, _, second, company in eachContractRow(text) do
                if id > 0 and id == tonumber(selected.id) and source == selected.source and destination == selected.destination
                and cargo == selected.cargo and tonumber(second) == tonumber(selected.amount.second)
                and company:trim() == selected.company:trim() then
                    return id - 1
                end
            end
        end

        self.setContracts = function(contracts)
            CONTRACTS = contracts
            return CONTRACTS
        end

        self.getContracts = function(contracts)
           return CONTRACTS
        end

        self.pin = function(contract)
            PINS = PINS:Filter(function(current) return tonumber(current.id) ~= tonumber(contract.id) end)
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
            if carsService.getDrivenTruck() then
                return #CONTRACTS > 0
                and not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive()
            end
        
            return false
        end

        self.CanSearch = function()
            if carsService.getDrivenTruck() then
                return not sampIsDialogActive()
                and not sampIsChatInputActive()
                and not self.findActive()
                and not self.findAvailableToTake()
            end
        
            return false
        end

        self.CanUnload = function()
            if sampIsDialogActive() or sampIsChatInputActive() then
                return false
            end

            local car = carsService.getDrivenTruck()
            if not car then return false end
            local x, y, z = getCharCoordinates(PLAYER_PED)
            local distance = constants.CONFIG.DEFAULT_SETTINGS.unloadDistance
            local function isNearPoint(group)
                for _, point in pairs(group) do
                    if getDistanceBetweenCoords3d(x, y, z, point.x, point.y, point.z) <= distance then
                        return true
                    end
                end
                return false
            end

            local hasLegalCargo = self.hasUnknownActiveContract or self.findActive()
            if not isNearPoint(points.illegal) and not (hasLegalCargo and isNearPoint(points.legal)) then
                return false
            end

            return carsService.hasAttachedTrailer(car)
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

        self.getPriorities = function(source, destination, routePoints)
            for _, value in ipairs(routePoints or pointsService.get()) do
                local isSource = source:find(value.point.source)
                local isDestination = destination:find(value.point.destination)
                if isSource and isDestination then return { value.point.sort, value.point.top } end
            end
            return { math.huge, false }
        end

        self.findAvailableToTake = function()
            local player = playerService.getLocalPlayer()
            if not player then return false end
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