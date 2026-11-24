local imgui = require "mimgui"
local Palette = require "tch.gui.themes.palette"
local Scale = require "tch.gui.scale"
local Theme = {}

function Theme.color(role, alpha)
    local hex = Palette.color(role)
    return imgui.ImVec4(tonumber(hex:sub(1, 2), 16) / 255,
        tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, alpha or 1)
end

function Theme.apply(mode)
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = Scale.vec(6, 6)
    imgui.GetStyle().FramePadding = Scale.vec(5, 4)
    imgui.GetStyle().ItemSpacing = Scale.vec(6, 5)
    imgui.GetStyle().ItemInnerSpacing = Scale.vec(4, 4)
    imgui.GetStyle().TouchExtraPadding = Scale.vec(0, 0)
    imgui.GetStyle().IndentSpacing = Scale.px(8)
    imgui.GetStyle().ScrollbarSize = Scale.px(10)
    imgui.GetStyle().GrabMinSize = Scale.px(10)
    imgui.GetStyle().WindowBorderSize = Scale.px(1)
    imgui.GetStyle().ChildBorderSize = Scale.px(0)
    imgui.GetStyle().PopupBorderSize = Scale.px(1)
    imgui.GetStyle().FrameBorderSize = Scale.px(1)
    imgui.GetStyle().TabBorderSize = Scale.px(0)
    imgui.GetStyle().WindowRounding = Scale.px(5)
    imgui.GetStyle().ChildRounding = Scale.px(5)
    imgui.GetStyle().PopupRounding = Scale.px(5)
    imgui.GetStyle().ScrollbarRounding = Scale.px(10)
    imgui.GetStyle().GrabRounding = Scale.px(4)
    imgui.GetStyle().TabRounding = Scale.px(4)
    local style = imgui.GetStyle()
    local light = Palette.current().light
    local transparent = mode == "transparent"
    local alpha = transparent and (light and 0.94 or 0.78) or 1
    local function set(name, role, opacity)
        if imgui.Col[name] ~= nil then style.Colors[imgui.Col[name]] = Theme.color(role, opacity) end
    end
    set("Text", "text")
    set("TextDisabled", "muted")
    set("WindowBg", "bg", alpha)
    set("PopupBg", "bg", 1)
    set("Border", "button")
    style.Colors[imgui.Col.ChildBg] = imgui.ImVec4(0, 0, 0, 0)
    style.Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0, 0, 0, 0)
    for _, name in ipairs({ "FrameBg", "TitleBg", "TitleBgCollapsed", "MenuBarBg", "ScrollbarBg", "Tab", "TabUnfocused" }) do set(name, "surface") end
    for _, name in ipairs({ "Button", "Header", "TitleBgActive", "ScrollbarGrab", "TabActive", "TabUnfocusedActive", "Separator" }) do set(name, "button") end
    for _, name in ipairs({ "ButtonHovered", "HeaderHovered", "FrameBgHovered", "ScrollbarGrabHovered", "TabHovered", "SeparatorHovered", "ResizeGripHovered" }) do set(name, "hover") end
    for _, name in ipairs({ "ButtonActive", "HeaderActive", "FrameBgActive", "ScrollbarGrabActive", "SeparatorActive", "ResizeGripActive" }) do set(name, "active") end
    for _, name in ipairs({ "CheckMark", "SliderGrab", "SliderGrabActive", "PlotLinesHovered", "PlotHistogram", "PlotHistogramHovered", "NavHighlight" }) do set(name, "accent") end
    set("ResizeGrip", "button", 0.6)
    set("PlotLines", "muted")
    set("TextSelectedBg", "accent", 0.3)
    if mode == "info" then style.WindowRounding = Scale.px(3) end
    imgui.GetIO().FontGlobalScale = Scale.factor()
    return {}
end

function Theme.new()
    return Theme.apply()
end

return Theme