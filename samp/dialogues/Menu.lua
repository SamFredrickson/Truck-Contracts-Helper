local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local constants = require 'tch.constants'
local Dialogue = require 'tch.samp.dialogues.dialogue'
local Utils = require 'tch.common.utils'

local Linerunner = require 'tch.entities.vehicles.linerunner'
local Tanker = require 'tch.entities.vehicles.tanker'
local RoadTrain = require 'tch.entities.vehicles.roadtrain'

local trucks = { Linerunner.new().id, Tanker.new().id, RoadTrain.new().id }

local Menu = {
    new = function()
        local id, title = 32700, "Дальнобойщик | {AE433D}Меню"
        local self = Dialogue.new(id, title)
        return self
    end,
    FLAGS = {
		IS_PARSING_CONTRACTS_LAST_STEP = false,
        CONTRACT = { IS_TAKING = false, ID = 0 },
        IS_PARSING_CONTRACTS = false
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

Menu.search = function()
    Menu.FLAGS.IS_PARSING_CONTRACTS = true
    sampSendChat('/tmenu')
end

Menu.take = function(id)
    Menu.FLAGS.CONTRACT.IS_TAKING = true
    Menu.FLAGS.CONTRACT.ID = id
    sampSendChat('/tmenu')
end

Menu.load = function(id)
    sampSendChat('/tload')
end

Menu.report = function(contract)
    local message = string.format(
        "/j Внимание! Доступен контракт %d. %s -> %s [%d / %d]",
        contract.id,
        contract.source,
        contract.destination,
        contract.amount.first,
        contract.amount.second
    )
    sampSendChat(message)
end

return Menu