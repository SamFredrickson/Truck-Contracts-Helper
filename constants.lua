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
    MULTIPLE_CONTRACTS = "({AE433D}%d+%. {FFFFFF}%W+ �%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ �� %d+ �%.	{A9A9A9}[A-Za-z0-9%s%-]+)",
    SINGLE_CONTRACT = "{AE433D}(%d+)%. {FFFFFF}(%W+ �%d+) %-%> (%W+){A9A9A9}(%W+){33AA33}(%d+) �� (%d+) �%.	{A9A9A9}([A-Za-z0-9%s%-]+)"
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
    { source = "���������� �2", destination = "���� ��", sort = 1, top = true },
    { source = "����� ���� �2", destination = "���� ��", sort = 2, top = true },
    { source = "��������� �1", destination = "���� ��", sort = 3, top = true },
    { source = "��������� �2", destination = "���� ��", sort = 4, top = true },
    { source = "������������ ����� �1", destination = "���� ��", sort = 5, top = true },
    { source = "������������ ����� �1", destination = "���� ��", sort = 6, top = false },
    { source = "��������� �1", destination = "���� ��", sort = 7, top = false },
    { source = "��������� �2", destination = "���� ��", sort = 8, top = false },
    { source = "����� ���� �2", destination = "���� ��", sort = 9, top = false }
}

local POINTS = {
    { 
        source = "���������� �2", 
        destination = "���� ��", 
        sort = 1, 
        top = true 
    },
    { 
        source = "��������� �1", 
        destination = "���� ��", 
        sort = 2, 
        top = true 
    },
    { 
        source = "����� ���� �2", 
        destination = "���� ��", 
        sort = 3, 
        top = true 
    },
    { 
        source = "������������ ����� �1", 
        destination = "���� ��", 
        sort = 4, 
        top = true
    },
    { 
        source = "��������� �2", 
        destination = "���� ��", 
        sort = 5,
        top = true
    },
    { 
        source = "������������ ����� �1", 
        destination = "���� ��", 
        sort = 6,
        top = false
    },
    { 
        source = "���������� �2", 
        destination = "���� ��", 
        sort = 7, 
        top = false 
    },
    { 
        source = "��������� �1", 
        destination = "���� ��",
        sort = 8, 
        top = false
    },
    { 
        source = "��������� �2", 
        destination = "���� ��",
        sort = 9, 
        top = false
    },
    { 
        source = "����� ���� �2", 
        destination = "���� ��",
        sort = 10,
        top = false
    },
    { 
        source = "���������� �1", 
        destination = "���� ��", 
        sort = 11, 
        top = false 
    },
    { 
        source = "������������ ����� �2", 
        destination = "���� ��", 
        sort = 12,
        top = false 
    },
    { 
        source = "����� ���� �1", 
        destination = "���� ��", 
        sort = 13,
        top = false
    },
    { 
        source = "������������ ����� �2", 
        destination = "���� ��", 
        sort = 14,
        top = false 
    },
    { 
        source = "����� ���� �1", 
        destination = "���� ��", 
        sort = 15,
        top = false
    },
    { 
        source = "���������� �1", 
        destination = "���� ��", 
        sort = 16,
        top = false
    }
}

