local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local constants = require 'tch.constants'
local Dialogue = require 'tch.samp.dialogues.dialogue'
local Utils = require 'tch.common.utils'

local Linerunner = require 'tch.entities.vehicles.linerunner'
local Tanker = require 'tch.entities.vehicles.tanker'
local RoadTrain = require 'tch.entities.vehicles.roadtrain'

local PortLosSantos = require 'tch.entities.coords.portlossantos'
local PortSanFierro = require 'tch.entities.coords.portsanfierro'

local trucks = { 
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id 
}

local PortLosSantosCoords = PortLosSantos.new()
local PortSanFieroCoords = PortSanFierro.new()
local DISTANCE = 15 -- дистанци€ в метрах   

local Menu = {
    new = function()
        local id, title = 32700, "ƒальнобойщик | {AE433D}ћеню"
        local self = Dialogue.new(id, title)
        return self
    end,
    FLAGS = {
		IS_PARSING_CONTRACTS_LAST_STEP = false,
        CONTRACT = { IS_TAKING = false, IS_CANCELING = false, ID = 0 },
        IS_PARSING_CONTRACTS = false,
        IS_UNLOADING = false
	}
}

Menu.isSearchingAllowed = function(playerCursor, window)
    if Utils.isPlayerDriving() then
        local modelId = Utils.getPlayerCarModelId()
        return playerCursor
        and not sampIsDialogActive()
        and not sampIsChatInputActive()
        and not sampTextdrawIsExists(constants.TEXTDRAWS.CONTRACTS.PRICE) -- ебаный костыль на проверку запущенного контракта
        and Utils.in_array(modelId, trucks)
        and window
    end
end

Menu.isTakingAllowed = function(window)
    if Utils.isPlayerDriving() then
        local modelId = Utils.getPlayerCarModelId()
        return window
        and not sampIsDialogActive()
        and not sampIsChatInputActive()
        and not sampTextdrawIsExists(constants.TEXTDRAWS.CONTRACTS.PRICE) -- ебаный костыль на проверку запущенного контракта
        and Utils.in_array(modelId, trucks)
    end
end

Menu.isUnloadingAllowed = function()
    local isNearBy = (Utils.getDistanceBetweenPlayerAndCoords(PortSanFieroCoords) <= DISTANCE 
        or Utils.getDistanceBetweenPlayerAndCoords(PortLosSantosCoords) <= DISTANCE)

    if Utils.isPlayerDriving() and isNearBy then
        local modelId = Utils.getPlayerCarModelId()
        return 
        not sampIsDialogActive()
        and not sampIsChatInputActive()
        and sampTextdrawIsExists(constants.TEXTDRAWS.CONTRACTS.PRICE) -- ебаный костыль на проверку запущенного контракта
        and Utils.in_array(modelId, trucks)
    end
end

Menu.search = function()
    Menu.FLAGS.IS_PARSING_CONTRACTS = true
    sampSendChat('/tmenu')
end

Menu.take = function(id)
    Menu.FLAGS.CONTRACT.IS_TAKING = true
    Menu.FLAGS.CONTRACT.ID = id
    sampSendChat('/tmenu')
end

Menu.cancel = function()
    Menu.FLAGS.CONTRACT.IS_CANCELING = true
    sampSendChat('/tmenu')
end

Menu.load = function(id)
    sampSendChat('/tload')
end

Menu.unload = function(id)
    sampSendChat('/tunload')
end

Menu.report = function(contract)
    local message = string.format(
        "/j ¬нимание! ƒоступен контракт %d. %s -> %s [%d / %d]",
        contract.id,
        contract.source,
        contract.destination,
        contract.amount.first,
        contract.amount.second
    )
    sampSendChat(message)
end

return Menu