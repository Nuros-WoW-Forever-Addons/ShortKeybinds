-- ============================================================================
-- ShortKeybinds - Core Engine
-- Shortens action bar keybind text for WoW (e.g. Num Pad 1 -> N1, SHIFT-Num Pad 1 -> S-N1)
-- 100% Taint-Safe Execution with real-time range ticker & Blizzard Options registration
-- ============================================================================

local addonName, ns = ...
_G[addonName] = ns

-- Default Database Configuration
ns.defaults = {
    enabled = true,
    showDash = true,            -- Use 'S-N1' vs 'SN1'
    justifyText = "LEFT",       -- "LEFT", "RIGHT", "CENTER"
    modifierCase = "UPPERCASE", -- "UPPERCASE" ('S-N1') or "LOWERCASE" ('s-n1')
    fontSize = 11,              -- Base hotkey font size
    autoScaleFont = true,       -- Auto scale font size down for long keybinds
    textColor = { r = 1, g = 0.82, b = 0 }, -- Bright golden yellow for contrast
    hideHotkeys = false,         -- Hide keybind text completely if true
    shortenNumpad = true,        -- Shorten Num Pad keys
    shortenModifiers = true,     -- Shorten SHIFT/CTRL/ALT
    shortenMouse = true,         -- Shorten Mouse buttons
    clearText = "Clr",           -- Custom replacement for Numpad 'Clear'
}

-- Initialize DB
function ns:InitDB()
    if not ShortKeybindsDB then
        ShortKeybindsDB = {}
    end
    for k, v in pairs(ns.defaults) do
        if ShortKeybindsDB[k] == nil then
            if type(v) == "table" then
                ShortKeybindsDB[k] = { r = v.r, g = v.g, b = v.b }
            else
                ShortKeybindsDB[k] = v
            end
        end
    end
end

-- Print helper
function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[ShortKeybinds]|r " .. tostring(msg))
end

-- Helper: Get exact action slot ID for any button across all action bars
local function GetButtonActionSlot(button)
    if not button then return nil end

    if button.action and type(button.action) == "number" and button.action > 0 then
        return button.action
    end

    local name = button:GetName()
    if not name then return nil end

    local id = button:GetID()
    if not id or id == 0 then
        id = tonumber(string.match(name, "%d+$")) or 1
    end

    if string.find(name, "^ActionButton") then
        if ActionButton_GetPagedID then
            local pagedID = ActionButton_GetPagedID(button)
            if pagedID and pagedID > 0 then return pagedID end
        end
        return id
    elseif string.find(name, "^MultiBarBottomLeftButton") then
        return 60 + id
    elseif string.find(name, "^MultiBarBottomRightButton") then
        return 48 + id
    elseif string.find(name, "^MultiBarRightButton") then
        return 24 + id
    elseif string.find(name, "^MultiBarLeftButton") then
        return 36 + id
    end

    return nil
end

-- Helper: Get binding action name for an action button
function ns.GetButtonBindingAction(button)
    if not button then return nil end

    if button.buttonType and button:GetID() and button:GetID() > 0 then
        return button.buttonType .. button:GetID()
    end

    local name = button:GetName()
    if not name then return nil end

    local id = button:GetID()
    if not id or id == 0 then
        id = tonumber(string.match(name, "%d+$")) or 1
    end

    if string.find(name, "^ActionButton") then
        return "ACTIONBUTTON" .. id
    elseif string.find(name, "^MultiBarBottomLeftButton") then
        return "MULTIACTIONBAR1BUTTON" .. id
    elseif string.find(name, "^MultiBarBottomRightButton") then
        return "MULTIACTIONBAR2BUTTON" .. id
    elseif string.find(name, "^MultiBarRightButton") then
        return "MULTIACTIONBAR3BUTTON" .. id
    elseif string.find(name, "^MultiBarLeftButton") then
        return "MULTIACTIONBAR4BUTTON" .. id
    elseif string.find(name, "^BonusActionButton") then
        return "ACTIONBUTTON" .. id
    elseif string.find(name, "^PetActionButton") then
        return "BONUSACTIONBUTTON" .. id
    elseif string.find(name, "^ShapeshiftButton") or string.find(name, "^StanceButton") then
        return "SHAPESHIFTBUTTON" .. id
    end

    return nil
end

