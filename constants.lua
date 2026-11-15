local encoding = require "encoding"
local Array = require "tch.common.array"
local Linerunner = require "tch.entities.vehicles.linerunner"
local Tanker = require "tch.entities.vehicles.tanker"
local RoadTrain = require "tch.entities.vehicles.roadtrain"
local Volvo = require "tch.entities.vehicles.volvo"
local Peterbilt = require "tch.entities.vehicles.peterbilt"
local Kenworth = require "tch.entities.vehicles.kenworth"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local SCRIPT_INFO = {
    AUTHOR = "SAM",
    VERSION = "1.15.0",
    MOONLOADER = 026,
    VERSION_NUMBER = 25,
    VERSION_URL = "https://raw.githubusercontent.com/SamFredrickson/Truck-Contracts-Helper/master/version.json",
    CHANGELOG_URL = "https://github.com/SamFredrickson/Truck-Contracts-Helper/blob/master/CHANGELOG.md",
    URL = "https://github.com/SamFredrickson/Truck-Contracts-Helper",
}

local COLORS = {
	RED = 0xFF0000,
	GREEN = 0x00FF00,
	GOLD = 0xFFD700,
	SEASHELL = 0xFFF5EE,
	PINK = 0xFFC0CB,
    DARK_GRAY = 0xBABABA
}

local TRUCKS = {
    Linerunner.new().id, 
    Tanker.new().id, 
    RoadTrain.new().id,
	Volvo.new().id,
    Peterbilt.new().id,
    Kenworth.new().id
}

local REGEXP = {
    MULTIPLE_CONTRACTS = "({.-}%d+%. {.-}%W+ №%d %-%> %W+..{.-}%W+{.-}%d+ из %d+ т%.	{.-}[%w\128-\255-%s]+)",
    SINGLE_CONTRACT = "{.-}(%d+)%. {.-}(%W+ №%d+) %-%> (.+){.-}(%W+){.-}(%d+) из (%d+) т%.	{.-}([%w\128-\255-%s]+)"
}

local TRAILERS = { 435, 450, 591, 584 }
local MAX_TRUCK_DRIVER_LEVEL = 26
local MIN_CONTRACTS_SIZE = 1
local MAX_CONTRACTS_SIZE = 16
local MIN_TONS_QUANTITY = 0
local MAX_TONS_QUANTITY = 1600

local CONFIG = {
    PATH = "tch/settings.ini",
    DEFAULT_SETTINGS = {
        truckRentedChoice = 0,
        selectedScriptStatus = 1,
        clistChoice = 16,
        documentsDialogue = false,
        autounload = true,
        drift = false,
        unloadDistance = 15,
        autolock = false,
        autohideContractsList = false,
        autoload = false,
        totalEarnings = 0,
        sessionEarnings = 0,
        sessionEarningsGame = "",
        sessionRaceQuantity = 0,
        sessionExperience = 0,
        lastIllegalCargoUnloadedAt = 0,
        statistics = true,
        contractsScreenX = nil,
        contractsScreenY = nil,
        transparentContracts = true,
        autorepair = false,
        autorefill = false,
        autoHotDog = false,
        repairPrice = 100,
        refillPrice = 20000,
        hotPrice = 10000,
        cameraLines = true,
        linesColor = 0xFFFF0000,
        linesWidth = 1,
        transparentCorpses = true,
        contractWindowTypes = 0
    }
}

local MECHANIC = {
    MIN_REPIAR_PRICE = 100,
    MAX_REPAIR_PRICE = 10000,
    MIN_REFILL_PRICE = 1,
    MAX_REFILL_PRICE = 500000
}

local HOTDOG = {
    MIN_PRICE = 1,
    MAX_PRICE = 10000
}

