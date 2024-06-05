local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local SCRIPT_INFO = {
    AUTHOR = "SAM",
    VERSION = "1.6.0",
    MOONLOADER = 026,
    VERSION_NUMBER = 9,
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
    MULTIPLE_CONTRACTS = "({.-}%d+%. {.-}%W+ �%d %-%> %W+{.-}%W+{.-}%d+ �� %d+ �%.	{.-}[%w\128-\255-]+)",
    SINGLE_CONTRACT = "{.-}(%d+)%. {.-}(%W+ �%d+) %-%> (%W+){.-}(%W+){.-}(%d+) �� (%d+) �%.	{.-}([%w\128-\255-]+)"
}

local MAX_TRUCK_DRIVER_LEVEL = 26
local MIN_CONTRACTS_SIZE = 1
local MAX_CONTRACTS_SIZE = 16
local MIN_TONS_QUANTITY = 1
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
        transparentCorpses = true
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
        coords = { x = -449.37, y = -66.01, z = 59.42 },
        autoTakeDistance = 25
    },
    {
        source = "��������� �2",
        coords = { x = -1978.81, y = -2434.78, z = 30.63 },
        autoTakeDistance = 35
    },
    {
        source = "������������ ����� �1",
        coords = { x = -158.12, y = -289.38, z = 3.91 },
        autoTakeDistance = 60
    },
    {
        source = "������������ ����� �2",
        coords = { x = 617.18, y = 1224.79, z = 11.72 },
        autoTakeDistance = 25
    },
    {
        source = "���������� �1",
        coords = { x = 256.20, y = 1414.57, z = 10.71 },
        autoTakeDistance = 25
    },
    {
        source = "���������� �2",
        coords = { x = -1046.84, y = -670.79, z = 32.35 },
        autoTakeDistance = 25
    },
    {
        source = "����� ���� �1",
        coords = { x = 608.77, y = 847.84, z = -43.15 },
        autoTakeDistance = 25
    },
    {
        source = "����� ���� �2",
        coords = { x = -1873.02, y = -1720.16, z = 21.75 },
        autoTakeDistance = 25
    }
}

local CONTRACT_FILTERS = {
    company = "",
    top = true,
    minTonsQuantity = 1,
    sources = {
        { 
            name = "��������� �1",
            x = 10,
            y = 155,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "��������� �2",
            x = 10,
            y = 187,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "������������ ����� �1",
            x = 10,
            y = 217,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "������������ ����� �2", 
            x = 10,
            y = 247,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "���������� �1",
            x = 10,
            y = 277,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "���������� �2",
            x = 10,
            y = 305,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "����� ���� �1",
            x = 10,
            y = 333,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        },
        { 
            name = "����� ���� �2",
            x = 10,
            y = 360,
            destinations = {
                { name = "���� ���-������", short_name = "���� ��", hidden = false },
                { name = "���� ���-������", short_name = "���� ��", hidden = false }
            }
        }
    },
    destinations = {
        { name = "���� ��", hidden = false },
        { name = "���� ��", hidden = false }
    }
}

