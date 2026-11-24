local imgui = require "mimgui"
local Palette = require "tch.gui.themes.palette"
local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

local function centerColumn(textWidth)
    imgui.SetCursorPosX(imgui.GetColumnOffset() + (imgui.GetColumnWidth() - textWidth) / 2)
end

local function decodeColor(tag, defaultColor)
    if tag:sub(1, 6):upper() == 'SSSSSS' then
        local alpha = tonumber(tag:sub(7, 8), 16)
        return imgui.ImVec4(defaultColor.x, defaultColor.y, defaultColor.z, alpha and alpha / 255 or defaultColor.w)
    end
    local rgba = tonumber(tag, 16)
    if not rgba then return end
    local r = bit.band(bit.rshift(rgba, 24), 0xFF)
    local g = bit.band(bit.rshift(rgba, 16), 0xFF)
    local b = bit.band(bit.rshift(rgba, 8), 0xFF)
    local a = bit.band(rgba, 0xFF)
    return imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
end

local function renderColoredText(text, centered)
    local defaultColor = imgui.GetStyle().Colors[1]

    for w in Palette.recolor(text):gmatch('[^\r\n]+') do
        if centered then
            local plainText = w:gsub('{.-}', '')
            local textWidth = imgui.CalcTextSize(u8(plainText)).x
            centerColumn(textWidth)
        end
        local text, colors_, m = {}, {}, 1
        w = w:gsub('{(......)}', '{%1FF}')
        while w:find('{........}') do
            local n, k = w:find('{........}')
            local color = decodeColor(w:sub(n + 1, k - 1), defaultColor)
            if color then
                text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                colors_[#colors_ + 1] = color
                m = n
            end
            w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
        end
        if text[0] then
            for i = 0, #text do
                imgui.TextColored(colors_[i] or defaultColor, u8(text[i]))
                imgui.SameLine(nil, 0)
            end
            imgui.NewLine()
        else imgui.Text(u8(w)) end
    end
end

function imgui.TextColoredRGB(text)
    renderColoredText(text, false)
end

function imgui.CenterColumnText(text)
    centerColumn(imgui.CalcTextSize(text).x)
    imgui.Text(text)
end

function imgui.CenterColumnTextRgb(text)
    renderColoredText(text, true)
end

return true
