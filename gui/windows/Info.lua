local imgui = require "mimgui"
local Scale = require "tch.gui.scale"
local encoding = require "encoding"
local InfoEntry = require "tch.entities.infoentry"
local Information = require "tch.entities.information"
local Time = require "tch.entities.time"
local Number = require "tch.entities.number"
local Window = require "tch.gui.windows.window"
local InfoTheme = require "tch.gui.themes.info"
local Theme = require "tch.gui.themes.theme"
local Config = require "tch.common.config"
local Statistics = require "tch.common.storage.statistics"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()

local TWO_HOURS = 3600 * 2
local raceTime = Time.new(0).toString()
local illegalCargoAvailableAt = config.data.settings.lastIllegalCargoUnloadedAt + TWO_HOURS
local illegalCargoAvailableAtFormatted = Time.new(os.difftime(illegalCargoAvailableAt, os.time())).toString()
local sessionEarnings = Number.new(config.data.settings.sessionEarnings).format(0, "", "{F2545B}")
local sessionExperience = Number.new(config.data.settings.sessionExperience).format(0, "", "{F2545B}")
local experienceToLevel = Number.new(0).format(0, "", "{F2545B}")
local raceQuantity = config.data.settings.sessionRaceQuantity

local rawEntries = {}
local function makeEntry(title, code, value)
    local entry = InfoEntry.new(title, code, value)
    rawEntries[code] = entry
    return entry
end

local information = Information.new
(
    makeEntry
    (
        "Рейс:", 
        "race", 
        "—"
    ),
    makeEntry
    (
        "Время в рейсе:", 
        "race-time", 
        raceTime
    ),
    makeEntry
    (
        "Нелегальный груз:", 
        "illegal-cargo-time", 
        illegalCargoAvailableAtFormatted
    ),
    makeEntry
    (
        "Опыта за сессию:", 
        "session-experience",
        sessionExperience
    ),
    makeEntry
    (
        "Опыта до N уровня:", 
        "experience-to-level",
        experienceToLevel
    ),
    makeEntry(
        "Рейсов за сессию:",
        "session-races",
        raceQuantity
    ),
    makeEntry
    (
        "Заработано за сессию:",
        "session-earnings",
        sessionEarnings
    ),
    makeEntry
    (
        "Заработано за всё время:",
        "total-earnings",
        0
    )
)

local labels = {
    ["race-time"] = "В пути",
    ["illegal-cargo-time"] = "Нелегалка",
    ["session-experience"] = "Опыт за сессию",
    ["session-races"] = "Рейсов",
    ["session-earnings"] = "За сессию",
    ["total-earnings"] = "За всё время"
}

local function plain(value)
    return tostring(value):gsub("{%x+}", "")
end

local function color(role, alpha)
    return imgui.ColorConvertFloat4ToU32(Theme.color(role, alpha))
end

local function display(entry)
    local raw = rawEntries[entry.code]
    local value = plain(raw.value)
    local label = labels[entry.code] or raw.title:gsub(":$", "")
    local role = "text"
    if entry.code == "race" then
        if value == "—" or value == "" then value = "Нет активного рейса" end
        return "", value, role
    elseif entry.code == "illegal-cargo-time" then
        if value == "00:00:00" then return "Нелегалка", "доступна", "success" end
        role = "warning"
    elseif entry.code == "session-earnings" or entry.code == "total-earnings" then
        -- Keep the existing total calculation and its live JSON updates.
        if entry.code == "total-earnings" then
            local formatted = entry.getValue()
            value = plain(formatted):match(":%s*(.-)%s*$") or value
            if formatted:find("{F2545B}", 1, true) then value = "-" .. value end
        else
            if tostring(raw.value):find("{F2545B}", 1, true) then value = "-" .. value end
            value = value .. "$"
        end
        if value:find("-", 1, true) then role = "error"
        elseif value:find("[1-9]") then role = "success" end
    end
    return label, value, role
end