local CONTRACTS = {
    { source = "Нефтезавод №2", destination = "Порт СФ", sort = 1, top = true },
    { source = "Нефтевышка №1", destination = "Нефтезавод №1", sort = 2, top = true },
    { source = "Нефтевышка №2", destination = "Нефтезавод №1", sort = 3, top = true },
    { source = "Нефтевышка №3", destination = "Нефтезавод №1", sort = 4, top = true },
    { source = "Склад угля №2", destination = "Порт СФ", sort = 5, top = true },
    { source = "Лесопилка №1", destination = "Порт СФ", sort = 6, top = true },
    { source = "Лесопилка №2", destination = "Порт СФ", sort = 7, top = true },
    { source = "Строительный завод №1", destination = "Порт СФ", sort = 8, top = true },
    { source = "Строительный завод №1", destination = "Порт ЛС", sort = 9, top = false },
    { source = "Лесопилка №1", destination = "Порт ЛС", sort = 10, top = false },
    { source = "Лесопилка №2", destination = "Порт ЛС", sort = 11, top = false },
    { source = "Склад угля №2", destination = "Порт ЛС", sort = 12, top = false }
}

local PROFIT_AND_LOSS = {
    { name = "Нефтезавод №1", sum = 0, profit = true, enabled = true, sort = 1 },
    { name = "Нефтезавод №2", sum = 0, profit = true, enabled = true, sort = 2 },
    { name = "Нефтевышка №1", sum = 0, profit = true, enabled = true, sort = 3 },
    { name = "Нефтевышка №2", sum = 0, profit = true, enabled = true, sort = 4 },
    { name = "Нефтевышка №3", sum = 0, profit = true, enabled = true, sort = 5 },
    { name = "Склад угля №1", sum = 0, profit = true, enabled = true, sort = 6 },
    { name = "Склад угля №2", sum = 0, profit = true, enabled = true, sort = 7 },
    { name = "Лесопилка №1", sum = 0, profit = true, enabled = true, sort = 8 },
    { name = "Лесопилка №2", sum = 0, profit = true, enabled = true, sort = 9 },
    { name = "Строительный завод №1", sum = 0, profit = true, enabled = true, sort = 10 },
    { name = "Строительный завод №2", sum = 0, profit = true, enabled = true, sort = 11 },
    { name = "Нелегальный груз", sum = 0, profit = true, enabled = true, sort = 12 },
    { name = "Семейный бонус", sum = 0, profit = true, enabled = true, sort = 13 },
    { name = "Штрафы с камер", sum = 0, profit = false, enabled = true, sort = 14 },
    { name = "Заправка на станции", sum = 0, profit = false, enabled = true, sort = 15 },
    { name = "Заправка механиком", sum = 0, profit = false, enabled = true, sort = 16 },
    { name = "Починка механиком", sum = 0, profit = false, enabled = true, sort = 17 },
    { name = "Канистры", sum = 0, profit = false, enabled = true, sort = 18 },
    { name = "Рем. комплекты", sum = 0, profit = false, enabled = true, sort = 19 },
    { name = "Бусты", sum = 0, profit = false, enabled = true, sort = 20 },
    { name = "Неизвестный источник", sum = 0, profit = true, enabled = true, sort = 21 }
}

