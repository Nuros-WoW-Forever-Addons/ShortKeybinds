-- ============================================================================
-- ShortKeybinds - Graphical Options UI Panel
-- Supports both embedded Blizzard Options & Independent Floating Window
-- ============================================================================

local addonName, ns = ...

local embeddedPanel = nil
local standaloneWindow = nil

-- Helper to safely handle BackdropTemplate
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local function ApplyBackdrop(frame, backdropInfo)
    if BackdropTemplateMixin and not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop(backdropInfo)
    end
end

-- Helper: Open WoW Native ColorPickerFrame
local function OpenColorPicker(r, g, b, callback)
    local info = {
        r = r, g = g, b = b,
        swatchFunc = function()
            local nr, ng, nb
            if ColorPickerFrame.GetColorRGB then
                nr, ng, nb = ColorPickerFrame:GetColorRGB()
            elseif ColorPickerFrame.GetColorRGBs then
                nr, ng, nb = ColorPickerFrame:GetColorRGBs()
            else
                nr, ng, nb = ColorPickerFrame.r, ColorPickerFrame.g, ColorPickerFrame.b
            end
            callback(nr or 1, ng or 1, nb or 0)
        end,
        cancelFunc = function()
            callback(r, g, b)
        end
    }

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        ColorPickerFrame.func = info.swatchFunc
        ColorPickerFrame.cancelFunc = info.cancelFunc
        ColorPickerFrame.r = r
        ColorPickerFrame.g = g
        ColorPickerFrame.b = b
        if ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(r, g, b)
        end
        ColorPickerFrame:Show()
    end
end

local function CreateCheckbox(parent, label, x, y, getter, setter, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)
    
    cb.refresh = function()
        cb:SetChecked(getter())
    end
    cb:SetScript("OnShow", cb.refresh)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        if onChange then onChange() end
    end)
    return cb
end

local registeredContainers = {}

local function RefreshAllOptionsUI()
    ns:UpdateAllHotKeys()
    for _, c in ipairs(registeredContainers) do
        if c and c.refreshControls then
            c.refreshControls()
        end
    end
end
ns.RefreshAllOptionsUI = RefreshAllOptionsUI

