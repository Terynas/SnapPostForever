local addonName, ns = ...

ns.Options = ns.Options or {}
local Options = ns.Options

local CATEGORY_NAME = "SnapPost Forever"
local registered = false
local category
local toolsPanel
local valuesPanel
local settingByVar = {}

local function RememberSetting(variable, setting)
    if variable and setting then
        settingByVar[variable] = setting
    end
    return setting
end

local function ClampNumber(value, minV, maxV, step)
    local n = tonumber(value)
    if not n then
        return nil
    end
    if minV and n < minV then
        n = minV
    end
    if maxV and n > maxV then
        n = maxV
    end
    if step and step > 0 then
        local factor = 1 / step
        n = math.floor(n * factor + 0.5) / factor
    end
    return n
end

local function ApplySettingValue(variable, value)
    local setting = settingByVar[variable]
    if setting and setting.SetValue then
        setting:SetValue(value)
        return true
    end
    return false
end

local function FormatSettingNumber(value, step)
    local n = tonumber(value)
    if not n then
        return ""
    end
    if step and step < 1 then
        local text = string.format("%.2f", n):gsub("(%..-)0+$", "%1"):gsub("%.$", "")
        return text
    end
    return tostring(math.floor(n + 0.5))
end

local function SettingsReady()
    return Settings
        and Settings.RegisterVerticalLayoutCategory
        and Settings.RegisterAddOnCategory
        and Settings.RegisterProxySetting
end

local function OpenCategory()
    if not category then
        return false
    end
    if Settings and Settings.OpenToCategory then
        -- Prefer ID (set below); fall back to name.
        if category.ID and Settings.OpenToCategory(category.ID) then
            return true
        end
        return Settings.OpenToCategory(CATEGORY_NAME)
    end
    if InterfaceOptionsFrame_OpenToCategory and toolsPanel then
        InterfaceOptionsFrame_OpenToCategory(toolsPanel)
        InterfaceOptionsFrame_OpenToCategory(toolsPanel)
        return true
    end
    return false
end

function Options:Open()
    if not registered then
        self:Register()
    end
    if OpenCategory() then
        return
    end
    -- Fallback: open the floating mapper.
    if ns.UI then
        ns.UI:ToggleMapper()
    end
end

local function ProxyBool(key, defaultValue)
    return function()
        if ns.db and ns.db.settings and ns.db.settings[key] ~= nil then
            return ns.db.settings[key] and true or false
        end
        return defaultValue and true or false
    end, function(value)
        if ns.db and ns.db.settings then
            ns.db.settings[key] = value and true or false
        end
    end
end

local function ProxyNumber(key, defaultValue)
    return function()
        if ns.db and ns.db.settings and ns.db.settings[key] ~= nil then
            return tonumber(ns.db.settings[key]) or defaultValue
        end
        return defaultValue
    end, function(value)
        if ns.db and ns.db.settings then
            ns.db.settings[key] = tonumber(value) or defaultValue
        end
    end
end