local AUTOLOAD_POINTS = {
    {
        source = "��������� �1",
        coords = { x = -449.37, y = -66.01, z = 59.42 }
    },
    {
        source = "��������� �2",
        coords = { x = -1978.81, y = -2434.78, z = 30.63 }
    },
    {
        source = "������������ ����� �1",
        coords = { x = -158.12, y = -289.38, z = 3.91 }
    },
    {
        source = "������������ ����� �2",
        coords = { x = 617.18, y = 1224.79, z = 11.72 }
    },
    {
        source = "���������� �1",
        coords = { x = 256.20, y = 1414.57, z = 10.71 }
    },
    {
        source = "���������� �2",
        coords = { x = -1046.84, y = -670.79, z = 32.35 }
    },
    {
        source = "����� ���� �1",
        coords = { x = 608.77, y = 847.84, z = -43.15 }
    },
    {
        source = "����� ���� �2",
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
    u8"[0] ��� �����",
    u8"[1] ������",
    u8"[2] ������-������",
    u8"[3] ����-������",
    u8"[4] ���������",
    u8"[5] Ƹ���-������",
    u8"[6] Ҹ���-������",
    u8"[7] ����-������",
    u8"[8] �������",
    u8"[9] ����-�������",
    u8"[10] ���������",
    u8"[11] ����������",
    u8"[12] Ҹ���-�������",
    u8"[13] ����-�������",
    u8"[14] Ƹ���-���������",
    u8"[15] ���������",
    u8"[16] �������",
    u8"[17] �����",
    u8"[18] �������",
    u8"[19] ����� �����",
    u8"[20] C���-������",
    u8"[21] Ҹ���-�����",
    u8"[22] ����������",
    u8"[23] ������",
    u8"[24] ����-�����",
    u8"[25] Ƹ����",
    u8"[26] ����������",
    u8"[27] �������",
    u8"[28] ������ ������",
    u8"[29] ���������",
    u8"[30] �����",
    u8"[31] �������",
    u8"[32] ׸����",
    u8"[33] �����"
}

local SERVER_MESSAGES = {
    {
        message = "�� ������� ���������� ����. ��� ������ ������ ����������� {.-}%(%( /tmenu %)%)",
        code = "successful-renting"
    },
    {
        message = "�������� ��� �������",
        code = "contract-canceled"
    },
    {
        message = "� ��� ��� ���� �������� ��������",
        code = "has-active-contract"
    },
    {
        message = "� ��� ��� ��������� ���������, �������� ��� ����� � ������������ ��������",
        code = "hasnt-active-contract"
    },
    {
        message = "��� ���������� ��������� � {.-}\"(.+)\" {.-}���� {.-}\"(.+)\" {.-}� ���������� {.-}(%d+) �.",
        code = "delivery-start"
    },
    {
        message = "�� �������� ��������� �� ����, ����� �� �������� ����������� {.-}/showtabel",
        code = "receive-documents"
    },
    {
        message = "�� ������� ��������� ���� {.-}\"(.+)\" {.-}� ���������� {.-}(%d+) �.",
        code = "delivery-success"
    },
    {
        message = "�� ������� ��������� ����������� ���� {.-}� ���������� {.-}(%d+) �.",
        code = "illegal-delivery-success"
    },
    {
        message = "��� ��������� � ������ �������� �������� {.-}(%d+)%% {.-}�������� {.-}(%d+)%$",
        code = "income"
    },
    {
        message = "�� �������� ������������� {.-}%$(%d+) {.-}��� ����� ����� �� ��������� �����",
        code = "family-income"
    },
    {
        message = "�� ����������� �������� �� �������� {.-}(%d+) �����",
        code = "contract-experience"
    },
    {
        message  = "����� � ������� {.-}(%d+)$ {.-}����� ������ � ����������� �����",
        code = "fine"
    },
    {
        message = "����������� ����� ��� ��� ����. ���������� ��������� (%d+):(%d+)",
        code = "waiting-for-free-place"
    },
    {
        message = "� ��� ����������� ����",
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
        message = "�� �����!",
        code = "flood"
    }
}

local STATISTICS_ENTRIES =  {
    {
        name = "����:",
        code = "race",
        short_name = "����:",
        hidden = false
    },
    {
        name = "����� � �����:",
        code = "race-time",
        short_name = "����� � �����:",
        hidden = false
    },
    {
        name = "����������� ���� �������� �����:",
        code = "illegal-cargo-time",
        short_name = "����������� ���� �������� �����:",
        hidden = false
    },
    {
        name = "����� �� ������:",
        code = "session-experience",
        short_name = "����� �� ������:",
        hidden = false
    },
    {
        name = "����� �� N ������:",
        code = "experience-to-level",
        short_name = "����� �� N ������:",
        hidden = false
    },
    {
        name = "������ �� ������:",
        code = "session-races",
        short_name = "������ �� ������:",
        hidden = false
    },
    {
        name = "���������� �� ������:",
        code = "session-earnings",
        short_name = "���������� �� ������:",
        hidden = false
    },
    {
        name = "���������� �� �� �����:",
        code = "total-earnings",
        short_name = "���������� �� �� �����:",
        hidden = false
    }
}

local TRUCK_RENTED_CHOICES = {
    u8"�� �������",
    u8"����� �����������",
    u8"����� ��� � ����"
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