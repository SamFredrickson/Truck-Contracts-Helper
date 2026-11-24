local imgui = require "mimgui"
local Theme = require "tch.gui.themes.theme"
local Scale = require "tch.gui.scale"
local Navigation = {}

function Navigation.button(id, label, selected)
    if selected then imgui.PushStyleColor(imgui.Col.Button, Theme.color("active")) end
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, Scale.px(6))
    local clicked = imgui.Button("##Navigation" .. id, Scale.vec(140, 45))
    imgui.PopStyleVar()
    if selected then imgui.PopStyleColor(1) end

    local first, last = imgui.GetItemRectMin(), imgui.GetItemRectMax()
    local center = imgui.ImVec2(first.x + Scale.px(17), (first.y + last.y) / 2)
    local draw = imgui.GetWindowDrawList()
    local color = imgui.ColorConvertFloat4ToU32(Theme.color(selected and "accent" or "muted"))
    local thickness = Scale.px(1.5)
    local function point(x, y) return imgui.ImVec2(center.x + Scale.px(x), center.y + Scale.px(y)) end
    local function line(x1, y1, x2, y2) draw:AddLine(point(x1, y1), point(x2, y2), color, thickness) end

    if id == 1 then
        draw:AddCircle(center, Scale.px(6), color, 20, thickness)
        draw:AddCircle(center, Scale.px(2.5), color, 16, thickness)
        for i = 0, 7 do
            local angle = i * math.pi / 4
            line(math.cos(angle) * 6, math.sin(angle) * 6, math.cos(angle) * 9, math.sin(angle) * 9)
        end
    elseif id == 2 then
        draw:AddRect(point(-9, -6), point(9, 6), color, Scale.px(2), 15, thickness)
        for row = 0, 1 do
            for column = 0, 3 do line(-6 + column * 4, -3 + row * 3, -5 + column * 4, -3 + row * 3) end
        end
        line(-4, 3, 4, 3)
    elseif id == 3 then
        draw:AddRect(point(-6, -9), point(6, 9), color, Scale.px(1), 15, thickness)
        line(-3, -4, 3, -4)
        line(-3, 0, 3, 0)
        line(-3, 4, 2, 4)
    elseif id == 4 then
        draw:AddRectFilled(point(-8, 2), point(-4, 8), color, Scale.px(1), 15)
        draw:AddRectFilled(point(-2, -3), point(2, 8), color, Scale.px(1), 15)
        draw:AddRectFilled(point(4, -8), point(8, 8), color, Scale.px(1), 15)
    end

    local text = imgui.CalcTextSize(label)
    draw:AddText(imgui.ImVec2(first.x + Scale.px(34), (first.y + last.y - text.y) / 2),
        imgui.ColorConvertFloat4ToU32(Theme.color("text")), label)
    return clicked
end

return Navigation