-- Format Keybinding Text according to user preferences
function ns.FormatKeyText(keyText)
    if not keyText or keyText == "" then return "" end

    if keyText == (RANGE_INDICATOR or "●") or keyText == "●" then
        return keyText
    end

    local text = keyText

    local showDash = true
    if ShortKeybindsDB and ShortKeybindsDB.showDash == false then
        showDash = false
    end
    local dash = showDash and "-" or ""

    local isLower = (ShortKeybindsDB and ShortKeybindsDB.modifierCase == "LOWERCASE")
    local sMod = isLower and "s" or "S"
    local cMod = isLower and "c" or "C"
    local aMod = isLower and "a" or "A"
    local mMod = isLower and "m" or "M"

    -- Modifiers
    if not ShortKeybindsDB or ShortKeybindsDB.shortenModifiers ~= false then
        text = string.gsub(text, "SHIFT%-", sMod .. dash)
        text = string.gsub(text, "CTRL%-", cMod .. dash)
        text = string.gsub(text, "ALT%-", aMod .. dash)
        text = string.gsub(text, "META%-", mMod .. dash)

        -- Handle lowercase/truncated modifier prefixes from default WoW
        text = string.gsub(text, "^s%-", sMod .. dash)
        text = string.gsub(text, "^c%-", cMod .. dash)
        text = string.gsub(text, "^a%-", aMod .. dash)
        text = string.gsub(text, "^m%-", mMod .. dash)
    end

    -- Numpad Keys
    if not ShortKeybindsDB or ShortKeybindsDB.shortenNumpad ~= false then
        local npPrefix = isLower and "n" or "N"
        text = string.gsub(text, "Num Pad (%d)", npPrefix .. "%1")
        text = string.gsub(text, "NUMPAD(%d)", npPrefix .. "%1")

        local clearRepl = (ShortKeybindsDB and ShortKeybindsDB.clearText) or (isLower and "clr" or "Clr")
        text = string.gsub(text, "Clear", clearRepl)
        text = string.gsub(text, "CLEAR", clearRepl)

        text = string.gsub(text, "Num Pad /", npPrefix .. "/")
        text = string.gsub(text, "Num Pad %*", npPrefix .. "*")
        text = string.gsub(text, "Num Pad %-", npPrefix .. "-")
        text = string.gsub(text, "Num Pad %+", npPrefix .. "+")
        text = string.gsub(text, "Num Pad %.", npPrefix .. ".")
        text = string.gsub(text, "Num Pad Enter", npPrefix .. "Ent")

        text = string.gsub(text, "NUMPADDIVIDE", npPrefix .. "/")
        text = string.gsub(text, "NUMPADMULTIPLY", npPrefix .. "*")
        text = string.gsub(text, "NUMPADMINUS", npPrefix .. "-")
        text = string.gsub(text, "NUMPADPLUS", npPrefix .. "+")
        text = string.gsub(text, "NUMPADPERIOD", npPrefix .. ".")
        text = string.gsub(text, "NUMPADDEL", npPrefix .. ".")
        text = string.gsub(text, "NUMPADENTER", npPrefix .. "Ent")
    end

    -- Mouse Buttons
    if not ShortKeybindsDB or ShortKeybindsDB.shortenMouse ~= false then
        local mPrefix = isLower and "m" or "M"
        text = string.gsub(text, "Mouse Button (%d)", mPrefix .. "%1")
        text = string.gsub(text, "MouseButton(%d)", mPrefix .. "%1")
        text = string.gsub(text, "Button(%d)", mPrefix .. "%1")
        text = string.gsub(text, "Mouse Wheel Up", mPrefix .. "wU")
        text = string.gsub(text, "Mouse Wheel Down", mPrefix .. "wD")
        text = string.gsub(text, "WheelUp", mPrefix .. "wU")
        text = string.gsub(text, "WheelDown", mPrefix .. "wD")
    end

    -- General Utility Keys
    text = string.gsub(text, "Spacebar", "Spc")
    text = string.gsub(text, "SPACE", "Spc")
    text = string.gsub(text, "Page Up", "PgUp")
    text = string.gsub(text, "PAGEUP", "PgUp")
    text = string.gsub(text, "Page Down", "PgDn")
    text = string.gsub(text, "PAGEDOWN", "PgDn")
    text = string.gsub(text, "Insert", "Ins")
    text = string.gsub(text, "INSERT", "Ins")
    text = string.gsub(text, "Delete", "Del")
    text = string.gsub(text, "DELETE", "Del")
    text = string.gsub(text, "Home", "Hm")
    text = string.gsub(text, "HOME", "Hm")
    text = string.gsub(text, "End", "End")
    text = string.gsub(text, "END", "End")
    text = string.gsub(text, "Arrow Up", "Up")
    text = string.gsub(text, "UP", "Up")
    text = string.gsub(text, "Arrow Down", "Dn")
    text = string.gsub(text, "DOWN", "Dn")
    text = string.gsub(text, "Arrow Left", "Lt")
    text = string.gsub(text, "LEFT", "Lt")
    text = string.gsub(text, "Arrow Right", "Rt")
    text = string.gsub(text, "RIGHT", "Rt")

    return text
