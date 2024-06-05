local imgui = require "mimgui"
local encoding = require "encoding"
local Window = require "tch.gui.windows.window"
local constants = require "tch.constants"
local Config = require "tch.common.config"
local RedTheme = require "tch.gui.themes.red"
local vkeys = require "vkeys"
local Hotkeys = require "tch.common.storage.hotkeys"

encoding.default = "CP1251"
local u8 = encoding.UTF8
local config = Config.new()
local hotKeys = Hotkeys.new()

local HotKeysManager = {
    new = function()
        local self = Window.new()
        self.title = u8("Горячие клавиши")
        self.menu = nil -- Menu Window
        self.previousHotKey = nil
        self.first = nil
        self.second = nil

        local screenX, screenY = getScreenResolution()
        local position = imgui.ImVec2(screenX / 2, screenY / 2)
        local size = imgui.ImVec2(300, 200)
        local forbidden = { "VK_ESCAPE", "VK_RETURN", "VK_BACK", "VK_LBUTTON", "VK_RBUTTON" }

        lua_thread.create
        (
            function()
                while true do
                    wait(0)
                    if self.window[0] then
                        for key, value in pairs(vkeys) do
                            if wasKeyPressed(value) then
                                if value < 160 or value > 165 then
                                    if not self.first
                                    and not self.second
                                    and not includes(key, forbidden) then
                                        self.first = value
                                    end
                                    if self.first
                                    and not self.second 
                                    and self.first ~= value
                                    and not includes(key, forbidden)
                                    and not select(2, table.unpack(self.previousHotKey)).single then
                                        self.second = value
                                    end
                                    if key == "VK_ESCAPE" then
                                        self.deactivate()
                                        self.first = nil
                                        self.second = nil
                                    end
                                    if key == "VK_RETURN" then
                                        local index, hotkey = table.unpack(self.previousHotKey)
                                        local first = self.first and vkeys.id_to_name(self.first):upper() or false
                                        local second = self.second and vkeys.id_to_name(self.second):upper() or false
                                        local format = not second and "%s" or "%s + %s"
                                        local text = string.format(format, first, second)
                
                                        hotKeys.data[index].first = self.first and self.first or hotKeys.data[index].first
                                        hotKeys.data[index].second = self.second and self.second or hotKeys.data[index].second
                                        hotKeys.data[index].buttonText = text
                
                                        self.first = nil
                                        self.second = nil
                                        self.menu.activate()
                                        self.deactivate()
                                        hotKeys.save()
                                    end
                                    if key == "VK_BACK" then
                                        self.first = nil
                                        self.second = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        )

        imgui.OnFrame
        (
            function() return self.window[0] end,
            function(player)
                RedTheme.new()
                imgui.SetNextWindowPos(position, imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
                imgui.SetNextWindowSize(size, imgui.Cond.FirstUseEver)

                imgui.Begin
                (
                    self.title, 
                    self.window, 
                    imgui.WindowFlags.NoResize 
                    + imgui.WindowFlags.NoCollapse
                    + imgui.WindowFlags.NoScrollbar
                    + imgui.WindowFlags.NoScrollWithMouse
                    + imgui.WindowFlags.NoMove
                )
                imgui.SetCursorPos(imgui.ImVec2(10, 30))
                imgui.BeginChild("##HotKeysManagerIntro")
                    imgui.TextColoredRGB("{FFECD1}Нажмите комбинацию или одну клавишу для \n{FFECD1}установки. {FFECD1}Backspace - {EE4B2B}отмена{FFECD1}, {FFECD1}Enter - {50C878}подтве\n{50C878}рдить")
                imgui.EndChild()

                if not self.first and not self.second then
                    imgui.SetCursorPos(imgui.ImVec2(10, 105))
                    imgui.BeginChild("##HotKeysManagerCombination")
                        imgui.PushFont(bigFontSize)
                        local text = select(2, table.unpack(self.previousHotKey)).buttonText
                        imgui.TextColoredRGB(text)
                        imgui.PopFont()
                    imgui.EndChild()
                end

                if self.first or self.second then
                    local first = self.first and vkeys.id_to_name(self.first):upper() or false
                    local second = self.second and vkeys.id_to_name(self.second):upper() or false
                    local format = not second and "%s" or "%s + %s"
                    local text = string.format(format, first, second)

                    imgui.SetCursorPos(imgui.ImVec2(10, 105))
                    imgui.BeginChild("##HotKeysManagerCombination")
                        imgui.PushFont(bigFontSize)
                        imgui.TextColoredRGB(text)
                        imgui.PopFont()
                    imgui.EndChild()
                end
                
                imgui.SetCursorPos(imgui.ImVec2(4, 165))
                imgui.BeginChild("##HotKeyManagerButtons")
                    if imgui.Button(u8("Подтвердить"), imgui.ImVec2(100, 30)) then
                        local index, hotkey = table.unpack(self.previousHotKey)
                        local first = self.first and vkeys.id_to_name(self.first):upper() or false
                        local second = self.second and vkeys.id_to_name(self.second):upper() or false
                        local format = not second and "%s" or "%s + %s"
                        local text = string.format(format, first, second)

                        hotKeys.data[index].first = self.first and self.first or hotKeys.data[index].first
                        hotKeys.data[index].second = self.second and self.second or hotKeys.data[index].second
                        hotKeys.data[index].buttonText = text

                        self.first = nil
                        self.second = nil
                        self.menu.activate()
                        self.deactivate()
                        hotKeys.save()
                    end
                    imgui.SameLine()
                    if imgui.Button(u8(select(2, table.unpack(self.previousHotKey)).deleted and "Вернуть" or "Удалить"), imgui.ImVec2(80, 30)) then
                        local index, hotkey = table.unpack(self.previousHotKey)
                        hotKeys.data[index].deleted = not hotKeys.data[index].deleted
                        self.first = nil
                        self.second = nil
                        self.menu.activate()
                        self.deactivate()
                        hotKeys.save()
                    end
                    imgui.SameLine()
                    if imgui.Button(u8("Отменить"), imgui.ImVec2(100, 30)) then
                        self.menu.activate()
                        self.deactivate()
                        self.first = nil
                        self.second = nil
                    end
                imgui.EndChild()
                imgui.End()
            end
        )

        return self
    end
}

return HotKeysManager