local Info = {
    new = function()
        local self = Window.new()
        self.title = u8("Информация")
        self.information = information
        self.entries = {}
        for _, entry in pairs(information) do self.entries[entry.id] = entry end

        imgui.OnFrame(
            function() return self.window[0] end,
            function(player)
                if config.data.settings.selectedScriptStatus == 0 then return end
                if not config.data.settings.statistics then return end
                InfoTheme.new()
                local visible = {}
                for _, setting in pairs(Statistics.new().data) do
                    if setting.show then visible[setting.code] = true end
                end
                local screenX, screenY = getScreenResolution()
                local padding, gap = Scale.px(10), Scale.px(18)
                local lineHeight = imgui.GetTextLineHeight()
                local rowHeight = lineHeight + Scale.px(7)
                local maxWidth = math.max(1, screenX - padding * 2)
                local items, x, row, usedWidth = {}, 0, 0, 0
                for _, entry in ipairs(self.entries) do
                    if visible[entry.code] then
                        local label, value, role = display(entry)
                        local labelText = label ~= "" and label .. " " or ""
                        local labelWidth = imgui.CalcTextSize(u8(labelText)).x
                        local valueGap = entry.code == "illegal-cargo-time" and Scale.px(5) or 0
                        local width = labelWidth + valueGap + imgui.CalcTextSize(u8(value)).x + Scale.px(2)
                        local icon = entry.code == "race-time" or entry.code == "illegal-cargo-time"
                        local iconWidth = icon and Scale.px(17) or 0
                        width = math.min(maxWidth, width + iconWidth)
                        if x > 0 and x + width > maxWidth then x, row = 0, row + 1 end
                        items[#items + 1] = { x = x, row = row, label = label,
                            value = value, role = role, icon = icon, width = width, iconWidth = iconWidth, valueGap = valueGap }
                        usedWidth = math.max(usedWidth, x + width)
                        x = x + width + gap
                    end
                end
                if #items == 0 then return end
                local contentWidth = math.min(maxWidth, usedWidth)
                local rows = row + 1
                local height = rows * rowHeight + padding * 2 - Scale.px(7)
                local width = contentWidth + padding * 2
                local alignment = tonumber(config.data.settings.infoPanelAlignment) or 0
                local offset = alignment == 1 and 0.5 or (alignment == 2 and 1 or 0)
                local panelX = math.max(0, (screenX - width) * offset)
                imgui.SetNextWindowPos(imgui.ImVec2(panelX, screenY - height), imgui.Cond.Always)
                imgui.SetNextWindowSize(imgui.ImVec2(contentWidth + padding * 2, height), imgui.Cond.Always)
                player.HideCursor = true
                imgui.PushStyleColor(imgui.Col.WindowBg, Theme.color("bg", 0.9))
                imgui.Begin(self.title, self.window,
                    imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
                    + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove
                    + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
                local origin = imgui.GetWindowPos()
                local draw = imgui.GetWindowDrawList()
                draw:AddLine(imgui.ImVec2(origin.x, origin.y),
                    imgui.ImVec2(origin.x + contentWidth + padding * 2, origin.y), color("accent", 0.7), Scale.px(1))
                local left, top = origin.x + padding, origin.y + padding

                for _, item in ipairs(items) do
                    local ix, iy = left + item.x, top + item.row * rowHeight
                    if item.x > 0 then
                        draw:AddLine(imgui.ImVec2(ix - gap / 2, iy + Scale.px(2)),
                            imgui.ImVec2(ix - gap / 2, iy + lineHeight - Scale.px(2)), color("muted", 0.35))
                    end
                    if item.icon then
                        local cx, cy = ix + Scale.px(6), iy + lineHeight / 2
                        draw:AddCircle(imgui.ImVec2(cx, cy), Scale.px(5), color("muted"), 16, Scale.px(1))
                        draw:AddLine(imgui.ImVec2(cx, cy), imgui.ImVec2(cx, cy - Scale.px(3)), color("muted"))
                        draw:AddLine(imgui.ImVec2(cx, cy), imgui.ImVec2(cx + Scale.px(2), cy + Scale.px(1)), color("muted"))
                        ix = ix + item.iconWidth
                    end
                    local label = item.label ~= "" and item.label .. " " or ""
                    local labelWidth = imgui.CalcTextSize(u8(label)).x
                    draw:AddText(imgui.ImVec2(ix, iy), color("muted"), u8(label))
                    draw:AddText(imgui.ImVec2(ix + labelWidth + item.valueGap, iy), color(item.role), u8(item.value))
                end
                imgui.End()
                imgui.PopStyleColor(1)
            end
        )
        return self
    end
}

function Info.previewEntries()
    local entries = {}
    for _, entry in pairs(information) do
        local label, value, role = display(entry)
        entries[#entries + 1] = { id = entry.id, code = entry.code, label = label, value = value, role = role }
    end
    table.sort(entries, function(a, b) return a.id < b.id end)
    return entries
end
return Info