end

-- Update button usable / range color state (Taint-Safe)
function ns.UpdateUsable(button)
    if not button then return end
    if ShortKeybindsDB and ShortKeybindsDB.enabled == false then return end

    local name = button:GetName()
    if not name then return end

    local hotkey = _G[name .. "HotKey"] or button.HotKey or button.hotkey
    if not hotkey then return end

    local isOutOfRange = false
    local slot = GetButtonActionSlot(button)

    if slot and HasAction and HasAction(slot) and IsActionInRange then
        local inRange = IsActionInRange(slot)
        if inRange == 0 or inRange == false then
            isOutOfRange = true
        end
    end

    -- Reset VertexColor multiplier to 1.0 (clears Blizzard's default 0.6, 0.6, 0.6 vertex tint)
    if hotkey.SetVertexColor then
        hotkey:SetVertexColor(1.0, 1.0, 1.0)
    end

    if isOutOfRange then
        -- Out of Range: Red
        if hotkey.SetTextColor then
            hotkey:SetTextColor(1.0, 0.1, 0.1)
        end
    else
        -- In Range / No Target: User Color Picker color
        local tc = ShortKeybindsDB and ShortKeybindsDB.textColor or { r = 1, g = 0.82, b = 0 }
        local r, g, b = tc.r or 1, tc.g or 0.82, tc.b or 0
        if hotkey.SetTextColor then
            hotkey:SetTextColor(r, g, b)
        end
    end
end

-- Register HookScript on button OnEnter / OnLeave to preserve custom color on mouseover
local function SetupEnterLeaveHooks(button)
    if not button or button._skbEnterLeaveHooked then return end
    button._skbEnterLeaveHooked = true

    if button.HookScript then
        button:HookScript("OnEnter", function(self)
            ns.UpdateUsable(self)
        end)
        button:HookScript("OnLeave", function(self)
            ns.UpdateUsable(self)
        end)
    end
end

-- Update single button hotkey text & formatting (Taint-Safe)
function ns.UpdateHotKey(button)
    if not button then return end

    local name = button:GetName()
    if not name then return end

    local hotkey = _G[name .. "HotKey"] or button.HotKey or button.hotkey
    if not hotkey then return end

    SetupEnterLeaveHooks(button)

    -- Check if disabled by user
    if ShortKeybindsDB and ShortKeybindsDB.enabled == false then
        hotkey:ClearAllPoints()
        hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
        hotkey:SetJustifyH("RIGHT")
        
        local fontPath, _, _ = hotkey:GetFont()
        if fontPath then
            hotkey:SetFont(fontPath, 12, "OUTLINE")
        end
        if hotkey.SetVertexColor then
            hotkey:SetVertexColor(0.6, 0.6, 0.6)
        end
        if hotkey.SetTextColor then
            hotkey:SetTextColor(1, 1, 1)
        end

        local action = ns.GetButtonBindingAction(button)
        if action and GetBindingKey then
            local key1, key2 = GetBindingKey(action)
            local rawKey = key1 or key2
            if rawKey then
                local keyText = (GetBindingText and GetBindingText(rawKey, "KEY_")) or rawKey
                if string.len(keyText) > 5 then
                    keyText = string.sub(keyText, 1, 3) .. "..."
                end
                hotkey:SetText(keyText)
            end
        end
        hotkey:Show()
        return
    end

    if ShortKeybindsDB and ShortKeybindsDB.hideHotkeys then
        hotkey:Hide()
        return
    end

    local action = ns.GetButtonBindingAction(button)
    local rawKey

    if action and GetBindingKey then
        local key1, key2 = GetBindingKey(action)
        rawKey = key1 or key2
    end

    local textToDisplay

    if rawKey then
        local keyText = (GetBindingText and GetBindingText(rawKey, "KEY_")) or rawKey
        textToDisplay = ns.FormatKeyText(keyText)
    else
        local currentText = hotkey:GetText()
        if currentText and currentText ~= "" and currentText ~= (RANGE_INDICATOR or "●") and currentText ~= "●" then
            textToDisplay = ns.FormatKeyText(currentText)
        end
    end

    if textToDisplay and textToDisplay ~= "" then
        hotkey:SetText(textToDisplay)
        if hotkey.SetWidth then hotkey:SetWidth(0) end

        -- Text Justification / Alignment
        local justify = (ShortKeybindsDB and ShortKeybindsDB.justifyText) or "LEFT"
        hotkey:ClearAllPoints()
        if justify == "LEFT" then
            hotkey:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            hotkey:SetJustifyH("LEFT")
        elseif justify == "CENTER" then
            hotkey:SetPoint("TOP", button, "TOP", 0, -2)
            hotkey:SetJustifyH("CENTER")
        else
            hotkey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
            hotkey:SetJustifyH("RIGHT")
        end

        -- Font size auto-scaling
        local baseSize = (ShortKeybindsDB and ShortKeybindsDB.fontSize) or 11
        local len = string.len(textToDisplay)
        local fontPath, _, _ = hotkey:GetFont()

        if ShortKeybindsDB and ShortKeybindsDB.autoScaleFont ~= false then
            if len >= 8 then
                baseSize = math.max(7, baseSize - 3)
            elseif len >= 6 then
                baseSize = math.max(8, baseSize - 2)
            elseif len >= 5 then
                baseSize = math.max(9, baseSize - 1)
            end
        end

        local flags = (ShortKeybindsDB and ShortKeybindsDB.fontFlags) or "OUTLINE"
        if fontPath then
            hotkey:SetFont(fontPath, baseSize, flags)
        end

        -- Apply color (Red if out of range, custom color if in range/no target)
        ns.UpdateUsable(button)

        hotkey:Show()
    end
end

-- Scan and update all usable states across all visible action buttons
function ns:UpdateAllUsableStates()
    local barPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "BonusActionButton",
        "PetActionButton",
        "ShapeshiftButton",
        "StanceButton"
    }

    for _, prefix in ipairs(barPrefixes) do
        for i = 1, 12 do
            local btn = _G[prefix .. i]
            if btn and btn:IsShown() then
                ns.UpdateUsable(btn)
            end
        end
    end