local HOTKEYS = {
    {
        name = "drift",
        text = "�����",
        buttonText = "SHIFT",
        first = 16, 
        single = true,
        deleted = false,
        position = { 10, 5 }
    },
    {
        name = "take-and-load",
        text = "����� �������� � ���������",
        buttonText = "ALT + Y",
        first = 19,
        second = 89,
        single = false,
        deleted = false,
        position = { 10, 33 }
    },
    {
        name = "cancel-contract",
        text = "�������� ��������",
        buttonText = "CTRL + C",
        first = 162,
        second = 67,
        single = false,
        deleted = false,
        position = { 10, 63 }
    },
    {
        name = "cursor",
        text = "������ ������ ����������",
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
    "{FCCB06}/tch.menu{EFF1F3} � ������� ����",
    "{FCCB06}/tch.toggle{EFF1F3} � �������� / ��������� ������",
    "{FCCB06}/tch.update{EFF1F3} � ������ ���������� �������",
    "{FCCB06}/tch.list{EFF1F3} � �������� / ������ ������ ����������",
    "{FCCB06}/tch.coords.send {EFF1F3}[�����] � ��������� ���� �������������� � �����",
    "{FCCB06}/tch.info {EFF1F3} � �������� / ������ ������ �� ����������� �����",
    "{FCCB06}/tch.pin {EFF1F3}[����� ���������] � ��������� �������� � ������",
    "{FCCB06}/tch.unpin {EFF1F3}[����� ���������] � ��������� �������� � ������"
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
        message = "([A-Za-z_]+)%[%d+%] ��������� ��� ��������������� ���������. ����: (%d+) $.",
        code = "repair-suggestion"
    },
    {
        message = "([A-Za-z_]+)%[%d+%] ��������� ��� ��������� ������������ �������� �� (%d+) ������. ����: (%d+) $.",
        code = "refill-suggestion"
    },
    {
        message = "([A-Za-z_]+)%[%d+%] ��������� ��� ������ ���%-���. ����: (%d+) $.",
        code = "hot-suggestion"
    },
    {
        message = "�� ������ ���%-���",
        code = "hot-accepted"
    },
    {
        message = "�� ��� ������",
        code = "hot-eaten"
    },
    {
        message = "�� ����������� �� ������ ������������� ��������",
        code = "repair-accepted"
    },
    {
        message = "�� ��� ���������������.",
        code = "repair-already"
    },
    {
        message = "�� ������ (%d+) ������ �������",
        code = "refill-accepted"
    },
    {
        message = "����� ������ �� ��������� ������",
        code = "repair-not-required"
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
        name = "����������� ����:",
        code = "illegal-cargo-time",
        short_name = "����������� ����:",
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

local CAMERA_LINES = 
{
    MIN_WIDTH = 1,
    MAX_WIDTH = 10,
    VALUES = {
        -- �� - �� (����������� ����)
        { 1659.4084472656, -28.431949615479, 35, 1655.3083496094, -29.94651222229, 35 },
        { 1655.3083496094, -29.94651222229, 35, 1653.5678710938, -30.589527130127, 35 },
        { 1653.5678710938, -30.589527130127, 35, 1652.2796630859, -31.065494537354, 35 },
        { 1652.2796630859, -31.065494537354, 35, 1649.5834960938, -32.061328887939, 35 },
        { 1649.5834960938, -32.061328887939, 35, 1648.0363769531, -32.632915496826, 35 },
        { 1648.0363769531, -32.632915496826, 35, 1645.5850830078, -33.538330078125, 35 },
        { 1645.5850830078, -33.538330078125, 35, 1643.4239501953, -34.336559295654, 35 },
        { 1643.4239501953, -34.336559295654, 35, 1639.9627685547, -35.615036010742, 35 },
        { 1639.9627685547, -35.615036010742, 35, 1637.6890869141, -36.455089569092, 35 },
        { 1637.6890869141, -36.455089569092, 35, 1635.8468017578, -37.135620117188, 35 },
        { 1635.8468017578, -37.135620117188, 35, 1634.2828369141, -37.713375091553, 35 },
        { 1634.2828369141, -37.713375091553, 35, 1633.6320800781, -37.953533172607, 35 },
         -- �� - �� (����������� ����)
        { 1644.1586914063, 6.0596385002136, 35, 1641.7395019531, 4.8679056167603, 35 },
        { 1641.7395019531, 4.8679056167603, 35, 1639.1954345703, 3.6145203113556, 35 },
        { 1639.1954345703, 3.6145203113556, 35, 1637.6905517578, 2.87291264534, 35 },
        { 1637.6905517578, 2.87291264534, 35, 1635.1798095703, 1.6361078023911, 35 },
        { 1635.1798095703, 1.6361078023911, 35, 1632.7681884766, 0.44798201322556, 35 },
        { 1632.7681884766, 0.44798201322556, 35, 1630.7121582031, -0.56496280431747, 35 },
        { 1630.7121582031, -0.56496280431747, 35, 1628.5098876953, -1.6499569416046, 35 },
        { 1628.5098876953, -1.6499569416046, 35, 1625.2502441406, -3.2557480335236, 35 },
        { 1625.2502441406, -3.2557480335236, 35, 1621.9906005859, -4.8618478775024, 35 },
        { 1621.9906005859, -4.8618478775024, 35, 1619.4641113281, -6.1064071655273, 35 },
        { 1659.4084472656, -28.431949615479, 35, 1658.5698242188, -27.093603134155, 35 },
        { 1658.5698242188, -27.093603134155, 35, 1657.1846923828, -23.757768630981, 35 },
        { 1657.1846923828, -23.757768630981, 35, 1656.1101074219, -21.347822189331, 35 },
        { 1656.1101074219, -21.347822189331, 35, 1654.8751220703, -18.578535079956, 35 },
        { 1654.8751220703, -18.578535079956, 35, 1653.3819580078, -15.230195999146, 35 },
        { 1653.3819580078, -15.230195999146, 35, 1651.9537353516, -12.026292800903, 35 },
        { 1651.9537353516, -12.026292800903, 35, 1650.3634033203, -8.4628076553345, 35 },
        { 1650.3634033203, -8.4628076553345, 35, 1648.5223388672, -4.3323273658752, 35 },
        { 1648.5223388672, -4.3323273658752, 35, 1646.7772216797, -0.4177483022213, 35 },
        { 1646.7772216797, -0.4177483022213, 35, 1646.4262695313, 0.39916190505028, 35 },
        { 1646.4262695313, 0.39916190505028, 35, 1645.7130126953, 2.0319807529449, 35 },
        { 1645.7130126953, 2.0319807529449, 35, 1644.7370605469, 4.2645416259766, 35 },
        { 1644.7370605469, 4.2645416259766, 35, 1644.5073242188, 4.8146057128906, 35 },
        { 1644.5073242188, 4.8146057128906, 35, 1644.1586914063, 6.0596385005, 35 },
        { 1633.6320800781, -37.953533172607, 35, 1633.154296875, -36.919097900391, 35 },
        { 1633.154296875, -36.919097900391, 35, 1631.072265625, -32.281471252441, 35 },
        { 1631.072265625, -32.281471252441, 35, 1629.7666015625, -29.373905181885, 35 },
        { 1629.7666015625, -29.373905181885, 35, 1628.5787353516, -26.728229522705, 35 },
        { 1628.5787353516, -26.728229522705, 35, 1626.7862548828, -22.735698699951, 35 },
        { 1626.7862548828, -22.735698699951, 35, 1624.8830566406, -18.496925354004, 35 },
        { 1624.8830566406, -18.496925354004, 35, 1623.7003173828, -15.863347053528, 35 },
        { 1623.7003173828, -15.863347053528, 35, 1622.69140625, -13.616389274597, 35 },
        { 1622.69140625, -13.616389274597, 35, 1621.5078125, -10.979785919189, 35 },
        { 1621.5078125, -10.979785919189, 35, 1619.4641113281, -6.1064071655273, 35 },
        -- �� - �� (����� ������� ��)
        { 526.87548828125, 449.82916259766, 18.13, 528.72253417969, 451.11972045898, 18.13 },
        { 528.72253417969, 451.11972045898, 18.13, 530.86706542969, 452.61810302734, 18.13 },
        { 530.86706542969, 452.61810302734, 18.13, 532.4287109375, 453.70916748047, 18.13 },
        { 532.4287109375, 453.70916748047, 18.13, 534.30041503906, 455.0166015625, 18.13 },
        { 534.30041503906, 455.0166015625, 18.13, 536.08984375, 456.26699829102, 18.13 },
        { 536.08984375, 456.26699829102, 18.13, 537.94354248047, 457.5622253418, 18.13 },
        { 537.94354248047, 457.5622253418, 18.13, 539.79119873047, 458.85333251953, 18.13 },
        -- �� - �� (����� ������� ��)
        { 515.50738525391, 493.52047729492, 18.13, 513.42248535156, 492.09686279297, 18.13 },
        { 513.42248535156, 492.09686279297, 18.13, 510.82879638672, 490.3258972168, 18.13 },
        { 510.82879638672, 490.3258972168, 18.13, 507.81536865234, 488.26837158203, 18.13 },
        { 507.81536865234, 488.26837158203, 18.13, 504.42230224609, 485.95162963867, 18.13 },
        { 504.42230224609, 485.95162963867, 18.13, 502.37075805664, 484.55075073242, 18.13 },
        { 539.79119873047, 458.85333251953, 18.13, 537.77227783203, 461.70239257813, 18.13 },
        { 537.77227783203, 461.70239257813, 18.13, 535.70477294922, 464.67904663086, 18.13 },
        { 535.70477294922, 464.67904663086, 18.13, 534.06536865234, 467.03955078125, 18.13 },
        { 534.06536865234, 467.03955078125, 18.13, 532.00634765625, 470.00381469727, 18.13 },
        { 532.00634765625, 470.00381469727, 18.13, 529.79858398438, 473.18273925781, 18.13 },
        { 529.79858398438, 473.18273925781, 18.13, 527.82177734375, 476.02880859375, 18.13 },
        { 527.82177734375, 476.02880859375, 18.13, 525.13922119141, 479.89077758789, 18.13 },
        { 525.13922119141, 479.89077758789, 18.13, 521.13586425781, 485.65466308594, 18.13 },
        { 521.13586425781, 485.65466308594, 18.13, 518.07983398438, 490.0546875, 18.13 },
        { 518.07983398438, 490.0546875, 18.13, 515.50738525391, 493.52047729492, 18.13 },
        { 502.37075805664, 484.55075073242, 18.13, 504.06692504883, 482.4836730957, 18.13 },
        { 504.06692504883, 482.4836730957, 18.13, 505.49868774414, 480.43167114258, 18.13 },
        { 505.49868774414, 480.43167114258, 18.13, 507.12979125977, 478.09365844727, 18.13 },
        { 507.12979125977, 478.09365844727, 18.13, 508.74697875977, 475.77542114258, 18.13 },
        { 508.74697875977, 475.77542114258, 18.13, 510.39172363281, 473.41775512695, 18.13 },
        { 510.39172363281, 473.41775512695, 18.13, 511.71832275391, 471.51593017578, 18.13 },
        { 511.71832275391, 471.51593017578, 18.13, 513.90954589844, 468.37484741211, 18.13 },
        { 513.90954589844, 468.37484741211, 18.13, 515.42065429688, 466.20892333984, 18.13 },
        { 515.42065429688, 466.20892333984, 18.13, 517.38098144531, 463.39862060547, 18.13 },
        { 517.38098144531, 463.39862060547, 18.13, 520.27215576172, 459.25457763672, 18.13 },
        { 520.27215576172, 459.25457763672, 18.13, 522.64074707031, 455.85925292969, 18.13 },
        { 522.64074707031, 455.85925292969, 18.13, 524.86370849609, 452.67260742188, 18.13 },
        { 524.86370849609, 452.67260742188, 18.13, 526.87548828125, 449.82916259766, 18.13 },
        -- �� - �� (����� ����� 2)
        { -164.97848510742, 348.24380493164, 11, -166.69427490234, 348.71194458008, 11 },
        { -166.69427490234, 348.71194458008, 11, -169.80448913574, 349.56051635742, 11 },
        { -169.80448913574, 349.56051635742, 11, -171.53881835938, 350.03359985352, 11 },
        { -171.53881835938, 350.03359985352, 11, -173.42216491699, 350.54736328125, 11 },
        { -173.42216491699, 350.54736328125, 11, -175.45086669922, 351.10076904297, 11 },
        { -175.45086669922, 351.10076904297, 11, -176.89801025391, 351.49557495117, 11 },
        { -176.89801025391, 351.49557495117, 11, -180.02836608887, 352.34951782227, 11 },
        -- �� - �� (����� ����� 2)
        { -154.56004333496, 387.68154907227, 11, -156.45191955566, 388.14254760742, 11 },
        { -156.45191955566, 388.14254760742, 11, -158.24468994141, 388.53158569336, 11 },
        { -158.24468994141, 388.53158569336, 11, -160.13252258301, 388.94131469727, 11 },
        { -160.13252258301, 388.94131469727, 11, -162.35786437988, 389.42416381836, 11 },
        { -162.35786437988, 389.42416381836, 11, -164.57649230957, 389.90567016602, 11 },
        { -164.57649230957, 389.90567016602, 11, -166.48350524902, 390.31954956055, 11 },
        { -166.48350524902, 390.31954956055, 11, -170.19387817383, 391.12484741211, 11 },
        { -164.97848510742, 348.24380493164, 11, -164.28430175781, 350.48526000977, 11 },
        { -164.28430175781, 350.48526000977, 11, -163.77685546875, 352.55999755859, 11 },
        { -163.77685546875, 352.55999755859, 11, -162.94038391113, 355.98001098633, 11 },
        { -162.94038391113, 355.98001098633, 11, -162.16818237305, 358.87030029297, 11 },
        { -162.16818237305, 358.87030029297, 11, -160.93293762207, 363.49404907227, 11 },
        { -160.93293762207, 363.49404907227, 11, -159.95013427734, 367.27633666992, 11 },
        { -159.95013427734, 367.27633666992, 11, -158.92314147949, 371.22866821289, 11 },
        { -158.92314147949, 371.22866821289, 11, -157.99617004395, 374.79595947266, 11 },
        { -157.99617004395, 374.79595947266, 11, -156.71588134766, 379.7229309082, 11 },
        { -156.71588134766, 379.7229309082, 11, -155.63276672363, 383.89126586914, 11 },
        { -155.63276672363, 383.89126586914, 11, -154.56004333496, 387.68154907227, 11 },
        { -170.19387817383, 391.12484741211, 11, -170.86589050293, 388.32604980469, 11 },
        { -170.86589050293, 388.32604980469, 11, -171.45967102051, 385.96624755859, 11 },
        { -171.45967102051, 385.96624755859, 11, -172.2115020752, 382.97805786133, 11 },
        { -172.2115020752, 382.97805786133, 11, -172.91789245605, 380.17074584961, 11 },
        { -172.91789245605, 380.17074584961, 11, -173.91963195801, 376.18942260742, 11 },
        { -173.91963195801, 376.18942260742, 11, -174.87217712402, 372.40377807617, 11 },
        { -174.87217712402, 372.40377807617, 11, -175.88864135742, 368.36395263672, 11 },
        { -175.88864135742, 368.36395263672, 11, -176.93334960938, 364.21185302734, 11 },
        { -176.93334960938, 364.21185302734, 11, -177.88143920898, 360.44384765625, 11 },
        { -177.88143920898, 360.44384765625, 11, -178.52458190918, 357.88754272461, 11 },
        { -178.52458190918, 357.88754272461, 11, -180.02836608887, 352.34951782227, 11 },
        -- �� - ��
        { -1262.0081787109, 993.57043457031, 43, -1259.9104003906, 991.59881591797, 43 },
        { -1259.9104003906, 991.59881591797, 43, -1256.7265625, 988.60614013672, 43 },
        { -1256.7265625, 988.60614013672, 43, -1253.9406738281, 985.98742675781, 43 },
        { -1253.9406738281, 985.98742675781, 43, -1251.4184570313, 983.61682128906, 43 },
        { -1251.4184570313, 983.61682128906, 43, -1248.9345703125, 981.2822265625, 43 },
        { -1248.9345703125, 981.2822265625, 43, -1246.8793945313, 979.35089111328, 43 },
        { -1246.8793945313, 979.35089111328, 43, -1243.8706054688, 976.52319335938, 43 },
        { -1243.8706054688, 976.52319335938, 43, -1241.6569824219, 974.44281005859, 43 },
        { -1241.6569824219, 974.44281005859, 43, -1240.3421630859, 973.20715332031, 43 },
        { -1240.3421630859, 973.20715332031, 43, -1239.0476074219, 971.99053955078, 43 },
        -- �� - ��
        { -1282.6405029297, 972.51904296875, 44, -1280.4232177734, 970.4384765625, 44 },
        { -1280.4232177734, 970.4384765625, 44, -1278.8812255859, 968.96685791016, 44 },
        { -1278.8812255859, 968.96685791016, 44, -1276.9748535156, 967.14807128906, 44 },
        { -1276.9748535156, 967.14807128906, 44, -1274.9542236328, 965.22003173828, 44 },
        { -1274.9542236328, 965.22003173828, 44, -1272.9998779297, 963.35491943359, 44 },
        { -1272.9998779297, 963.35491943359, 44, -1270.9270019531, 961.37652587891, 44 },
        { -1270.9270019531, 961.37652587891, 44, -1267.9569091797, 958.54266357422, 44 },
        { -1267.9569091797, 958.54266357422, 44, -1266.0203857422, 956.6943359375, 44 },
        { -1266.0203857422, 956.6943359375, 44, -1264.1186523438, 954.87951660156, 44 },
        { -1264.1186523438, 954.87951660156, 44, -1262.3133544922, 953.15716552734, 44 },
        { -1262.3133544922, 953.15716552734, 44, -1260.6428222656, 951.56311035156, 44 },
        { -1260.6428222656, 951.56311035156, 44, -1259.6573486328, 950.62255859375, 44 },
        { -1259.6573486328, 950.62255859375, 44, -1257.9428710938, 952.43627929688, 44 },
        { -1257.9428710938, 952.43627929688, 44, -1255.5906982422, 954.91882324219, 44 },
        { -1255.5906982422, 954.91882324219, 44, -1252.9226074219, 957.73468017578, 44 },
        { -1252.9226074219, 957.73468017578, 44, -1250.9490966797, 959.81707763672, 44 },
        { -1250.9490966797, 959.81707763672, 44, -1248.1453857422, 962.77563476563, 44 },
        { -1248.1453857422, 962.77563476563, 44, -1245.9322509766, 965.11090087891, 44 },
        { -1245.9322509766, 965.11090087891, 44, -1243.5728759766, 967.60076904297, 44 },
        { -1243.5728759766, 967.60076904297, 44, -1241.7615966797, 969.51232910156, 44 },
        { -1241.7615966797, 969.51232910156, 44, -1240.7730712891, 970.48370361328, 44 },
        { -1240.7730712891, 970.48370361328, 44, -1239.0476074219, 971.99053955078, 43 },
        { -1262.0081787109, 993.57043457031, 43, -1263.6242675781, 992.07891845703, 43 },
        { -1263.6242675781, 992.07891845703, 43, -1265.6290283203, 990.02520751953, 43 },
        { -1265.6290283203, 990.02520751953, 43, -1267.3900146484, 988.22113037109, 43 },
        { -1267.3900146484, 988.22113037109, 43, -1269.0900878906, 986.47930908203, 43 },
        { -1269.0900878906, 986.47930908203, 43, -1271.3677978516, 984.14562988281, 43 },
        { -1271.3677978516, 984.14562988281, 43, -1273.294921875, 982.17114257813, 43 },
        { -1273.294921875, 982.17114257813, 43, -1275.4449462891, 979.96899414063, 43 },
        { -1275.4449462891, 979.96899414063, 43, -1277.4354248047, 977.92987060547, 43 },
        { -1277.4354248047, 977.92987060547, 43, -1279.8458251953, 975.46063232422, 43 },
        { -1279.8458251953, 975.46063232422, 43, -1281.9523925781, 973.30230712891, 43 },
        { -1281.9523925781, 973.30230712891, 43, -1282.6405029297, 972.51904296875, 44 },
        -- �� - �� (����� 1)
        { -119.48370361328, -1001.6177978516, 23.5, -117.67171478271, -1000.1538696289, 23.5 },
        { -117.67171478271, -1000.1538696289, 23.5, -116.24008178711, -999.00036621094, 23.5 },
        { -116.24008178711, -999.00036621094, 23.5, -114.45062255859, -997.55865478516, 23.5 },
        { -114.45062255859, -997.55865478516, 23.5, -112.94937133789, -996.34924316406, 23.5 },
        { -112.94937133789, -996.34924316406, 23.5, -111.63174438477, -995.28778076172, 23.5 },
        { -111.63174438477, -995.28778076172, 23.5, -110.07495880127, -994.03350830078, 23.5 },
        { -110.07495880127, -994.03350830078, 23.5, -108.98948669434, -993.15905761719, 23.5 },
         -- �� - �� (����� 1)
        { -97.221588134766, -1034.8848876953, 23.5, -95.834190368652, -1033.9108886719, 23.5 },
        { -95.834190368652, -1033.9108886719, 23.5, -94.601142883301, -1033.0477294922, 23.5 },
        { -94.601142883301, -1033.0477294922, 23.5, -93.003952026367, -1031.9295654297, 23.5 },
        { -93.003952026367, -1031.9295654297, 23.5, -91.119491577148, -1030.6099853516, 23.5 },
        { -91.119491577148, -1030.6099853516, 23.5, -89.252952575684, -1029.3034667969, 23.5 },
        { -89.252952575684, -1029.3034667969, 23.5, -87.038841247559, -1027.7531738281, 23.5 },
        { -87.038841247559, -1027.7531738281, 23.5, -85.820121765137, -1026.8999023438, 23.5 },
        { -119.48370361328, -1001.6177978516, 23.5, -118.99440765381, -1002.3745117188, 23.5 },
        { -118.99440765381, -1002.3745117188, 23.5, -117.91358947754, -1003.9756469727, 23.5 },
        { -117.91358947754, -1003.9756469727, 23.5, -116.89768218994, -1005.4806518555, 23.5 },
        { -116.89768218994, -1005.4806518555, 23.5, -115.08076477051, -1008.1726074219, 23.5 },
        { -115.08076477051, -1008.1726074219, 23.5, -114.36848449707, -1009.2279052734, 23.5 },
        { -114.36848449707, -1009.2279052734, 23.5, -113.09275817871, -1011.1179199219, 23.5 },
        { -113.09275817871, -1011.1179199219, 23.5, -111.60571289063, -1013.3208618164, 23.5 },
        { -111.60571289063, -1013.3208618164, 23.5, -110.66282653809, -1014.7177734375, 23.5 },
        { -110.66282653809, -1014.7177734375, 23.5, -109.49655151367, -1016.4455566406, 23.5 },
        { -109.49655151367, -1016.4455566406, 23.5, -108.58296966553, -1017.7990112305, 23.5 },
        { -108.58296966553, -1017.7990112305, 23.5, -107.28245544434, -1019.7258300781, 23.5 },
        { -107.28245544434, -1019.7258300781, 23.5, -106.34969329834, -1021.1077270508, 23.5 },
        { -106.34969329834, -1021.1077270508, 23.5, -105.06132507324, -1023.016418457, 23.5 },
        { -105.06132507324, -1023.016418457, 23.5, -104.12237548828, -1024.4075927734, 23.5 },
        { -104.12237548828, -1024.4075927734, 23.5, -102.44835662842, -1026.8880615234, 23.5 },
        { -102.44835662842, -1026.8880615234, 23.5, -101.32122802734, -1028.5574951172, 23.5 },
        { -101.32122802734, -1028.5574951172, 23.5, -99.939468383789, -1030.6044921875, 23.5 },
        { -99.939468383789, -1030.6044921875, 23.5, -98.84691619873, -1032.2230224609, 23.5 },
        { -98.84691619873, -1032.2230224609, 23.5, -98.285263061523, -1033.0529785156, 23.5 },
        { -98.285263061523, -1033.0529785156, 23.5, -97.221588134766, -1034.884887696, 23.5 },
        { -108.98948669434, -993.15905761719, 23.5, -108.30171203613, -994.25103759766, 23.5 },
        { -108.30171203613, -994.25103759766, 23.5, -107.02347564697, -996.07177734375, 23.5 },
        { -107.02347564697, -996.07177734375, 23.5, -105.88572692871, -997.68414306641, 23.5 },
        { -105.88572692871, -997.68414306641, 23.5, -104.01616668701, -1000.3338623047, 23.5 },
        { -104.01616668701, -1000.3338623047, 23.5, -102.37930297852, -1002.6536865234, 23.5 },
        { -102.37930297852, -1002.6536865234, 23.5, -101.04438018799, -1004.5454711914, 23.5 },
        { -101.04438018799, -1004.5454711914, 23.5, -99.627067565918, -1006.5540771484, 23.5 },
        { -99.627067565918, -1006.5540771484, 23.5, -97.998123168945, -1008.8626098633, 23.5 },
        { -97.998123168945, -1008.8626098633, 23.5, -96.503005981445, -1010.9815063477, 23.5 },
        { -96.503005981445, -1010.9815063477, 23.5, -95.364593505859, -1012.5949707031, 23.5 },
        { -95.364593505859, -1012.5949707031, 23.5, -94.521308898926, -1013.8146972656, 23.5 },
        { -94.521308898926, -1013.8146972656, 23.5, -93.006774902344, -1016.0053100586, 23.5 },
        { -93.006774902344, -1016.0053100586, 23.5, -91.886283874512, -1017.6798706055, 23.5 },
        { -91.886283874512, -1017.6798706055, 23.5, -90.552085876465, -1019.7059326172, 23.5 },
        { -90.552085876465, -1019.7059326172, 23.5, -89.094711303711, -1021.9188842773, 23.5 },
        { -89.094711303711, -1021.9188842773, 23.5, -88.028762817383, -1023.556640625, 23.5 },
        { -88.028762817383, -1023.556640625, 23.5, -86.776412963867, -1025.4898681641, 23.5 },
        { -86.776412963867, -1025.4898681641, 23.5, -85.820121765137, -1026.8999023438, 23.5 }
    }
}

local TRUCK_RENTED_CHOICES = {
    u8"�� �������",
    u8"����� �����������",
    u8"����� ��� � ����"
}

local SCRIPT_STATUSES = {
    u8"��������",
    u8"�������"
}

local PINS = {}

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
    PINS = PINS
}