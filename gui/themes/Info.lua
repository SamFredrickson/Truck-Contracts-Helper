local Theme = require "tch.gui.themes.theme"
local imgui = require "mimgui"
local encoding = require "encoding"

encoding.default = "CP1251"
local u8 = encoding.UTF8

local Info = {
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
        imgui.GetStyle().WindowRounding = 3
        imgui.GetStyle().ChildRounding = 3
        imgui.GetStyle().PopupRounding = 3
        imgui.GetStyle().ScrollbarRounding = 10
        imgui.GetStyle().GrabRounding = 3
        imgui.GetStyle().TabRounding = 3
    
        -- ѕалитра: Ѕлагородный приглушенно-бордовый фон и м€гкие красные акценты
        imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(0.96, 0.94, 0.94, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.60, 0.52, 0.53, 1.00)
        imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.24, 0.13, 0.14, 0.98) -- ћ€гкий винный фон
        imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.00, 0.00, 0.00, 0.00)
        imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.20, 0.10, 0.11, 0.98)
        imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.42, 0.22, 0.24, 1.00)
        imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
        imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.32, 0.16, 0.18, 1.00)
        imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.46, 0.20, 0.22, 1.00)
        imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.56, 0.24, 0.26, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.28, 0.14, 0.15, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.36, 0.16, 0.18, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.24, 0.13, 0.14, 1.00)
        imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.28, 0.14, 0.15, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.20, 0.10, 0.11, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.42, 0.22, 0.24, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.54, 0.26, 0.29, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.66, 0.32, 0.35, 1.00)
        imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.84, 0.32, 0.35, 1.00)
        imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.72, 0.28, 0.31, 1.00)
        imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.84, 0.32, 0.35, 1.00)
        imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.44, 0.18, 0.20, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.58, 0.22, 0.25, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.68, 0.26, 0.29, 1.00)
        imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.44, 0.18, 0.20, 0.60)
        imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.58, 0.22, 0.25, 0.80)
        imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.68, 0.26, 0.29, 1.00)
        imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.42, 0.22, 0.24, 1.00)
        imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.58, 0.22, 0.25, 1.00)
        imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.68, 0.26, 0.29, 1.00)
        imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.44, 0.18, 0.20, 0.40)
        imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.58, 0.22, 0.25, 0.67)
        imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.68, 0.26, 0.29, 0.95)
        imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.34, 0.16, 0.18, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.54, 0.22, 0.25, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.46, 0.18, 0.20, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(0.28, 0.14, 0.15, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(0.36, 0.16, 0.18, 1.00)
        imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.70, 0.70, 0.70, 1.00)
        imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(0.84, 0.32, 0.35, 1.00)
        imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.84, 0.32, 0.35, 1.00)
        imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(0.94, 0.42, 0.45, 1.00)
        imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.84, 0.32, 0.35, 0.30)

        return self
    end
}

return Info