end

-- Scan and update all action buttons across all action bars
function ns:UpdateAllHotKeys()
    local barPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "BonusActionButton",
        "PetActionButton",
        "ShapeshiftButton",
        "StanceButton"
    }

    for _, prefix in ipairs(barPrefixes) do
        for i = 1, 12 do
            local btn = _G[prefix .. i]
            if btn then
                SetupEnterLeaveHooks(btn)
                ns.UpdateHotKey(btn)
            end
        end
    end
end

-- Secure hooks for ActionButton routines
function ns:SetupHooks()
    if ns.hooksDone then return end
    ns.hooksDone = true

    if hooksecurefunc then
        if ActionButton_OnUpdate then
            hooksecurefunc("ActionButton_OnUpdate", ns.UpdateUsable)
        end
        if ActionButton_UpdateHotKey then
            hooksecurefunc("ActionButton_UpdateHotKey", ns.UpdateHotKey)
        end
        if ActionButton_UpdateUsable then
            hooksecurefunc("ActionButton_UpdateUsable", ns.UpdateUsable)
        end
        if ActionButton_UpdateState then
            hooksecurefunc("ActionButton_UpdateState", ns.UpdateUsable)
        end
        if ActionButton_UpdateRangeCheck then
            hooksecurefunc("ActionButton_UpdateRangeCheck", ns.UpdateUsable)
        end
        if PetActionButton_UpdateHotKey then
            hooksecurefunc("PetActionButton_UpdateHotKey", ns.UpdateHotKey)
        end
    end
end

-- 0.15s Real-Time Range & Color Ticker Frame (Captures instant in-range movement transitions)
local tickerFrame = CreateFrame("Frame")
local elapsedSum = 0

tickerFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSum = elapsedSum + elapsed
    if elapsedSum >= 0.15 then
        elapsedSum = 0
        if ShortKeybindsDB and ShortKeybindsDB.enabled ~= false and not ShortKeybindsDB.hideHotkeys then
            ns:UpdateAllUsableStates()
        end
    end