local function BuildToolsPanel()
    if toolsPanel then
        return toolsPanel
    end

    local f = CreateFrame("Frame", "SnapPostForeverOptionsPanel")
    f.name = CATEGORY_NAME
    f:Hide()

    f.OnCommit = function() end
    f.OnDefault = function() end
    f.OnRefresh = function() end

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffc9a227SnapPost Forever|r")

    local ver = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    ver:SetText("v" .. (ns.version or "?") .. "  ·  Options > AddOns > SnapPost Forever")

    local help = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", ver, "BOTTOMLEFT", 0, -14)
    help:SetPoint("RIGHT", -16, 0)
    help:SetJustifyH("LEFT")
    help:SetWordWrap(true)
    help:SetText(
        "Map profession materials to your alts, then mail them from any mailbox."
            .. " Use the settings above for mail behaviour, or open the mapper from here."
    )

    local mapperBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mapperBtn:SetSize(180, 28)
    mapperBtn:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -18)
    mapperBtn:SetText("Open Mapper")
    mapperBtn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
            HideUIPanel(SettingsPanel)
        elseif SettingsPanel and SettingsPanel.Close then
            SettingsPanel:Close()
        end
        if ns.UI then
            if ns.UI.ShowMapper then
                ns.UI:ShowMapper()
            else
                ns.UI:ToggleMapper()
            end
        end
    end)

    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetSize(180, 28)
    scanBtn:SetPoint("LEFT", mapperBtn, "RIGHT", 10, 0)
    scanBtn:SetText("Scan This Character")
    scanBtn:SetScript("OnClick", function()
        if ns.CharDB then
            local key = ns.CharDB:ScanPlayer()
            ns.Print("Scanned %s professions.", key or ns.PlayerKey())
        end
    end)

    local bagsBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    bagsBtn:SetSize(180, 28)
    bagsBtn:SetPoint("TOPLEFT", mapperBtn, "BOTTOMLEFT", 0, -10)
    bagsBtn:SetText("Show Mail Plan")
    bagsBtn:SetScript("OnClick", function()
        if not ns.BagScan or not ns.UI then
            return
        end
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
            HideUIPanel(SettingsPanel)
        end
        local plan = ns.BagScan:BuildPlan()
        ns.UI:ShowMailPrompt(plan)
    end)

    local guideBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    guideBtn:SetSize(180, 28)
    guideBtn:SetPoint("LEFT", bagsBtn, "RIGHT", 10, 0)
    guideBtn:SetText("Show Guide")
    guideBtn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
            HideUIPanel(SettingsPanel)
        end
        if ns.UI and ns.UI.ShowMapper then
            ns.UI:ShowMapper({ noIntro = true })
        end
        if ns.Intro and ns.Intro.Show then
            ns.Intro:Show(true)
        end
    end)

    local cmds = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    cmds:SetPoint("TOPLEFT", bagsBtn, "BOTTOMLEFT", 0, -20)
    cmds:SetPoint("RIGHT", -16, 0)
    cmds:SetJustifyH("LEFT")
    cmds:SetText(
        "Slash: |cffffffff/spostf|r mapper · |cffffffff/spostf options|r ·"
            .. " |cffffffff/spostf minimap|r · |cffffffff/spostf scan|r · |cffffffff/spostf bags|r"
    )

    toolsPanel = f
    return f
end

local function AddValueRow(parent, anchor, labelText, getText, commit, hint)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    if anchor then
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -14)
    else
        label:SetPoint("TOPLEFT", 16, -16)
    end
    label:SetText(labelText)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(72, 22)
    box:SetPoint("LEFT", label, "LEFT", 250, 0)
    box:SetAutoFocus(false)
    box:SetMaxLetters(12)
    box:SetJustifyH("RIGHT")
    box:SetText(getText() or "")

    local hintFs
    if hint then
        hintFs = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hintFs:SetPoint("LEFT", box, "RIGHT", 10, 0)
        hintFs:SetText(hint)
    end

    local function refresh()
        if not box:HasFocus() then
            box:SetText(getText() or "")
        end
    end

    local function apply()
        local ok, err = commit(box:GetText())
        if ok then
            box:SetText(getText() or "")
        elseif err then
            ns.Print("%s", err)
            box:SetText(getText() or "")
        end
        box:ClearFocus()
    end

    box:SetScript("OnEnterPressed", apply)
    box:SetScript("OnEditFocusLost", apply)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(getText() or "")
        self:ClearFocus()
    end)

    return label, box, refresh
end