local function BuildOptionsControls(f, isStandalone)
    table.insert(registeredContainers, f)

    local topOffset = isStandalone and -45 or -55

    -- Title & Subtitle (only for embedded; standalone has header bar title)
    if not isStandalone then
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
        title:SetText("ShortKeybinds Options")

        local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        subtitle:SetText("Clean, compact keybind display for default Action Bars")
    end

    local startY = topOffset

    -- Checkboxes
    local cbEnable = CreateCheckbox(f, "Enable ShortKeybinds", 16, startY, 
        function() return ShortKeybindsDB and ShortKeybindsDB.enabled ~= false end,
        function(val) ShortKeybindsDB.enabled = val end,
        RefreshAllOptionsUI
    )

    local cbJustify = CreateCheckbox(f, "Left Justify Hotkey Text (TOPLEFT corner)", 16, startY - 28,
        function() return (ShortKeybindsDB and ShortKeybindsDB.justifyText or "LEFT") == "LEFT" end,
        function(val) ShortKeybindsDB.justifyText = val and "LEFT" or "RIGHT" end,
        RefreshAllOptionsUI
    )

    local cbDash = CreateCheckbox(f, "Use Dash in Modifiers (e.g. S-N1 vs SN1)", 16, startY - 56,
        function() return ShortKeybindsDB and ShortKeybindsDB.showDash ~= false end,
        function(val) ShortKeybindsDB.showDash = val end,
        RefreshAllOptionsUI
    )

    local cbCase = CreateCheckbox(f, "UPPERCASE Modifiers (e.g. S-N1 vs s-n1)", 16, startY - 84,
        function() return (ShortKeybindsDB and ShortKeybindsDB.modifierCase or "UPPERCASE") == "UPPERCASE" end,
        function(val) ShortKeybindsDB.modifierCase = val and "UPPERCASE" or "LOWERCASE" end,
        RefreshAllOptionsUI
    )

    local cbScale = CreateCheckbox(f, "Auto-Scale Font for Multi-Modifier Binds", 16, startY - 112,
        function() return ShortKeybindsDB and ShortKeybindsDB.autoScaleFont ~= false end,
        function(val) ShortKeybindsDB.autoScaleFont = val end,
        RefreshAllOptionsUI
    )

    local cbNumpad = CreateCheckbox(f, "Shorten Numpad Keys (Num Pad 1 -> N1)", 16, startY - 140,
        function() return ShortKeybindsDB and ShortKeybindsDB.shortenNumpad ~= false end,
        function(val) ShortKeybindsDB.shortenNumpad = val end,
        RefreshAllOptionsUI
    )

    local cbHide = CreateCheckbox(f, "Hide Keybind Text Completely", 16, startY - 168,
        function() return ShortKeybindsDB and ShortKeybindsDB.hideHotkeys end,
        function(val) ShortKeybindsDB.hideHotkeys = val end,
        RefreshAllOptionsUI
    )

    -- Color Picker Button & Swatch
    local colorLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    colorLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, startY - 200)
    colorLabel:SetText("Hotkey Text Color:")

    local colorSwatch = CreateFrame("Button", nil, f, backdropTemplate)
    colorSwatch:SetSize(22, 22)
    colorSwatch:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    
    ApplyBackdrop(colorSwatch, {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })

    local function UpdateSwatchColor()
        local tc = ShortKeybindsDB and ShortKeybindsDB.textColor or { r = 1, g = 0.82, b = 0 }
        if colorSwatch.SetBackdropColor then
            colorSwatch:SetBackdropColor(tc.r or 1, tc.g or 0.82, tc.b or 0, 1)
        end
    end

    colorSwatch:SetScript("OnClick", function()
        local tc = ShortKeybindsDB and ShortKeybindsDB.textColor or { r = 1, g = 0.82, b = 0 }
        OpenColorPicker(tc.r or 1, tc.g or 0.82, tc.b or 0, function(r, g, b)
            ShortKeybindsDB.textColor = { r = r, g = g, b = b }
            RefreshAllOptionsUI()
        end)
    end)

    -- Base Font Size Controls
    local fontLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, startY - 230)
    fontLabel:SetText("Base Font Size:")

    local fontValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightMed2")
    fontValue:SetPoint("LEFT", fontLabel, "RIGHT", 10, 0)

    local function UpdateFontText()
        fontValue:SetText("|cff00ffff" .. tostring(ShortKeybindsDB and ShortKeybindsDB.fontSize or 11) .. "pt|r")
    end

    local fontMinus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    fontMinus:SetSize(22, 20)
    fontMinus:SetPoint("LEFT", fontValue, "RIGHT", 10, 0)
    fontMinus:SetText("-")
    fontMinus:SetScript("OnClick", function()
        local sz = (ShortKeybindsDB and ShortKeybindsDB.fontSize or 11) - 1
        if sz >= 6 then
            ShortKeybindsDB.fontSize = sz
            RefreshAllOptionsUI()
        end
    end)

    local fontPlus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    fontPlus:SetSize(22, 20)
    fontPlus:SetPoint("LEFT", fontMinus, "RIGHT", 4, 0)
    fontPlus:SetText("+")
    fontPlus:SetScript("OnClick", function()
        local sz = (ShortKeybindsDB and ShortKeybindsDB.fontSize or 11) + 1
        if sz <= 24 then
            ShortKeybindsDB.fontSize = sz
            RefreshAllOptionsUI()
        end
    end)

    -- 'Clear' Key Replacement Label & Input
    local clearLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clearLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, startY - 260)
    clearLabel:SetText("Numpad 'Clear' key text:")

    local clearEdit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    clearEdit:SetSize(60, 20)
    clearEdit:SetPoint("LEFT", clearLabel, "RIGHT", 10, 0)
    clearEdit:SetAutoFocus(false)
    clearEdit:SetText(ShortKeybindsDB and ShortKeybindsDB.clearText or "Clr")
    clearEdit:SetScript("OnTextChanged", function(self)
        local val = self:GetText()
        if val and val ~= "" then
            ShortKeybindsDB.clearText = val
            ns:UpdateAllHotKeys()
            if f.updatePreview then f.updatePreview() end
        end
    end)

    -- Live Preview Section Box
    local previewBox = CreateFrame("Frame", nil, f, backdropTemplate)
    previewBox:SetHeight(85)
    previewBox:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 50)
    previewBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 50)
    
    ApplyBackdrop(previewBox, {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    if previewBox.SetBackdropColor then
        previewBox:SetBackdropColor(0, 0, 0, 0.75)
        previewBox:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
    end

    local prevHeader = previewBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevHeader:SetPoint("TOPLEFT", previewBox, "TOPLEFT", 8, -6)
    prevHeader:SetText("Live Keybind Preview:")

    local prevText = previewBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prevText:SetPoint("TOPLEFT", prevHeader, "BOTTOMLEFT", 0, -4)
    prevText:SetJustifyH("LEFT")

    f.updatePreview = function()
        if ShortKeybindsDB and ShortKeybindsDB.hideHotkeys then
            prevText:SetText("|cffff9900(All hotkey texts are currently hidden)|r")
            return
        end
        if ShortKeybindsDB and ShortKeybindsDB.enabled == false then
            prevText:SetText("|cffff0000(ShortKeybinds is currently DISABLED)|r")
            return
        end
        local sample1 = ns.FormatKeyText("Num Pad 1")
        local sample2 = ns.FormatKeyText("SHIFT-Num Pad 1")
        local sample3 = ns.FormatKeyText("CTRL-Num Pad 1")
        local sample4 = ns.FormatKeyText("ALT-Num Pad 1")
        local sample5 = ns.FormatKeyText("ALT-CTRL-Num Pad 1")
        local sample6 = ns.FormatKeyText("SHIFT-Clear")
        
        local tc = ShortKeybindsDB and ShortKeybindsDB.textColor or { r = 1, g = 0.82, b = 0 }
        local hexColor = string.format("ff%02x%02x%02x", (tc.r or 1)*255, (tc.g or 0.82)*255, (tc.b or 0)*255)

        prevText:SetText(
            "Num Pad 1: |c" .. hexColor .. sample1 .. "|r   |   SHIFT-Num Pad 1: |c" .. hexColor .. sample2 .. "|r\n" ..
            "CTRL-Num Pad 1: |c" .. hexColor .. sample3 .. "|r   |   ALT-Num Pad 1: |c" .. hexColor .. sample4 .. "|r\n" ..
            "ALT-CTRL-Num Pad 1: |c" .. hexColor .. sample5 .. "|r   |   SHIFT-Clear: |c" .. hexColor .. sample6 .. "|r"
        )
    end

    f.refreshControls = function()
        cbEnable.refresh()
        cbJustify.refresh()
        cbDash.refresh()
        cbCase.refresh()
        cbScale.refresh()
        cbNumpad.refresh()
        cbHide.refresh()
        clearEdit:SetText(ShortKeybindsDB and ShortKeybindsDB.clearText or "Clr")
        UpdateSwatchColor()
        UpdateFontText()
        f.updatePreview()
    end

    f:SetScript("OnShow", function()
        f.refreshControls()
    end)

    -- Reset Defaults Button
    local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    resetBtn:SetSize(110, 22)
    resetBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 16)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        ShortKeybindsDB = {}
        ns:InitDB()
        RefreshAllOptionsUI()
        ns:Print("Settings reset to defaults.")
    end)

    -- Pop Out Button or Close Button
    if not isStandalone then
        local btnPopOut = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btnPopOut:SetSize(210, 22)
        btnPopOut:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -16)
        btnPopOut:SetText("Pop Out Independent Window")
        btnPopOut:SetScript("OnClick", function()
            if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
                HideUIPanel(InterfaceOptionsFrame)
            end
            if SettingsPanel and SettingsPanel:IsShown() then
                HideUIPanel(SettingsPanel)
            end
            ns.ShowStandaloneUI()
        end)
    else
        local okayBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        okayBtn:SetSize(80, 22)
        okayBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
        okayBtn:SetText("Close")
        okayBtn:SetScript("OnClick", function()
            f:Hide()
        end)
    end
