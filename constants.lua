local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local SCRIPT_INFO = {
    AUTHOR = "SAM",
    VERSION = "1.5.1",
    MOONLOADER = 026,
    VERSION_NUMBER = 8,
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

local REGEXP = {
    MULTIPLE_CONTRACTS = "({AE433D}%d+%. {FFFFFF}%W+ №%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ из %d+ т%.	{A9A9A9}[A-Za-z0-9%s%-]+)",
    SINGLE_CONTRACT = "{AE433D}(%d+)%. {FFFFFF}(%W+ №%d+) %-%> (%W+){A9A9A9}(%W+){33AA33}(%d+) из (%d+) т%.	{A9A9A9}([A-Za-z0-9%s%-]+)"
}

local MAX_TRUCK_DRIVER_LEVEL = 26

local CONFIG = {
    PATH = "tch/settings.ini",
    DEFAULT_SETTINGS = {
        truckRentedChoice = 0,
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
        sessionRaceQuantity = 0,
        sessionExperience = 0,
        lastIllegalCargoUnloadedAt = 0,
        statistics = true,
        contractsScreenX = nil,
        contractsScreenY = nil
    }
}

local CONTRACTS = {
    { source = "Нефтезавод №2", destination = "Порт СФ", sort = 1, top = true },
    { source = "Склад угля №2", destination = "Порт СФ", sort = 2, top = true },
    { source = "Лесопилка №1", destination = "Порт СФ", sort = 3, top = true },
    { source = "Лесопилка №2", destination = "Порт СФ", sort = 4, top = true },
    { source = "Строительный завод №1", destination = "Порт СФ", sort = 5, top = true },
    { source = "Строительный завод №1", destination = "Порт ЛС", sort = 6, top = false },
    { source = "Лесопилка №1", destination = "Порт ЛС", sort = 7, top = false },
    { source = "Лесопилка №2", destination = "Порт ЛС", sort = 8, top = false },
    { source = "Склад угля №2", destination = "Порт ЛС", sort = 9, top = false }
}

local POINTS = {
    { 
        source = "Нефтезавод №2", 
        destination = "Порт СФ", 
        sort = 1, 
        top = true 
    },
    { 
        source = "Лесопилка №1", 
        destination = "Порт СФ", 
        sort = 2, 
        top = true 
    },
    { 
        source = "Склад угля №2", 
        destination = "Порт СФ", 
        sort = 3, 
        top = true 
    },
    { 
        source = "Строительный завод №1", 
        destination = "Порт СФ", 
        sort = 4, 
        top = true
    },
    { 
        source = "Лесопилка №2", 
        destination = "Порт СФ", 
        sort = 5,
        top = true
    },
    { 
        source = "Строительный завод №1", 
        destination = "Порт ЛС", 
        sort = 6,
        top = false
    },
    { 
        source = "Нефтезавод №2", 
        destination = "Порт ЛС", 
        sort = 7, 
        top = false 
    },
    { 
        source = "Лесопилка №1", 
        destination = "Порт ЛС",
        sort = 8, 
        top = false
    },
    { 
        source = "Лесопилка №2", 
        destination = "Порт ЛС",
        sort = 9, 
        top = false
    },
    { 
        source = "Склад угля №2", 
        destination = "Порт ЛС",
        sort = 10,
        top = false
    },
    { 
        source = "Нефтезавод №1", 
        destination = "Порт СФ", 
        sort = 11, 
        top = false 
    },
    { 
        source = "Строительный завод №2", 
        destination = "Порт СФ", 
        sort = 12,
        top = false 
    },
    { 
        source = "Склад угля №1", 
        destination = "Порт СФ", 
        sort = 13,
        top = false
    },
    { 
        source = "Строительный завод №2", 
        destination = "Порт ЛС", 
        sort = 14,
        top = false 
    },
    { 
        source = "Склад угля №1", 
        destination = "Порт ЛС", 
        sort = 15,
        top = false
    },
    { 
        source = "Нефтезавод №1", 
        destination = "Порт ЛС", 
        sort = 16,
        top = false
    }
}

local AUTOLOAD_POINTS = {
    {
        source = "Лесопилка №1",
        coords = { x = -449.37, y = -66.01, z = 59.42 }
    },
    {
        source = "Лесопилка №2",
        coords = { x = -1978.81, y = -2434.78, z = 30.63 }
    },
    {
        source = "Строительный завод №1",
        coords = { x = -158.12, y = -289.38, z = 3.91 }
    },
    {
        source = "Строительный завод №2",
        coords = { x = 617.18, y = 1224.79, z = 11.72 }
    },
    {
        source = "Нефтезавод №1",
        coords = { x = 256.20, y = 1414.57, z = 10.71 }
    },
    {
        source = "Нефтезавод №2",
        coords = { x = -1046.84, y = -670.79, z = 32.35 }
    },
    {
        source = "Склад угля №1",
        coords = { x = 608.77, y = 847.84, z = -43.15 }
    },
    {
        source = "Склад угля №2",
        coords = { x = -1873.02, y = -1720.16, z = 21.75 }
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

local SERVER_MESSAGES = {
    {
        message = "Вы успешно арендовали фуру. Для начала работы используйте {.-}%(%( /tmenu %)%)",
        code = "successful-renting"
    },
    {
        message = "Контракт был отменен",
        code = "contract-canceled"
    },
    {
        message = "У Вас уже есть активный контракт",
        code = "has-active-contract"
    },
    {
        message = "У Вас нет активного контракта, получить его можно в транспортной компании",
        code = "hasnt-active-contract"
    },
    {
        message = "Вам необходимо доставить в {.-}\"(.+)\" {.-}груз {.-}\"(.+)\" {.-}в количестве {.-}(%d+) т.",
        code = "delivery-start"
    },
    {
        message = "Вы получили документы на груз, чтобы их показать используйте {.-}/showtabel",
        code = "receive-documents"
    },
    {
        message = "Вы успешно доставили груз {.-}\"(.+)\" {.-}в количестве {.-}(%d+) т.",
        code = "delivery-success"
    },
    {
        message = "Вы успешно доставили нелегальный груз {.-}в количестве {.-}(%d+) т.",
        code = "illegal-delivery-success"
    },
    {
        message = "Ваш заработок с учетом комиссии компании {.-}(%d+)%% {.-}составил {.-}(%d+)%$",
        code = "income"
    },
    {
        message = "Вы получили дополнительно {.-}%$(%d+) {.-}при сдаче груза за улучшение семьи",
        code = "family-income"
    },
    {
        message = "За выполненный контракт Вы получили {.-}(%d+) опыта",
        code = "contract-experience"
    },
    {
        message  = "Штраф в размере {.-}(%d+)$ {.-}будет списан с банковского счёта",
        code = "fine"
    },
    {
        message = "Освобождаем место под Ваш груз. Пожалуйста подождите (%d+):(%d+)",
        code = "waiting-for-free-place"
    },
    {
        message = "У Вас отсутствует груз",
        code = "no-cargo-attached"
    },
    {
        message = "%[J%] ([A-Za-z_]+)%[%d+%]: {.-}(.+)",
        code = "truck-driver-chat-new-message"
    },
    {
        message = "%[J%] ([A-Za-z_]+)%[%d+%]: {.-}(.+) (.+)|(.+)|(.+)",
        code = "truck-driver-chat-new-message-with-coords"
    },
    {
        message = "Не флуди!",
        code = "flood"
    }
}

local STATISTICS_ENTRIES =  {
    {
        name = "Рейс:",
        code = "race",
        short_name = "Рейс:",
        hidden = false
    },
    {
        name = "Время в рейсе:",
        code = "race-time",
        short_name = "Время в рейсе:",
        hidden = false
    },
    {
        name = "Нелегальный груз доступен через:",
        code = "illegal-cargo-time",
        short_name = "Нелегальный груз доступен через:",
        hidden = false
    },
    {
        name = "Опыта за сессию:",
        code = "session-experience",
        short_name = "Опыта за сессию:",
        hidden = false
    },
    {
        name = "Опыта до N уровня:",
        code = "experience-to-level",
        short_name = "Опыта до N уровня:",
        hidden = false
    },
    {
        name = "Рейсов за сессию:",
        code = "session-races",
        short_name = "Рейсов за сессию:",
        hidden = false
    },
    {
        name = "Заработано за сессию:",
        code = "session-earnings",
        short_name = "Заработано за сессию:",
        hidden = false
    },
    {
        name = "Заработано за всё время:",
        code = "total-earnings",
        short_name = "Заработано за всё время:",
        hidden = false
    }
}

local TRUCK_RENTED_CHOICES = {
    u8"Не выбрано",
    u8"Игрок заспавнился",
    u8"Игрок сел в фуру"
}

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
    MAX_TRUCK_DRIVER_LEVEL = MAX_TRUCK_DRIVER_LEVEL
}