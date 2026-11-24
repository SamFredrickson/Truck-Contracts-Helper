local imgui = require "mimgui"
local Config = require "tch.common.config"
local Scale = { options = { 100, 110, 125, 150 } }

function Scale.percent()
    local value = tonumber(Config.new().data.settings.uiScale)
    for _, percent in ipairs(Scale.options) do
        if percent == value then return percent end
    end
    return 100
end

function Scale.factor() return Scale.percent() / 100 end
function Scale.px(value) return value * Scale.factor() end

function Scale.width(value)
    return value > 0 and Scale.px(value) or value
end

function Scale.vec(x, y)
    return imgui.ImVec2(Scale.width(x), Scale.width(y))
end

function Scale.windowSize(width, height)
    local screenX, screenY = getScreenResolution()
    return imgui.ImVec2(math.min(Scale.px(width), screenX - 20), math.min(Scale.px(height), screenY - 20))
end

function Scale.clampPosition(position, width, height)
    local screenX, screenY = getScreenResolution()
    return imgui.ImVec2(math.max(0, math.min(position.x, screenX - width)),
        math.max(0, math.min(position.y, screenY - height)))
end

return Scale