end

function ns.CreateOptionsUI()
    if embeddedPanel then return embeddedPanel end

    local f = CreateFrame("Frame", "ShortKeybindsOptionsPanel", UIParent)
    f.name = "ShortKeybinds"
    BuildOptionsControls(f, false)

    embeddedPanel = f
    return f
end

function ns.ShowStandaloneUI()
    if not standaloneWindow then
        local f = CreateFrame("Frame", "ShortKeybindsFloatingWindow", UIParent, backdropTemplate)
        f:SetSize(440, 480)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("DIALOG")

        -- Translucent HUD Edit Mode Panel Styling
        ApplyBackdrop(f, {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogFrame-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        if f.SetBackdropColor then
            f:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
            f:SetBackdropBorderColor(0.8, 0.65, 0.2, 0.9)
        end

        -- Header Panel Bar
        local headerBar = f:CreateTexture(nil, "ARTWORK")
        headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
        headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
        headerBar:SetHeight(28)
        if headerBar.SetColorTexture then
            headerBar:SetColorTexture(0.12, 0.12, 0.18, 0.95)
        end

        -- Title Header Text
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
        title:SetPoint("LEFT", headerBar, "LEFT", 10, 0)
        title:SetText("|cff33ff99ShortKeybinds|r  |cffffd100Options|r")

        -- Close Button (X)
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("RIGHT", headerBar, "RIGHT", -2, 0)
        closeBtn:SetScript("OnClick", function()
            f:Hide()
        end)

        table.insert(UISpecialFrames, "ShortKeybindsFloatingWindow")

        BuildOptionsControls(f, true)
        standaloneWindow = f
    end

    if not standaloneWindow:IsShown() then
        standaloneWindow:Show()
    end
end

-- Register panel into Game Menu -> Options -> AddOns tab across all client versions
function ns.RegisterOptionsWithBlizzard()
    local panel = ns.CreateOptionsUI()

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ShortKeybinds")
        Settings.RegisterAddOnCategory(category)
        panel.categoryID = category:GetID()
    end
end

function ns.ToggleOptionsUI()
    if standaloneWindow and standaloneWindow:IsShown() then
        standaloneWindow:Hide()
    else
        ns.ShowStandaloneUI()
    end
end
