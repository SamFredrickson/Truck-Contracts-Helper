local imgui = require "mimgui"
local Theme = require "tch.gui.themes.theme"
local Palette = require "tch.gui.themes.palette"
local Scale = require "tch.gui.scale"
local Icons = {}

function Icons.width(contract)
    return Scale.px((contract.top and 16 or 0) + (contract.IsPinned and 16 or 0))
end

function Icons.star(position, height, selected)
    local draw = imgui.GetWindowDrawList()
    local center = imgui.ImVec2(position.x + Scale.px(8), position.y + height / 2)
    local gold = Palette.current().light and imgui.ImVec4(0.58, 0.39, 0.02, 1) or imgui.ImVec4(1, 0.79, 0.24, 1)
    local gray = Palette.current().light and imgui.ImVec4(0.4, 0.4, 0.4, 1) or imgui.ImVec4(0.65, 0.65, 0.65, 1)
    local color = imgui.ColorConvertFloat4ToU32(selected and gold or gray)
    local vertices = {}
    for i = 0, 9 do
        local angle = -math.pi / 2 + i * math.pi / 5
        local radius = Scale.px(i % 2 == 0 and 7 or 3.2)
        vertices[i + 1] = imgui.ImVec2(center.x + math.cos(angle) * radius, center.y + math.sin(angle) * radius)
    end
    for i = 1, 10 do
        draw:AddTriangleFilled(center, vertices[i], vertices[i % 10 + 1], color)
    end
end

function Icons.draw(contract, position, height)
    local draw = imgui.GetWindowDrawList()
    local centerY = position.y + height / 2
    if contract.top then Icons.star(position, height, true) end
    if contract.IsPinned then
        local x = position.x + Scale.px(contract.top and 24 or 8)
        local color = imgui.ColorConvertFloat4ToU32(Theme.color("text"))
        draw:AddLine(imgui.ImVec2(x, centerY + Scale.px(1)), imgui.ImVec2(x - Scale.px(2), centerY + Scale.px(7)), color, Scale.px(1.5))
        draw:AddTriangleFilled(imgui.ImVec2(x - Scale.px(4), centerY + Scale.px(1)), imgui.ImVec2(x + Scale.px(4), centerY + Scale.px(1)), imgui.ImVec2(x, centerY - Scale.px(4)), color)
        draw:AddLine(imgui.ImVec2(x - Scale.px(3), centerY - Scale.px(4)), imgui.ImVec2(x + Scale.px(3), centerY - Scale.px(4)), color, Scale.px(2))
    end
end

return Icons