end)

-- Event Listener Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns:InitDB()
        ns:SetupHooks()
        if ns.RegisterOptionsWithBlizzard then
            ns.RegisterOptionsWithBlizzard()
        end
        ns:UpdateAllHotKeys()
        ns:Print("Version 1.0.0 loaded! Type |cff00ffff/skb|r or check Game Menu -> Options -> AddOns.")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BINDINGS" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "PLAYER_TARGET_CHANGED" or event == "ACTIONBAR_UPDATE_USABLE" or event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "MODIFIER_STATE_CHANGED" or event == "ACTIONBAR_SLOT_CHANGED" then
        ns:UpdateAllHotKeys()
    end
end)

-- Slash Commands
SLASH_SHORTKEYBINDS1 = "/skb"
SLASH_SHORTKEYBINDS2 = "/shortkeybinds"
SlashCmdList["SHORTKEYBINDS"] = function(msg)
    local cmd, arg = string.match(msg or "", "^(%S*)%s*(.-)$")
    cmd = string.lower(cmd or "")

    if cmd == "toggle" then
        ShortKeybindsDB.enabled = not ShortKeybindsDB.enabled
        ns:Print("Keybind shortening is now " .. (ShortKeybindsDB.enabled and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r") .. ".")
        ns:UpdateAllHotKeys()
    elseif cmd == "align" or cmd == "justify" then
        local pos = string.upper(arg or "")
        if pos == "LEFT" or pos == "RIGHT" or pos == "CENTER" then
            ShortKeybindsDB.justifyText = pos
            ns:Print("Hotkey text alignment set to |cff00ffff" .. pos .. "|r.")
            ns:UpdateAllHotKeys()
        else
            ns:Print("Usage: /skb align <LEFT|RIGHT|CENTER>")
        end
    elseif cmd == "case" then
        local style = string.upper(arg or "")
        if style == "UPPERCASE" or style == "LOWERCASE" then
            ShortKeybindsDB.modifierCase = style
            ns:Print("Modifier letter case set to |cff00ffff" .. style .. "|r.")
            ns:UpdateAllHotKeys()
        else
            ns:Print("Usage: /skb case <UPPERCASE|LOWERCASE>")
        end
    elseif cmd == "dash" then
        ShortKeybindsDB.showDash = not ShortKeybindsDB.showDash
        ns:Print("Modifier dash separator is now " .. (ShortKeybindsDB.showDash and "|cff00ff00ENABLED (e.g. S-N1)|r" or "|cffff0000DISABLED (e.g. SN1)|r") .. ".")
        ns:UpdateAllHotKeys()
    elseif cmd == "hide" then
        ShortKeybindsDB.hideHotkeys = not ShortKeybindsDB.hideHotkeys
        ns:Print("Hotkey text visibility is now " .. (ShortKeybindsDB.hideHotkeys and "|cffff0000HIDDEN|r" or "|cff00ff00VISIBLE|r") .. ".")
        ns:UpdateAllHotKeys()
    elseif cmd == "font" then
        local size = tonumber(arg)
        if size and size >= 6 and size <= 24 then
            ShortKeybindsDB.fontSize = size
            ns:Print("Hotkey base font size set to |cff00ffff" .. size .. "pt|r.")
            ns:UpdateAllHotKeys()
        else
            ns:Print("Usage: /skb font <6-24>")
        end
    elseif cmd == "reset" then
        ShortKeybindsDB = {}
        ns:InitDB()
        ns:Print("Settings reset to defaults.")
        ns:UpdateAllHotKeys()
    else
        if ns.ToggleOptionsUI then
            ns.ToggleOptionsUI()
        else
            ns:Print("Slash Commands:")
            ns:Print("  /skb - Open Options UI")
            ns:Print("  /skb align <LEFT|RIGHT|CENTER> - Set hotkey text alignment")
            ns:Print("  /skb case <UPPERCASE|LOWERCASE> - Set modifier case format")
            ns:Print("  /skb toggle - Toggle shortening on/off")
            ns:Print("  /skb dash - Toggle dash between modifier and key")
            ns:Print("  /skb hide - Toggle hiding keybind text completely")
            ns:Print("  /skb font <6-24> - Set base hotkey font size")
            ns:Print("  /skb reset - Reset all settings")
        end
    end
end