local POINTS = {
    { 
        source = "Нефтезавод №2", 
        destination = "Порт СФ", 
        sort = 1, 
        top = true 
    },
     { 
        source = "Нефтевышка №1", 
        destination = "Нефтезавод №1", 
        sort = 2,
        top = false
    },
    { 
        source = "Нефтевышка №2", 
        destination = "Нефтезавод №1", 
        sort = 3,
        top = false
    },
    { 
        source = "Нефтевышка №3", 
        destination = "Нефтезавод №1", 
        sort = 4,
        top = false
    },
    { 
        source = "Лесопилка №1", 
        destination = "Порт СФ", 
        sort = 5, 
        top = true 
    },
    { 
        source = "Склад угля №2", 
        destination = "Порт СФ", 
        sort = 6, 
        top = true 
    },
    { 
        source = "Строительный завод №1", 
        destination = "Порт СФ", 
        sort = 7, 
        top = true
    },
    { 
        source = "Лесопилка №2", 
        destination = "Порт СФ", 
        sort = 8,
        top = true
    },
    { 
        source = "Строительный завод №1", 
        destination = "Порт ЛС", 
        sort = 9,
        top = false
    },
    { 
        source = "Нефтезавод №2", 
        destination = "Порт ЛС", 
        sort = 10, 
        top = false 
    },
    { 
        source = "Лесопилка №1", 
        destination = "Порт ЛС",
        sort = 11, 
        top = false
    },
    { 
        source = "Лесопилка №2", 
        destination = "Порт ЛС",
        sort = 12, 
        top = false
    },
    { 
        source = "Склад угля №2", 
        destination = "Порт ЛС",
        sort = 13,
        top = false
    },
    { 
        source = "Нефтезавод №1", 
        destination = "Порт СФ", 
        sort = 14, 
        top = false 
    },
    { 
        source = "Строительный завод №2", 
        destination = "Порт СФ", 
        sort = 15,
        top = false 
    },
    { 
        source = "Склад угля №1", 
        destination = "Порт СФ", 
        sort = 16,
        top = false
    },
    { 
        source = "Строительный завод №2", 
        destination = "Порт ЛС", 
        sort = 17,
        top = false 
    },
    { 
        source = "Склад угля №1", 
        destination = "Порт ЛС", 
        sort = 18,
        top = false
    },
    { 
        source = "Нефтезавод №1", 
        destination = "Порт ЛС", 
        sort = 19,
        top = false
    }
}

