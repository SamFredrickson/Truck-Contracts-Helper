local Theme = require "tch.gui.themes.theme"
local imgui = require "mimgui"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local RedTransparent = {
    new = function()
        local self = Theme.new()

        imgui.SwitchContext()
        local ImVec4 = imgui.ImVec4
        imgui.GetStyle().WindowPadding = imgui.ImVec2(6, 6)
        imgui.GetStyle().FramePadding = imgui.ImVec2(5, 4)
        imgui.GetStyle().ItemSpacing = imgui.ImVec2(6, 5)
        imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(4, 4)
        imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
        imgui.GetStyle().IndentSpacing = 8
        imgui.GetStyle().ScrollbarSize = 10
        imgui.GetStyle().GrabMinSize = 10
        imgui.GetStyle().WindowBorderSize = 1
        imgui.GetStyle().ChildBorderSize = 0
        imgui.GetStyle().PopupBorderSize = 1
        imgui.GetStyle().FrameBorderSize = 1
        imgui.GetStyle().TabBorderSize = 0
        imgui.GetStyle().WindowRounding = 6
        imgui.GetStyle().ChildRounding = 6
        imgui.GetStyle().PopupRounding = 6
        imgui.GetStyle().ScrollbarRounding = 10
        imgui.GetStyle().GrabRounding = 4
        imgui.GetStyle().TabRounding = 4
    
        -- Палитра: Полупрозрачный глубокий винный стиль с высокой читаемостью текста
        imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(0.98, 0.96, 0.96, 1.00) -- Текст должен быть непрозрачным
        imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.65, 0.55, 0.56, 0.60)
        imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.22, 0.11, 0.12, 0.45) -- Полупрозрачный матовый винный фон
        imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.00, 0.00, 0.00, 0.00)
        imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.18, 0.09, 0.10, 0.85) -- Попапы чуть плотнее
        imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.46, 0.22, 0.25, 0.40)
        imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.35, 0.14, 0.16, 0.45)
        imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.55, 0.18, 0.22, 0.65)
        imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.65, 0.22, 0.26, 0.75)
        imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.28, 0.12, 0.14, 0.50)
        imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.38, 0.15, 0.17, 0.70)
        imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.22, 0.11, 0.12, 0.40)
        imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.25, 0.12, 0.14, 0.45)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.18, 0.09, 0.10, 0.30)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.46, 0.22, 0.25, 0.55)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.60, 0.26, 0.30, 0.75)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.72, 0.30, 0.35, 0.90)
        imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.90, 0.35, 0.38, 0.95)
        imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.75, 0.28, 0.32, 0.75)
        imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.90, 0.35, 0.38, 0.95)
        imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.46, 0.16, 0.18, 0.50)
        imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.62, 0.22, 0.25, 0.75)
        imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.75, 0.26, 0.30, 0.90)
        imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.46, 0.16, 0.18, 0.40)
        imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.62, 0.22, 0.25, 0.65)
        imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.75, 0.26, 0.30, 0.85)
        imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.46, 0.22, 0.25, 0.40)
        imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.62, 0.22, 0.25, 0.70)
        imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.75, 0.26, 0.30, 0.90)
        imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.46, 0.16, 0.18, 0.30)
        imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.62, 0.22, 0.25, 0.55)
        imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.75, 0.26, 0.30, 0.75)
        imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.35, 0.14, 0.16, 0.45)
        imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.58, 0.20, 0.24, 0.70)
        imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.48, 0.16, 0.20, 0.75)
        imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(0.26, 0.12, 0.14, 0.40)
        imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(0.35, 0.14, 0.16, 0.55)
        imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.75, 0.75, 0.75, 0.70)
        imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(0.90, 0.35, 0.38, 0.95)
        imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.35, 0.38, 0.80)
        imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(0.98, 0.45, 0.48, 0.95)
        imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.90, 0.35, 0.38, 0.35)

        return self
    end
}

return RedTransparent