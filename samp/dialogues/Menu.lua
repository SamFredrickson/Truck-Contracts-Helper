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
        local id, title = 32700, "ƒальнобойщик | {AE433D}ћеню"
        local self = Dialogue.new(id, title)
        return self
    end,
    FLAGS = {
		IS_PARSING_CONTRACTS_LAST_STEP = false,
        IS_TAKING_CONTRACT = false,
        IS_PARSING_CONTRACTS = false
	}
}

function isParsingAllowed()
    if isCharInAnyCar(PLAYER_PED) then
        local modelId = Utils.getPlayerCarModelId()
        return hideCursor
        and not sampIsDialogActive()
        and not sampIsChatInputActive()
        and not sampTextdrawIsExists(constants.TEXTDRAWS.CONTRACTS.PRICE) -- ебаный костыль на проверку запущенного контракта
        and Utils.in_array(modelId, trucks)
        and self.window[0]
    end
    return false
end

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

Menu.search = function()
    Menu.FLAGS.IS_PARSING_CONTRACTS = true
    sampSendChat('/tmenu')
end

return Menu