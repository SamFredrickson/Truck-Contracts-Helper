local Config = require "tch.common.config"
local Palette = {}

Palette.options = {
    { id = "pink", name = "Розовая", bg = "30212B", surface = "47313F", button = "70475F", hover = "865570", active = "985F80", accent = "EBA4CC", text = "FFF1F8", muted = "D0B7C7" },
    { id = "red", name = "Красная", bg = "1B1719", surface = "302326", button = "663039", hover = "853C46", active = "A34854", accent = "ED737B" },
    { id = "burgundy", name = "Бордовая", bg = "21151C", surface = "38212D", button = "632A46", hover = "803757", active = "99456B", accent = "E692B1" },
    { id = "black", name = "Чёрная", bg = "080808", surface = "181818", button = "282828", hover = "383838", active = "4A4A4A", accent = "D6D6D6", text = "F2F2F2", muted = "B8B8B8" },
    { id = "white", name = "Белая", bg = "F2F4F7", surface = "E1E6ED", button = "D0DDED", hover = "BACDE6", active = "A3BDDE", accent = "214F87", light = true, chatAccent = "8BB9F0" },
    { id = "blue", name = "Синяя", bg = "131C29", surface = "203149", button = "2A4769", hover = "365D88", active = "365F87", accent = "80B9F2" },
    { id = "green", name = "Зелёная", bg = "141F1C", surface = "243931", button = "2C5444", hover = "386D57", active = "376C57", accent = "78CFAA" }
}

local byId = {}
for _, palette in ipairs(Palette.options) do byId[palette.id] = palette end

function Palette.current()
    return byId[Config.new().data.settings.theme] or byId.red
end

function Palette.color(role, chat)
    local palette = Palette.current()
    if role == "text" then return palette.text or (palette.light and not chat and "222B38" or "F1F3F5") end
    if role == "muted" then return palette.muted or (palette.light and not chat and "536071" or "B4BAC4") end
    if role == "success" then return palette.light and not chat and "176B45" or "7CD6A1" end
    if role == "error" then return palette.light and not chat and "A12436" or "FF929C" end
    if role == "warning" then return palette.light and not chat and "825300" or "F0CF82" end
    if role == "accent" then return chat and (palette.chatAccent or palette.accent) or palette.accent end
    return palette[role]
end

local roles = {
    FFFFFF = "text", EFF1F3 = "text", FFECD1 = "text", AAAAAA = "muted",
    ED5A5A = "accent", F2545B = "accent", F4CBC6 = "accent", AE433D = "accent",
    ["32CD32"] = "success", ["3E9C35"] = "success", ["50C878"] = "success",
    B4140E = "error", EE4B2B = "error", FFCC00 = "warning", FCCB06 = "warning"
}

function Palette.recolor(text, chat)
    return (text:gsub("{(%x+)}", function(tag)
        if #tag ~= 6 and #tag ~= 8 then return "{" .. tag .. "}" end
        local role = roles[tag:sub(1, 6):upper()]
        if role then return "{" .. Palette.color(role, chat) .. tag:sub(7) .. "}" end
        return "{" .. tag .. "}"
    end))
end

return Palette