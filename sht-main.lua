local encoding = require "encoding"
local constants = require "sht.constants"
local imgui = require "mimgui"
local sampev = require "samp.events"

local InteriorUndefinedException = require "sht.samp.entities.exceptions.interiorundefinedexception"
local HouseUndefinedException = require "sht.samp.entities.exceptions.houseundefinedexception"
local SafeLastTryHackObserver = require "sht.samp.entities.observers.safelasttryhackobserver"
local HackArguments = require "sht.samp.entities.arguments.hackarguments"
local House = require "sht.samp.entities.house"
local Safe = require "sht.samp.entities.safe"
local World = require "sht.samp.entities.world"
local Game = require "sht.samp.entities.game"
local Chat = require "sht.samp.entities.chat"
local Range = require "sht.samp.entities.range"

local CustomTheme = require "sht.gui.themes.custom"
local SettingsWindow = require "sht.gui.windows.settings"
local ListWindow = require "sht.gui.windows.list.list"

local Utils = require "sht.common.utils"
local Config = require "sht.common.config"
local Log = require "sht.common.log"

local HouseInfo = require "sht.samp.dialogues.houseinfo"
local Fishing = require "sht.samp.dialogues.fishing"

encoding.default = "CP1251"
local u8 = encoding.UTF8

script_author(constants.SCRIPT_INFO.AUTHOR)
script_version(constants.SCRIPT_INFO.VERSION)
script_moonloader(constants.SCRIPT_INFO.MOONLOADER)
script_version_number(constants.SCRIPT_INFO.VERSION_NUMBER)
script_url(constants.SCRIPT_INFO.URL)
script_name(constants.SCRIPT_INFO.NAME)

local settingsWindow = SettingsWindow.new()
local listWindow = ListWindow.new()
local houseInfoDialogue = HouseInfo.new()
local fishingDialogue = Fishing.new()
local config = Config.new()

local lastEnteredHouse = nil
local isHouseSaved = false

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    CustomTheme.new()

    imgui.GetIO().Fonts:Clear()
    glyph_ranges_cyrillic = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imgui.GetIO().Fonts:AddFontFromFileTTF(
        "C:/Windows/Fonts/arial.ttf", 
        Utils.toScreenX(6), 
        nil, 
        glyph_ranges_cyrillic
    )
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("safe.settings", function()
        settingsWindow.toggle()
    end)

    sampRegisterChatCommand("safe.list", function()
        listWindow.toggle()
    end)

    sampRegisterChatCommand("safe.hack", function(args)
        if getCharActiveInterior(PLAYER_PED) <= 0 then
            InteriorUndefinedException.new().throw()
            return
        end

        if not lastEnteredHouse then
            HouseUndefinedException.new().throw()
            return
        end

        if lastEnteredHouse.safe.isActive() then
            Chat.send(constants.COMMANDS.SAFE)
            lastEnteredHouse.safe.open:run()
            return
        end

        if lastEnteredHouse.safe.isInactive() then
            local from, to = table.unpack(HackArguments.new(args).parse())
            lastEnteredHouse.safe.lastHackTryAt = os.time()
            lastEnteredHouse.safe.status = Safe.Status.PENDING
            lastEnteredHouse.safe.range = Range.new(from, to)

            if config.data.settings.logging then
                Log.info(string.format(
                    "Процесс взлома сейфа в доме №%d запущен...", 
                    lastEnteredHouse.number
                ))
            end

            if config.data.settings.antiAFK then
                Game.enableWindowMode()
            end

            if not config.data.settings.antiAFK then
                Game.disableWindowMode()
            end
            
            Chat.send(constants.COMMANDS.SAFE)
            lastEnteredHouse.safe.hack:run()
            return
        end
    end)

    while true do
       wait(-1)
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    -- Обновляем информацию о последнем доме, в который вошёл игрок
    if houseInfoDialogue.id == id then
        local number, price, class, parkingSlots, owner = table.unpack(HouseInfo.textToTable(text))
        local house = House.findByNumber(tonumber(number))
        local safe = house and house.safe or Safe.new()
        isHouseSaved = house and true or false

        SafeLastTryHackObserver.new().observe(safe)

        lastEnteredHouse = House.new(
            number, 
            price, 
            class, 
            parkingSlots, 
            owner,
            safe
        )
    end
