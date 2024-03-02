local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local SCRIPT_INFO = {
    AUTHOR = "SAM",
    VERSION = "1.0.1",
    MOONLOADER = 026,
    VERSION_NUMBER = 2,
    VERSION_URL = "https://raw.githubusercontent.com/SamFredrickson/Truck-Contracts-Helper/master/version.json",
    CHANGELOG_URL = "https://github.com/SamFredrickson/Truck-Contracts-Helper/blob/master/CHANGELOG.md",
    URL = "https://github.com/SamFredrickson/Truck-Contracts-Helper",
}

local COLORS = {
	RED = 0xFF0000,
	GREEN = 0x00FF00,
	GOLD = 0xFFD700,
	SEASHELL = 0xFFF5EE,
	PINK = 0xFFC0CB
}

local REGEXP = {
    MULTIPLE_CONTRACTS = "({AE433D}%d+%. {FFFFFF}%W+ №%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ из %d+ т%.	{A9A9A9}[A-Za-z0-9%s%-]+)",
    SINGLE_CONTRACT = "{AE433D}(%d+)%. {FFFFFF}(%W+ №%d+) %-%> (%W+){A9A9A9}(%W+){33AA33}(%d+) из (%d+) т%.	{A9A9A9}([A-Za-z0-9%s%-]+)"
}

local CONFIG = {
    PATH = "tch/settings.ini",
    DEFAULT_SETTINGS = {
        truckRentedChoice = 0,
        clistChoice = 16,
        documentsDialogue = false,
        autounload = true,
        autoload = false,
        drift = false,
        unloadDistance = 15,
        autolock = false
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
    LOCK    = "/lock"
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
        message = "%[J%] ([A-Za-z_]+)%[%d+%]: {.-}(.+)",
        code = "truck-driver-chat-new-message"
    },
    {
        message = "%[J%] ([A-Za-z_]+)%[%d+%]: {.-}(.+) (.+)|(.+)|(.+)",
        code = "truck-driver-chat-new-message-with-coords"
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
    SERVER_MESSAGES = SERVER_MESSAGES
}