local function BuildValuesPanel()
    if valuesPanel then
        return valuesPanel
    end

    local f = CreateFrame("Frame", "SnapPostForeverValuesPanel")
    f.name = "Values"
    f:Hide()

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffc9a227Type exact values|r")

    local help = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    help:SetPoint("RIGHT", -16, 0)
    help:SetJustifyH("LEFT")
    help:SetWordWrap(true)
    help:SetText(
        "Type a number and press Enter (or click away)."
            .. " Sliders on the main SnapPost Forever page stay in sync. Out-of-range values are clamped."
    )

    local refreshers = {}
    local anchor = help

    local function row(labelText, getText, commit, hint)
        local label, _, refresh = AddValueRow(f, anchor, labelText, getText, commit, hint)
        refreshers[#refreshers + 1] = refresh
        anchor = label
    end

    row("Send delay (seconds)", function()
        return FormatSettingNumber((ns.db and ns.db.settings and ns.db.settings.sendDelay) or 3, 0.5)
    end, function(text)
        local n = ClampNumber(text, 1, 30, 0.5)
        if not n then
            return false, "Send delay must be a number (1-30)."
        end
        if not ApplySettingValue("SnapPostForever_sendDelay", n) and ns.db and ns.db.settings then
            ns.db.settings.sendDelay = n
        end
        return true
    end, "1 - 30")

    row("Character sidebar icon size", function()
        return FormatSettingNumber((ns.db and ns.db.settings and ns.db.settings.charTabSize) or 28, 1)
    end, function(text)
        local n = ClampNumber(text, 20, 40, 1)
        if not n then
            return false, "Character sidebar icon size must be a number (20-40)."
        end
        n = math.floor(n + 0.5)
        if not ApplySettingValue("SnapPostForever_charTabSize", n) and ns.db and ns.db.settings then
            ns.db.settings.charTabSize = n
            if ns.UI and ns.UI.RescaleCharTabs then
                ns.UI:RescaleCharTabs()
            end
        end
        return true
    end, "24 - 64")

    row("DE greens max level", function()
        local s = ns.db and ns.db.settings and ns.db.settings.deFodder
        return FormatSettingNumber((s and s.maxLevel) or 40, 1)
    end, function(text)
        local n = ClampNumber(text, 1, 60, 1)
        if not n then
            return false, "DE greens max level must be a number (1-60)."
        end
        n = math.floor(n + 0.5)
        if not ApplySettingValue("SnapPostForever_deFodderMaxLevel", n) and ns.db and ns.db.settings then
            ns.db.settings.deFodder = ns.db.settings.deFodder or {}
            ns.db.settings.deFodder.maxLevel = n
        end
        return true
    end, "1 - 60")

    row("DE greens max vendor (gold)", function()
        local s = ns.db and ns.db.settings and ns.db.settings.deFodder
        return FormatSettingNumber((tonumber(s and s.maxVendorCopper) or 50000) / 10000, 0.5)
    end, function(text)
        local n = ClampNumber(text, 0, 20, 0.5)
        if not n then
            return false, "Max vendor gold must be a number (0-20)."
        end
        if not ApplySettingValue("SnapPostForever_deFodderMaxVendorGold", n) and ns.db and ns.db.settings then
            ns.db.settings.deFodder = ns.db.settings.deFodder or {}
            ns.db.settings.deFodder.maxVendorCopper = math.floor(n * 10000 + 0.5)
        end
        return true
    end, "0 - 20")

    row("DE greens max AH (gold)", function()
        local s = ns.db and ns.db.settings and ns.db.settings.deFodder
        return FormatSettingNumber((tonumber(s and s.maxAuctionCopper) or 10000) / 10000, 0.5)
    end, function(text)
        local n = ClampNumber(text, 0, 20, 0.5)
        if not n then
            return false, "Max AH gold must be a number (0-20)."
        end
        if not ApplySettingValue("SnapPostForever_deFodderMaxAuctionGold", n) and ns.db and ns.db.settings then
            ns.db.settings.deFodder = ns.db.settings.deFodder or {}
            ns.db.settings.deFodder.maxAuctionCopper = math.floor(n * 10000 + 0.5)
        end
        return true
    end, "0 - 20")

    local tip = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    tip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
    tip:SetPoint("RIGHT", -16, 0)
    tip:SetJustifyH("LEFT")
    tip:SetWordWrap(true)
    tip:SetText("Tip: you can still use the sliders on SnapPost Forever; this page is for typing exact numbers.")

    f.OnRefresh = function()
        for _, refresh in ipairs(refreshers) do
            refresh()
        end
    end
    f.OnCommit = function() end
    f.OnDefault = function() end

    valuesPanel = f
    return f
end

local function RegisterModern()
    for k in pairs(settingByVar) do
        settingByVar[k] = nil
    end
    category = Settings.RegisterVerticalLayoutCategory(CATEGORY_NAME)
    category.ID = CATEGORY_NAME

    do
        local get = function()
            if ns.MinimapButton then
                return ns.MinimapButton:IsShown()
            end
            if ns.db and ns.db.minimap then
                return not ns.db.minimap.hide
            end
            return true
        end
        local set = function(value)
            if ns.db and ns.db.settings then
                ns.db.settings.showMinimap = value and true or false
            end
            if ns.MinimapButton then
                ns.MinimapButton:SetShown(value and true or false)
            elseif ns.db then
                ns.db.minimap = ns.db.minimap or {}
                ns.db.minimap.hide = not value
            end
        end
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_showMinimap",
            "boolean",
            "Show minimap icon",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(
            category,
            setting,
            "Show the SnapPost Forever letter icon on the minimap."
                .. " Left-click opens the mapper; right-click opens options."
        )
    end

    do
        local get, set = ProxyBool("autoPrompt", true)
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_autoPrompt",
            "boolean",
            "Auto-prompt at mailbox",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(category, setting, "When you open a mailbox, show the SnapPost send list if bags have mapped materials.")
    end

    do
        local get, set = ProxyBool("skipIntro", false)
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_skipIntro",
            "boolean",
            "Skip first-time guide",
            false,
            get,
            set
        )
        Settings.CreateCheckbox(
            category,
            setting,
            "Do not show the first-time how-to when opening the mapper on a character."
                .. " Turn this off and use Tools > Show guide to replay the tour."
        )
    end

    do
        local get, set = ProxyBool("chatMailProgress", true)
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_chatMailProgress",
            "boolean",
            "Chat: mail send progress",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(
            category,
            setting,
            "Print Queuing / Sent to / finished lines in chat while mailing."
                .. " Failures and mailbox-required errors still print when this is off."
        )
    end

    do
        local get, set = ProxyBool("skipSoulbound", true)
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_skipSoulbound",
            "boolean",
            "Skip soulbound items",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(category, setting, "Do not queue soulbound / bound stacks for mailing.")
    end

    do
        local get, set = ProxyBool("onlyMapped", true)
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_onlyMapped",
            "boolean",
            "Only mapped materials",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(category, setting, "Only include catalog materials that resolve to another character.")
    end

    do
        local get, set = ProxyNumber("sendDelay", 3.0)
        local setting = RememberSetting("SnapPostForever_sendDelay", Settings.RegisterProxySetting(
            category,
            "SnapPostForever_sendDelay",
            "number",
            "Send delay (seconds)",
            3.0,
            get,
            set
        ))
        local options = Settings.CreateSliderOptions(1, 30, 0.5)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(category, setting, options, "Pause between each outgoing mail. Type an exact value under Values.")
    end

    do
        local get, set = ProxyNumber("charTabSize", 28)
        local setting = RememberSetting("SnapPostForever_charTabSize", Settings.RegisterProxySetting(
            category,
            "SnapPostForever_charTabSize",
            "number",
            "Character sidebar icon size",
            28,
            get,
            function(value)
                set(value)
                if ns.UI and ns.UI.RescaleCharTabs then
                    ns.UI:RescaleCharTabs()
                end
            end
        ))
        local options = Settings.CreateSliderOptions(20, 40, 2)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(category, setting, options, "Mapper sidebar alt icon size (20-40). Type an exact value under Values.")
    end

    do
        local get = function()
            local s = ns.db and ns.db.settings and ns.db.settings.deFodder
            if s and s.enabled ~= nil then
                return s.enabled and true or false
            end
            return true
        end
        local set = function(value)
            if ns.db and ns.db.settings then
                ns.db.settings.deFodder = ns.db.settings.deFodder or {}
                ns.db.settings.deFodder.enabled = value and true or false
            end
        end
        local setting = Settings.RegisterProxySetting(
            category,
            "SnapPostForever_deFodderEnabled",
            "boolean",
            "Mail low-value greens to enchanter",
            true,
            get,
            set
        )
        Settings.CreateCheckbox(
            category,
            setting,
            "Uncommon armor/weapons under the level/vendor/AH caps go to the DE recipient"
                .. " set in the mapper (DE greens > char). Uses Auctionator prices when available."
        )
    end

    do
        local get = function()
            local s = ns.db and ns.db.settings and ns.db.settings.deFodder
            return tonumber(s and s.maxLevel) or 40
        end
        local set = function(value)
            if ns.db and ns.db.settings then
                ns.db.settings.deFodder = ns.db.settings.deFodder or {}
                ns.db.settings.deFodder.maxLevel = tonumber(value) or 40
            end
        end
        local setting = RememberSetting("SnapPostForever_deFodderMaxLevel", Settings.RegisterProxySetting(
            category,
            "SnapPostForever_deFodderMaxLevel",
            "number",
            "DE greens max level",
            40,
            get,
            set
        ))
        local options = Settings.CreateSliderOptions(1, 60, 1)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(category, setting, options, "Max of item level / required level. Type an exact value under Values.")
    end

    do
        local get = function()
            local s = ns.db and ns.db.settings and ns.db.settings.deFodder
            return (tonumber(s and s.maxVendorCopper) or 50000) / 10000
        end
        local set = function(value)
            if ns.db and ns.db.settings then
                ns.db.settings.deFodder = ns.db.settings.deFodder or {}
                ns.db.settings.deFodder.maxVendorCopper = math.floor((tonumber(value) or 5) * 10000 + 0.5)
            end
        end
        local setting = RememberSetting("SnapPostForever_deFodderMaxVendorGold", Settings.RegisterProxySetting(
            category,
            "SnapPostForever_deFodderMaxVendorGold",
            "number",
            "DE greens max vendor (gold)",
            5,
            get,
            set
        ))
        local options = Settings.CreateSliderOptions(0, 20, 0.5)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(category, setting, options, "Skip greens whose vendor sell price is above this. Type under Values.")
    end

    do
        local get = function()
            local s = ns.db and ns.db.settings and ns.db.settings.deFodder
            return (tonumber(s and s.maxAuctionCopper) or 10000) / 10000
        end
        local set = function(value)
            if ns.db and ns.db.settings then
                ns.db.settings.deFodder = ns.db.settings.deFodder or {}
                ns.db.settings.deFodder.maxAuctionCopper = math.floor((tonumber(value) or 1) * 10000 + 0.5)
            end
        end
        local setting = RememberSetting("SnapPostForever_deFodderMaxAuctionGold", Settings.RegisterProxySetting(
            category,
            "SnapPostForever_deFodderMaxAuctionGold",
            "number",
            "DE greens max AH (gold)",
            1,
            get,
            set
        ))
        local options = Settings.CreateSliderOptions(0, 20, 0.5)
        if options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        end
        Settings.CreateSlider(
            category,
            setting,
            options,
            "If Auctionator AH price is above this, keep for auction instead of DE. Type under Values."
        )
    end

    local values = BuildValuesPanel()
    local valuesSub, valuesLayout = Settings.RegisterCanvasLayoutSubcategory(category, values, "Values")
    valuesSub.ID = CATEGORY_NAME .. " Values"
    if valuesLayout and valuesLayout.AddAnchorPoint then
        valuesLayout:AddAnchorPoint("TOPLEFT", 10, -10)
        valuesLayout:AddAnchorPoint("BOTTOMRIGHT", -10, 10)
    end

    local panel = BuildToolsPanel()
    local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(category, panel, "Tools")
    subcategory.ID = CATEGORY_NAME .. " Tools"
    if layout and layout.AddAnchorPoint then
        layout:AddAnchorPoint("TOPLEFT", 10, -10)
        layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10)
    end

    Settings.RegisterAddOnCategory(category)
    return true
end

local function RegisterLegacy()
    local panel = BuildToolsPanel()
    panel.parent = nil
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        category = { ID = CATEGORY_NAME, name = CATEGORY_NAME }
        return true
    end
    return false
end

function Options:Register()
    if registered or not ns.db then
        return registered
    end
    local ok
    if SettingsReady() then
        local success, err = pcall(RegisterModern)
        if success then
            ok = true
        else
            ns.Print("Settings panel failed (%s); trying legacy options.", tostring(err))
            ok = RegisterLegacy()
        end
    else
        ok = RegisterLegacy()
    end
    registered = ok
    return registered
end

-- Register once saved variables exist.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    -- Core.lua also handles ADDON_LOADED; wait a tick so ns.db is ready.
    C_Timer.After(0, function()
        if ns.db then
            Options:Register()
        end
    end)
end)