end

function sampev.onServerMessage(color, text)
    if lastEnteredHouse then
        if text:find("Сейф открывается") and lastEnteredHouse.safe.isPending() then
            if not isHouseSaved then
                lastEnteredHouse.safe.status = Safe.Status.ACTIVE
                local house = House.add(lastEnteredHouse)
            end

            if config.data.settings.logging then
                Log.info(string.format(
                    "Сейф в доме %d успешно взломан! Пин-код: %s",
                    lastEnteredHouse.number,
                    lastEnteredHouse.safe.code
                ))
            end

            if config.data.settings.quitIfSafeWasHacked then 
                Game.exit() 
            end
            Game.disableWindowMode()
            return
        end
        if text:find("Вы далеко от сейфа") and lastEnteredHouse.safe.isPending() then
            lastEnteredHouse.safe.status = Safe.Status.INACTIVE
            Game.disableWindowMode()
            return
        end
        if text:find("Не флуди") and lastEnteredHouse.safe.isPending() then
            Chat.send(constants.COMMANDS.SAFE)
            lastEnteredHouse.safe.hack:run()
            return
        end
        if text:find("Пин%-код не совпал") and lastEnteredHouse.safe.isPending() then
            if config.data.settings.quitIfOwnerIsInStream then
                for _, player in pairs(World.getPlayers()) do
                    if player.name == lastEnteredHouse.owner then
                        Game.exit()
                    end
                end
            end
            if config.data.settings.quitIfWhoeverIsInStream then
                for _, player in pairs(World.getPlayers()) do
                    if player.name ~= World.getMainPlayer().name then
                        Game.exit()
                    end
                end
            end
            if config.data.settings.eatDrugsIfCharHealthIs > 0 then
                local player = World.getMainPlayer()
                if player and player.health <= config.data.settings.eatDrugsIfCharHealthIs then
                    constants.FLAGS.EATING = true
                    lastEnteredHouse.safe.status = Safe.Status.INACTIVE
                    Chat.send(constants.COMMANDS.DRUGS, 2000)
                end
            end

            if config.data.settings.eatFishIfCharHealthIs > 0 then
                local player = World.getMainPlayer()
                if player and player.health <= config.data.settings.eatFishIfCharHealthIs then
                    constants.FLAGS.EATING = true
                    lastEnteredHouse.safe.status = Safe.Status.INACTIVE
                    Chat.send(constants.COMMANDS.FISH, 2000)
                end
            end

            lastEnteredHouse.safe.lastHackTryAt = os.time()
            lastEnteredHouse.safe.range.increment()
            
            if lastEnteredHouse.safe.range.isOutOfRange() then
                lastEnteredHouse.safe.status = Safe.Status.INACTIVE
                Game.disableWindowMode()
                return
            end

            if config.data.settings.logging then
                Log.info(string.format(
                    "Пин-код %s в доме №%d не совпал, идем дальше...",
                    lastEnteredHouse.safe.code,
                    lastEnteredHouse.number
                ))
            end

            Chat.send(constants.COMMANDS.SAFE)
            lastEnteredHouse.safe.hack:run()
            return
        end
        if text:find("Пин%-код для сейфа не установлен.") and lastEnteredHouse.safe.isPending() then
            lastEnteredHouse.safe.status = Safe.Status.INACTIVE
        end
    end

    if text:find("употребил растительный наркотик") and constants.FLAGS.EATING then
        constants.FLAGS.EATING = false
        lastEnteredHouse.safe.status = Safe.Status.PENDING
        Chat.send(constants.COMMANDS.SAFE, 1000)
        lastEnteredHouse.safe.hack:run()
    end

    if text:find("Недостаточно растительных наркотиков") and constants.FLAGS.EATING then
        constants.FLAGS.EATING = false
        lastEnteredHouse.safe.status = Safe.Status.PENDING
        Chat.send(constants.COMMANDS.SAFE, 1000)
        lastEnteredHouse.safe.hack:run()
    end
    
    if text:find("Недостаточно рыбы") and constants.FLAGS.EATING then
        constants.FLAGS.EATING = false
        lastEnteredHouse.safe.status = Safe.Status.PENDING
        Chat.send(constants.COMMANDS.SAFE, 1000)
        lastEnteredHouse.safe.hack:run()
    end
end