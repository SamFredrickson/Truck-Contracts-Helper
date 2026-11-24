local imgui = require "mimgui"
local encoding = require "encoding"
local Window = require "tch.gui.windows.window"
local LocalMessage = require "tch.entities.chat.localmessage"
local ContractService = require "tch.services.contractservice"
local ChatService = require "tch.services.chatservice"
local RedThemeTransparent = require "tch.gui.themes.redtransparent"
local RedTheme = require "tch.gui.themes.red"
local Icons = require "tch.gui.contracticons"
local Config = require "tch.common.config"
local Scale = require "tch.gui.scale"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()
local chatService = ChatService.new()
local contractsService = ContractService.new()

local function fitText(text, width)
    if imgui.CalcTextSize(u8(text)).x <= width then return u8(text) end
    while #text > 0 and imgui.CalcTextSize(u8(text .. "...")).x > width do
        text = text:sub(1, -2)
    end
    return u8(text .. "...")
end

local function showDetails(contract)
    if not imgui.IsItemHovered() then return end
    local labels = {}
    if contract.top then labels[#labels + 1] = "Приоритетный маршрут" end
    if contract.IsPinned then labels[#labels + 1] = "Закреплён" end
    labels[#labels + 1] = string.format("%d. %s -> %s", contract.id, contract.source, contract.destination)
    labels[#labels + 1] = string.format("%s: %s / %s т.", contract.cargo, contract.amount.first, contract.amount.second)
    labels[#labels + 1] = contract.company
    imgui.SetTooltip(u8(table.concat(labels, "\n")))
end

local function togglePin(contract)
    local wasPinned = contract.IsPinned
    if wasPinned then
        contractsService.unpin(tonumber(contract.id))
    else
        contractsService.pin(contract)
    end
    contract.IsPinned = not wasPinned
    local action = wasPinned and "откреплён" or "закреплён"
    chatService.send(LocalMessage.new(string.format(" Контракт {ed5a5a}%d. %s -> %s{FFFFFF} успешно {ed5a5a}%s{FFFFFF}.", contract.id, contract.source, contract.destination, action)))
end

local Main = {
    new = function(requestContract)
        local self = Window.new()
        self.hideCursor = true
        local screenX, screenY = getScreenResolution()
        local windowSizes = { { 415, 370 }, { 420, 290 } }
        local compactWidth = tonumber(config.data.settings.compactContractsWidth) or 320
        local savedWidth = compactWidth
        local lastScale
        local lastLayout
        local popupContract
        local position = imgui.ImVec2(config.data.settings.contractsScreenX or screenX - 420, config.data.settings.contractsScreenY or screenY - 410)
        local lastPosition
        local positionChanged = false

        local function savePlacement()
            local settings = config.data.settings
            local oldX, oldY, oldWidth = settings.contractsScreenX, settings.contractsScreenY, settings.compactContractsWidth
            local moved = positionChanged and (oldX ~= position.x or oldY ~= position.y)
            local resized = compactWidth ~= savedWidth
            positionChanged = false
            if not moved and not resized then return end
            if moved then settings.contractsScreenX, settings.contractsScreenY = position.x, position.y end
            savedWidth = compactWidth
            settings.compactContractsWidth = compactWidth
            if not Window.reportSave(config.save()) then
                settings.contractsScreenX, settings.contractsScreenY, settings.compactContractsWidth = oldX, oldY, oldWidth
            end
        end

        local function drawActions(contract, compact)
            local canTake = self.window[0] and contractsService.CanTake()
            local take, load, pin
            if compact then
                take = imgui.MenuItemBool(u8("Взять"), nil, false, canTake)
                load = imgui.MenuItemBool(u8("Взять и загрузить"), nil, false, canTake)
                pin = imgui.MenuItemBool(u8(contract.IsPinned and "Открепить" or "Закрепить"), nil, false, true)
            else
                take = imgui.Button(u8("Взять"), Scale.vec(90, 0)) and canTake
                imgui.SameLine()
                load = imgui.Button(u8("Взять и загрузить"), Scale.vec(130, 0)) and canTake
                imgui.SameLine()
                pin = imgui.Button(u8(contract.IsPinned and "Открепить" or "Закрепить"), imgui.ImVec2(-1, 0))
            end
            if take then requestContract(contract, false) end
            if load then requestContract(contract, true) end
            if pin then togglePin(contract) end
        end

        imgui.OnFrame(
            function()
                local visible = self.window[0] and config.data.settings.selectedScriptStatus ~= 0
                if not visible then
                    savePlacement()
                    lastPosition = nil
                end
                return visible
            end,
            function(player)
                ((config.data.settings.transparentContracts and self.hideCursor) and RedThemeTransparent or RedTheme).new()
                local contracts = contractsService.getContracts()
                local layout = config.data.settings.contractWindowTypes
                local compact = layout == 2
                self.title = string.format(u8("Список контрактов (%d)"), #contracts)
                local flags = imgui.WindowFlags.NoCollapse
                local rowHeight = imgui.GetTextLineHeight() + Scale.px(6)
                local style = imgui.GetStyle()
                local height = imgui.GetFrameHeight() + style.WindowPadding.y * 2
                    + math.max(1, math.min(#contracts, 6)) * rowHeight
                    + math.max(0, math.min(#contracts, 6) - 1) * style.ItemSpacing.y
                local size
                local scale = Scale.percent()
                if compact then
                    local resolutionX = getScreenResolution()
                    local maxWidth = math.min(Scale.px(800), resolutionX - 20)
                    local minWidth = math.min(Scale.px(260), maxWidth)
                    local width = math.max(minWidth, math.min(Scale.px(compactWidth), maxWidth))
                    size = imgui.ImVec2(width, height)
                    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(minWidth, height), imgui.ImVec2(maxWidth, height))
                    local unchanged = lastLayout == layout and lastScale == scale
                    imgui.SetNextWindowSize(size, unchanged and imgui.Cond.FirstUseEver or imgui.Cond.Always)
                else
                    flags = flags + imgui.WindowFlags.NoResize
                    local baseSize = windowSizes[layout + 1] or windowSizes[1]
                    size = Scale.windowSize(baseSize[1], baseSize[2])
                    imgui.SetNextWindowSize(size, imgui.Cond.Always)
                end
                if lastLayout ~= layout or lastScale ~= scale then
                    local clamped = Scale.clampPosition(position, size.x, size.y)
                    if clamped.x ~= position.x or clamped.y ~= position.y then positionChanged = true end
                    position = clamped
                    lastPosition = nil
                    imgui.SetNextWindowPos(position, imgui.Cond.Always)
                end
                lastLayout, lastScale = layout, scale
                imgui.Begin(self.title .. "###TchContracts", self.window, flags)
                player.HideCursor = self.hideCursor
                local windowPosition = imgui.GetWindowPos()
                local dragging = not self.hideCursor and imgui.IsMouseDown(0)
                if (dragging or positionChanged) and lastPosition
                and (windowPosition.x ~= lastPosition.x or windowPosition.y ~= lastPosition.y) then
                    position = windowPosition
                    positionChanged = true
                end
                lastPosition = windowPosition
                if compact then compactWidth = imgui.GetWindowSize().x / Scale.factor() end
                if not dragging then savePlacement() end

                if #contracts == 0 then imgui.Text(u8("Нет подходящих контрактов")) end
                for _, contract in ipairs(contracts) do
                    imgui.PushIDInt(tonumber(contract.id))
                    local origin = imgui.GetCursorScreenPos()
                    if compact then
                        local width = imgui.GetContentRegionAvail().x
                        if imgui.Selectable("##Contract", false, 0, imgui.ImVec2(width, rowHeight)) then
                            popupContract = contract
                            imgui.OpenPopup("ContractActions")
                        end
                        Icons.draw(contract, origin, rowHeight)
                        local text = string.format("%d. %s -> %s", contract.id, contract.source, contract.destination)
                        local draw = imgui.GetWindowDrawList()
                        draw:AddText(imgui.ImVec2(origin.x + Icons.width(contract) + Scale.px(4), origin.y + Scale.px(3)),
                            imgui.ColorConvertFloat4ToU32(style.Colors[imgui.Col.Text]),
                            fitText(text, math.max(0, width - Icons.width(contract) - Scale.px(4))))
                        showDetails(contract)
                    else
                        local expanded = imgui.CollapsingHeader("###Contract")
                        local itemMin, itemMax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
                        local height = itemMax.y - itemMin.y
                        local iconOrigin = imgui.ImVec2(itemMin.x + imgui.GetFrameHeight(), itemMin.y)
                        Icons.draw(contract, iconOrigin, height)
                        local textX = iconOrigin.x + Icons.width(contract) + Scale.px(4)
                        imgui.GetWindowDrawList():AddText(
                            imgui.ImVec2(textX, itemMin.y + style.FramePadding.y),
                            imgui.ColorConvertFloat4ToU32(style.Colors[imgui.Col.Text]),
                            fitText(contract.toString(), math.max(0, itemMax.x - textX - style.FramePadding.x)))
                        showDetails(contract)
                        if expanded then drawActions(contract, false) end
                    end
                    if compact and imgui.BeginPopup("ContractActions") then
                        if popupContract and contractsService.findMatchingContract(popupContract) then
                            drawActions(contract, true)
                        else
                            imgui.Text(u8("Контракт изменился. Выберите его снова."))
                        end
                        imgui.EndPopup()
                    end
                    imgui.PopID()
                end
                imgui.End()
            end
        )
        return self
    end
}
return Main