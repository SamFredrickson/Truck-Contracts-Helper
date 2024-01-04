local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local SCRIPT_INFO = {
    AUTHOR = "SAM",
    VERSION = "1.0.0",
    MOONLOADER = 026,
    VERSION_NUMBER = 1,
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
    MULTIPLE_CONTRACTS = "({AE433D}%d%. {FFFFFF}%W+ №%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ из %d+ т%.	{A9A9A9}[A-Za-z0-9%s%-]+)",
    SINGLE_CONTRACT = "{AE433D}(%d+)%. {FFFFFF}(%W+ №%d+) %-%> (%W+){A9A9A9}(%W+){33AA33}(%d+) из (%d+) т%.	{A9A9A9}([A-Za-z0-9%s%-]+)"
}


SCRIPT_INFO.NAME = string.format("Truck Contracts Helper %s (%d)", SCRIPT_INFO.VERSION, SCRIPT_INFO.VERSION_NUMBER)

return {
    SCRIPT_INFO = SCRIPT_INFO,
    COLORS = COLORS,
    REGEXP = REGEXP
}