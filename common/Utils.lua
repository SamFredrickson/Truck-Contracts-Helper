local imgui = require "mimgui"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Utils = {
    
}

Utils.TextColoredRGB = function(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local col = imgui.Col
    
    local designText = function(text__)
        local pos = imgui.GetCursorPos()
        if sampGetChatDisplayMode() == 2 then
            for i = 1, 1 --[[Степень тени]] do
                imgui.SetCursorPos(imgui.ImVec2(pos.x + i, pos.y))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x - i, pos.y))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y + i))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
                imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y - i))
                imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
            end
        end
        imgui.SetCursorPos(pos)
    end
    
    local text = text:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')

    local color = colors[col.Text]
    local start = 1
    local a, b = text:find('{........}', start)   
    
    while a do
        local t = text:sub(start, a - 1)
        if #t > 0 then
            designText(t)
            imgui.TextColored(color, t)
            imgui.SameLine(nil, 0)
        end

        local clr = text:sub(a + 1, b - 1)
        if clr:upper() == 'STANDART' then color = colors[col.Text]
        else
            clr = tonumber(clr, 16)
            if clr then
                local r = bit.band(bit.rshift(clr, 24), 0xFF)
                local g = bit.band(bit.rshift(clr, 16), 0xFF)
                local b = bit.band(bit.rshift(clr, 8), 0xFF)
                local a = bit.band(clr, 0xFF)
                color = imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
            end
        end

        start = b + 1
        a, b = text:find('{........}', start)
    end
    imgui.NewLine()
    if #text >= start then
        imgui.SameLine(nil, 0)
        designText(text:sub(start))
        imgui.TextColored(color, text:sub(start))
    end
end

return Utils

-- for capture in text:gmatch("({AE433D}%d%. {FFFFFF}%W+ №%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ из %d+ т%.	{A9A9A9}[A-Za-z0-9%s%-]+)") do
--     print(capture)
-- end

-- for capture in text:gmatch("({AE433D}%d%. {FFFFFF}%W+ №%d %-%> %W+{A9A9A9}%W+{33AA33}%d+ из %d+ т%.	{A9A9A9}[A-Za-z0-9%s%-]+)") do
--     local id, source, destination, cargo, amountFirst, amountSecond, company = capture:match("{AE433D}(%d+)%. {FFFFFF}(%W+ №%d+) %-%> (%W+){A9A9A9}(%W+){33AA33}(%d+) из (%d+) т%.	{A9A9A9}([A-Za-z0-9%s%-]+)")
--     print(source)
-- end