local AUTOLOAD_POINTS = {
    {
        source = "Лесопилка №1",
        coords = { x = -449.37, y = -66.01, z = 59.42 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Лесопилка №2",
        coords = { x = -1978.81, y = -2434.78, z = 30.63 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Строительный завод №1",
        coords = { x = -158.12, y = -289.38, z = 3.91 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Строительный завод №2",
        coords = { x = 617.18, y = 1224.79, z = 11.72 },
        autoCheckDistance = 60,
        autoTakeDistance = 60,
        autoLoadDistance = 15
    },
    {
        source = "Нефтезавод №1",
        coords = { x = 256.20, y = 1414.57, z = 10.71 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Нефтезавод №2",
        coords = { x = -1046.84, y = -670.79, z = 32.35 },
        autoCheckDistance = 60,
        autoTakeDistance = 60,
        autoLoadDistance = 15
    },
    {
        source = "Склад угля №1",
        coords = { x = 608.77, y = 847.84, z = -43.15 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Склад угля №2",
        coords = { x = -1873.02, y = -1720.16, z = 21.75 },
        autoCheckDistance = 60,
        autoTakeDistance = 20,
        autoLoadDistance = 15
    },
    {
        source = "Нефтевышка №1",
        coords = { x = -1908.13, y = 1379.05, z = 7.18 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Нефтевышка №2",
        coords = { x = -241.92, y = -1720.76, z = 3.22 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    },
    {
        source = "Нефтевышка №3",
        coords = { x = 2279.17, y = -2395.07, z = 13.54 },
        autoCheckDistance = 60,
        autoTakeDistance = 30,
        autoLoadDistance = 15
    }
}

local CONTRACT_FILTERS = {
    company = "",
    top = true,
    minTonsQuantity = 1,
    sources = {
        { 
            name = "Лесопилка №1",
            x = 10,
            y = 155,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Лесопилка №2",
            x = 10,
            y = 187,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Строительный завод №1",
            x = 10,
            y = 217,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Строительный завод №2", 
            x = 10,
            y = 247,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Нефтезавод №1",
            x = 10,
            y = 277,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Нефтезавод №2",
            x = 10,
            y = 305,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Склад угля №1",
            x = 10,
            y = 333,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Склад угля №2",
            x = 10,
            y = 360,
            destinations = {
                { name = "Порт Лос-Сантос", short_name = "Порт ЛС", hidden = false },
                { name = "Порт Сан-Фиерро", short_name = "Порт СФ", hidden = false }
            }
        },
        { 
            name = "Нефтевышка №1",
            x = 10,
            y = 387,
            destinations = {
                { name = "Нефтезавод №1", short_name = "Нефтезавод №1", hidden = false },
                { name = "Нефтезавод №2", short_name = "Нефтезавод №2", hidden = true }
            }
        },
        { 
            name = "Нефтевышка №2",
            x = 10,
            y = 416,
            destinations = {
                { name = "Нефтезавод №1", short_name = "Нефтезавод №1", hidden = false },
                { name = "Нефтезавод №2", short_name = "Нефтезавод №2", hidden = true }
            }
        },
        { 
            name = "Нефтевышка №3",
            x = 10,
            y = 445,
            destinations = {
                { name = "Нефтезавод №1", short_name = "Нефтезавод №1", hidden = false },
                { name = "Нефтезавод №2", short_name = "Нефтезавод №2", hidden = true }
            }
        }
    },
    destinations = {
        { name = "Порт ЛС", hidden = false },
        { name = "Порт СФ", hidden = false }
    }
}

local HOTKEYS = {
    {
        name = "drift",
        text = "Дрифт",
        buttonText = "SHIFT",
        first = 16, 
        single = true,
        deleted = false,
        position = { 10, 5 }
    },
    {
        name = "take-and-load",
        text = "Взять контракт и загрузить",
        buttonText = "ALT + Y",
        first = 18,
        second = 89,
        single = false,
        deleted = false,
        position = { 10, 33 }
    },
    {
        name = "cancel-contract",
        text = "Отменить контракт",
        buttonText = "CTRL + C",
        first = 162,
        second = 67,
        single = false,
        deleted = false,
        position = { 10, 63 }
    },
    {
        name = "cursor",
        text = "Курсор списка контрактов",
        buttonText = "SHIFT + C",
        first = 16,
        second = 67,
        single = false,
        position = { 10, 93 }
    }
}

SCRIPT_INFO.NAME = string.format(
    "Truck Contracts Helper %s (%d)", 
    SCRIPT_INFO.VERSION, 
    SCRIPT_INFO.VERSION_NUMBER
)

local COMMANDS = {
    MENU    = "/tmenu",
    LOAD    = "/tload",
    UNLOAD  = "/tunload",
    CLIST   = "/clist %d",
    LOCK    = "/lock",
    SKILL   = "/tskill"
}

local SCRIPT_COMMANDS = {
    "{FCCB06}/tch.menu{EFF1F3} — главное меню",
    "{FCCB06}/tch.toggle{EFF1F3} — включить / выключить скрипт",
    "{FCCB06}/tch.update{EFF1F3} — начать обновление скрипта",
    "{FCCB06}/tch.list{EFF1F3} — показать / скрыть список контрактов",
    "{FCCB06}/tch.sos {EFF1F3}[текст] — отправить свое местоположение в рацию",
    "{FCCB06}/tch.info {EFF1F3} — показать / скрыть панель со статистикой внизу",
    "{FCCB06}/tch.pin {EFF1F3}[номер контракта] — закрепить контракт в списке",
    "{FCCB06}/tch.unpin {EFF1F3}[номер контракта] — открепить контракт в списке"
}

local COLOR_LIST = {
    u8"[0] Без цвета",
    u8"[1] Зелёный",
    u8"[2] Светло-зелёный",
    u8"[3] Ярко-зелёный",
    u8"[4] Бирюзовый",
    u8"[5] Жёлто-зелёный",
    u8"[6] Тёмно-зелёный",
    u8"[7] Серо-зелёный",
    u8"[8] Красный",
    u8"[9] Ярко-красный",
    u8"[10] Оранжевый",
    u8"[11] Коричневый",
    u8"[12] Тёмно-красный",
    u8"[13] Серо-красный",
    u8"[14] Жёлто-оранжевый",
    u8"[15] Малиновый",
    u8"[16] Розовый",
    u8"[17] Синий",
    u8"[18] Голубой",
    u8"[19] Синяя сталь",
    u8"[20] Cине-зелёный",
    u8"[21] Тёмно-синий",
    u8"[22] Фиолетовый",
    u8"[23] Индиго",
    u8"[24] Серо-синий",
    u8"[25] Жёлтый",
    u8"[26] Кукурузный",
    u8"[27] Золотой",
    u8"[28] Старое золото",
    u8"[29] Оливковый",
    u8"[30] Серый",
    u8"[31] Серебро",
    u8"[32] Чёрный",
    u8"[33] Белый"
}

local CONTRACT_LIST_WINDOW_TYPES = {
    u8("Большой"),
    u8("Средний"),
    u8("Маленький")
}

local SERVER_MESSAGES = require "tch.samp.server-messages.patterns"

local STATISTICS_ENTRIES = {
    {
        show = true,
        short_name = "Текущий рейс",
        position = {10, 75},
        name = "Текущий рейс",
        code = "race"
    },
    {
        show = false,
        short_name = "Таймер нелегального груза",
        position = {225, 75},
        name = "Таймер нелегального груза",
        code = "illegal-cargo-time"
    },
    {
        show = true,
        short_name = "Время в рейсе",
        position = {10, 105},
        name = "Время в рейсе",
        code = "race-time"
    },
    {
        show = true,
        short_name = "Опыта за сессию",
        position = {225, 105},
        name = "Опыта за сессию",
        code = "session-experience"
    },
    {
        show = true,
        short_name = "Опыта до N уровня",
        position = {10, 135},
        name = "Опыта до N уровня",
        code = "experience-to-level"
    },
    {
        show = true,
        short_name = "Рейсов за сессию",
        position = {225, 135},
        name = "Рейсов за сессию",
        code = "session-races"
    },
    {
        show = true,
        short_name = "Заработано за сессию",
        position = {10, 165},
        name = "Заработано за сессию",
        code = "session-earnings"
    },
    {
        show = true,
        short_name = "Заработано за всё время",
        position = {225, 165},
        name = "Заработано за всё время",
        code = "total-earnings"
    }
}

local CAMERA_LINES = require "tch.common.cameralines"

local TRUCK_RENTED_CHOICES = {
    u8"Не выбрано",
    u8"Игрок заспавнился",
    u8"Игрок сел в фуру"
}

local SCRIPT_STATUSES = {
    u8"Выключен",
    u8"Включен"
}

local PINS = Array({})

return {
    SCRIPT_INFO = SCRIPT_INFO,
    COLORS = COLORS,
    REGEXP = REGEXP,
    TEXTDRAWS = TEXTDRAWS,
    CONTRACTS = CONTRACTS,
    COMMANDS = COMMANDS,
    CONFIG = CONFIG,
    COLOR_LIST = COLOR_LIST,
    TRUCK_RENTED_CHOICES = TRUCK_RENTED_CHOICES,
    POINTS = POINTS,
    TOP_CHOICES = TOP_CHOICES,
    SORT_CHOICES = SORT_CHOICES,
    SERVER_MESSAGES = SERVER_MESSAGES,
    AUTOLOAD_POINTS = AUTOLOAD_POINTS,
    STATISTICS_ENTRIES = STATISTICS_ENTRIES,
    MAX_TRUCK_DRIVER_LEVEL = MAX_TRUCK_DRIVER_LEVEL,
    MIN_CONTRACTS_SIZE = MIN_CONTRACTS_SIZE,
    MAX_CONTRACTS_SIZE = MAX_CONTRACTS_SIZE,
    MIN_TONS_QUANTITY = MIN_TONS_QUANTITY,
    MAX_TONS_QUANTITY = MAX_TONS_QUANTITY,
    MECHANIC = MECHANIC,
    CONTRACT_FILTERS = CONTRACT_FILTERS,
    SCRIPT_STATUSES = SCRIPT_STATUSES,
    CAMERA_LINES = CAMERA_LINES,
    HOTDOG = HOTDOG,
    SCRIPT_COMMANDS = SCRIPT_COMMANDS,
    HOTKEYS = HOTKEYS,
    PROFIT_AND_LOSS = PROFIT_AND_LOSS,
    CONTRACT_LIST_WINDOW_TYPES = CONTRACT_LIST_WINDOW_TYPES,
    PINS = PINS,
    TRUCKS = TRUCKS,
    TRAILERS = TRAILERS
}