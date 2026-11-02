local _, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI

local mapperFrame
local mailFrame
local mapperRows = {}
local charTabs = {}
local profChips = {}
local selectedProf = "Herbalism"
local selectedExpansion = "Classic"
local selectedMapChar = nil -- charKey for profession / expansion-prof mapping
local materialSearch = ""
local showAllMaterials = false
local showSharedOnly = false

-- Bump to force-rebuild the mapper frame after layout changes (/reload).
local MAPPER_LAYOUT = 42
local MAIL_LAYOUT = 3
local HEADER_H = 64
local PAD = 16
local SIDEBAR_W = 168
local FOOTER_H = 40
-- Character sidebar row icon size (Options: Character sidebar icon size).
local TAB_SIZE_DEFAULT = 28
local TAB_SIZE_MIN = 20
local TAB_SIZE_MAX = 40
local SIDEBAR_ROW_H = 36
local SIDEBAR_GAP = 4
local CHIP_W, CHIP_H, CHIP_GAP = 132, 36, 8

-- Charcoal fill only — chrome uses native Blizzard gold dialog/tooltip borders.
local PANEL_STONE = "Interface\\AddOns\\SnapPostForever\\Media\\panel-stone"

local CLASS_ICON_PATH = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local CLASS_CIRCLE_PATH = "Interface\\TargetingFrame\\UI-Classes-Circles"

local PROF_ICONS = {
    Alchemy = "Interface\\Icons\\Trade_Alchemy",
    Blacksmithing = "Interface\\Icons\\Trade_BlackSmithing",
    Enchanting = "Interface\\Icons\\Trade_Engraving",
    Engineering = "Interface\\Icons\\Trade_Engineering",
    Herbalism = "Interface\\Icons\\Trade_Herbalism",
    Inscription = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    Jewelcrafting = "Interface\\Icons\\INV_Misc_Gem_01",
    Leatherworking = "Interface\\Icons\\Trade_LeatherWorking",
    Mining = "Interface\\Icons\\Trade_Mining",
    Skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    Tailoring = "Interface\\Icons\\Trade_Tailoring",
    Cooking = "Interface\\Icons\\INV_Misc_Food_15",
    Fishing = "Interface\\Icons\\Trade_Fishing",
    ["First Aid"] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
}

-- Outer window: charcoal stone + classic WoW gold dialog border.
local WINDOW_BACKDROP = {
    bgFile = PANEL_STONE,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
-- Inner panels: same stone + thin gold tooltip rails.
local INSET_BACKDROP = {
    bgFile = PANEL_STONE,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local CHIP_BACKDROP = {
    bgFile = PANEL_STONE,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 64,
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local THEME = {
    window = { 1, 1, 1, 1 }, -- stone texture carries color
    border = { 1, 0.82, 0, 1 }, -- Blizzard gold
    inset = { 1, 1, 1, 1 },
    insetBorder = { 0.85, 0.70, 0.20, 1 },
    row = { 1, 1, 1, 0.95 },
    rowBorder = { 0.70, 0.58, 0.18, 0.75 },
    title = { 1, 0.82, 0 },
    subtitle = { 0.85, 0.82, 0.75 },
    parchment = { 0.93, 0.87, 0.72 },
    gold = { 0.95, 0.75, 0.25 },
}

local WHITE = "Interface\\Buttons\\WHITE8X8"

--- Thin horizontal gold rule (Shorts header divider) — plain lines, no frame art.
local function GoldRule(parent, alpha)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(WHITE)
    t:SetVertexColor(THEME.gold[1], THEME.gold[2], THEME.gold[3], alpha or 0.55)
    t:SetHeight(1)
    return t
end

--- Gold-rimmed square behind an icon (item / class / profession).
local function IconFrame(parent, size)
    local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    holder:SetSize(size + 6, size + 6)
    holder:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    holder:SetBackdropColor(0, 0, 0, 0.85)
    holder:SetBackdropBorderColor(THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.9)
    local tex = holder:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 3, -3)
    tex:SetPoint("BOTTOMRIGHT", -3, 3)
    holder.tex = tex
    return holder, tex
end

local function ApplyWindow(frame)
    frame:SetBackdrop(WINDOW_BACKDROP)
    frame:SetBackdropColor(THEME.window[1], THEME.window[2], THEME.window[3], THEME.window[4])
    frame:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])
end

-- Shared by Intro.lua and other chrome.
function UI.ApplyWindowChrome(frame)
    ApplyWindow(frame)
end

local function ApplyInset(frame, r, g, b, a)
    frame:SetBackdrop(INSET_BACKDROP)
    frame:SetBackdropColor(r or THEME.inset[1], g or THEME.inset[2], b or THEME.inset[3], a or THEME.inset[4])
    frame:SetBackdropBorderColor(
        THEME.insetBorder[1],
        THEME.insetBorder[2],
        THEME.insetBorder[3],
        THEME.insetBorder[4]
    )
end

local function ResetMapperFrame()
    if mapperFrame then
        mapperFrame:Hide()
        mapperFrame:SetParent(nil)
        mapperFrame = nil
    end
    wipe(charTabs)
    wipe(mapperRows)
    wipe(profChips)
end

local function ExpansionOptions()
    local opts = {}
    for _, e in ipairs(ns.Expansions) do
        opts[#opts + 1] = { value = e.key, text = e.label }
    end
    return opts
end

local function ProfessionOptionsForChar(charKey)
    local opts = {}
    local info = charKey and ns.CharDB:Get(charKey)
    local known = info and info.professions
    if known and next(known) then
        for _, p in ipairs(ns.Professions) do
            if known[p.key] then
                opts[#opts + 1] = { value = p.key, text = p.label }
            end
        end
    end
    -- No learned crafts yet (or not scanned): still offer the full list so
    -- expansion/profession material browsing does not hard-crash on nil.
    if #opts == 0 then
        for _, p in ipairs(ns.Professions or {}) do
            opts[#opts + 1] = { value = p.key, text = p.label }
        end
    end
    return opts
end

local function ClampSelectedProfession(charKey)
    local opts = ProfessionOptionsForChar(charKey)
    if #opts == 0 then
        selectedProf = nil
        return
    end
    for _, o in ipairs(opts) do
        if o.value == selectedProf then
            return
        end
    end
    selectedProf = opts[1].value
end

local function ShortCharName(key, info)
    if info and info.name and info.name ~= "" then
        return info.name
    end
    if type(key) == "string" then
        local bare = key:match("^(.-)%-") or key
        return bare
    end
    return "?"
end

local function ClassFileOf(info)
    return info and info.class and string.upper(tostring(info.class)) or nil
end

local function ClassRGB(classFile)
    local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local c = classFile and colors and colors[classFile]
    if c then
        return c.r or 0.8, c.g or 0.8, c.b or 0.8
    end
    return 0.75, 0.75, 0.75
end

local function LocalizedClassName(classFile)
    if not classFile then
        return "?"
    end
    if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile] then
        return LOCALIZED_CLASS_NAMES_MALE[classFile]
    end
    return classFile:sub(1, 1) .. string.lower(classFile:sub(2))
end

--- "Lunara (Druid)" in class color (marketing-style destination label).
local function DestLabel(charKey, info)
    local name = ShortCharName(charKey, info)
    local classFile = ClassFileOf(info)
    local className = LocalizedClassName(classFile)
    local r, g, b = ClassRGB(classFile)
    return string.format(
        "|cff%02x%02x%02x%s (%s)|r",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5),
        name,
        className
    )
end

local function SetClassIcon(texture, classFile, circular)
    if not texture then
        return
    end
    classFile = classFile and string.upper(tostring(classFile or ""))
    local coords = CLASS_ICON_TCOORDS and classFile ~= "" and CLASS_ICON_TCOORDS[classFile]
    if coords then
        texture:SetTexture(circular and CLASS_CIRCLE_PATH or CLASS_ICON_PATH)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    texture:Show()
end

local function MaterialItemIcon(itemId)
    if not itemId or itemId <= 0 then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemId)
        if icon then
            return icon
        end
    end
    if GetItemIcon then
        local icon = GetItemIcon(itemId)
        if icon then
            return icon
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CharTabSize()
    local n = ns.db and ns.db.settings and tonumber(ns.db.settings.charTabSize)
    if not n then
        n = TAB_SIZE_DEFAULT
    end
    n = math.floor(n + 0.5)
    if n < TAB_SIZE_MIN then
        n = TAB_SIZE_MIN
    elseif n > TAB_SIZE_MAX then
        n = TAB_SIZE_MAX
    end
    return n
end

local function ApplyCharTabMetrics(tab)
    if not tab then
        return
    end
    local size = CharTabSize()
    tab:SetHeight(math.max(SIDEBAR_ROW_H, size + 12))
    if tab.iconFrame then
        tab.iconFrame:SetSize(size + 6, size + 6)
    end
end

local function SetCharTabIcon(tab, classFile)
    if not tab or not tab.icon then
        return
    end
    SetClassIcon(tab.icon, classFile, false)
end

local function SummarizeMapsForChar(charKey)
    if not charKey or not ns.db or not ns.db.maps then
        return {}, 0, false
    end
    local profs = {}
    for prof, dest in pairs(ns.db.maps.byProfession or {}) do
        if dest == charKey then
            profs[#profs + 1] = prof
        end
    end
    table.sort(profs)
    local itemCount = 0
    for _, dest in pairs(ns.db.maps.byItem or {}) do
        if dest == charKey then
            itemCount = itemCount + 1
        end
    end
    local isDE = ns.Mapper:GetDEFodderChar() == charKey
    return profs, itemCount, isDE
end

local function SelectMapChar(charKey)
    selectedMapChar = charKey
    if mapperFrame then
        UI:RefreshMapper()
    end
end

local function EnsureMapper()
    if mapperFrame and mapperFrame.layoutVersion ~= MAPPER_LAYOUT then
        ResetMapperFrame()
    end
    if mapperFrame then
        return mapperFrame
    end

    local f = CreateFrame("Frame", "SnapPostForeverMapperFrame", UIParent, "BackdropTemplate")
    f.layoutVersion = MAPPER_LAYOUT
    f:SetSize(820, 650)
    f:SetPoint("CENTER")
    ApplyWindow(f)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        ns.Dropdown.CloseAll()
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    tinsert(UISpecialFrames, "SnapPostForeverMapperFrame")

    local host = f
    local hostPad = PAD

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    if _G.GameFontNormalHuge then
        title:SetFontObject(_G.GameFontNormalHuge)
    end
    title:SetPoint("TOP", host, "TOP", 0, -16)
    title:SetText("SnapPost Forever Mapper")
    title:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(1, -1)
    f.titleText = title

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetWidth(420)
    subtitle:SetJustifyH("CENTER")
    subtitle:SetTextColor(THEME.parchment[1], THEME.parchment[2], THEME.parchment[3])
    subtitle:SetText("Map reagents and materials to your alts.\nSnapPost will always send them to the right place.")
    f.subtitleText = subtitle

    f.headerRule = GoldRule(f, 0.6)
    f.headerRule:SetPoint("TOPLEFT", host, "TOPLEFT", 60, -(HEADER_H + 2))
    f.headerRule:SetPoint("TOPRIGHT", host, "TOPRIGHT", -60, -(HEADER_H + 2))

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetFrameLevel(f:GetFrameLevel() + 20)
    close:SetScript("OnClick", function()
        ns.Dropdown.CloseAll()
        f:Hide()
    end)

    -- Left alt sidebar + main pane (inside custom frame opening).
    f.sidebar = CreateFrame("Frame", nil, host, "BackdropTemplate")
    f.sidebar:SetPoint("TOPLEFT", hostPad, -(HEADER_H + 10))
    f.sidebar:SetPoint("BOTTOMLEFT", hostPad, hostPad + FOOTER_H)
    f.sidebar:SetWidth(SIDEBAR_W)
    ApplyInset(f.sidebar)

    f.sidebarScroll = CreateFrame("ScrollFrame", "SnapPostForeverCharSidebarScroll", f.sidebar, "UIPanelScrollFrameTemplate")
    f.sidebarScroll:SetPoint("TOPLEFT", 6, -8)
    f.sidebarScroll:SetPoint("BOTTOMRIGHT", -28, 10)
    f.sidebarContent = CreateFrame("Frame", nil, f.sidebarScroll)
    f.sidebarContent:SetSize(SIDEBAR_W - 40, 1)
    f.sidebarScroll:SetScrollChild(f.sidebarContent)

    -- Main pane well (professions + materials).
    f.mainWell = CreateFrame("Frame", nil, host, "BackdropTemplate")
    f.mainWell:SetPoint("TOPLEFT", f.sidebar, "TOPRIGHT", 10, 0)
    f.mainWell:SetPoint("BOTTOMRIGHT", -hostPad, hostPad + FOOTER_H)
    ApplyInset(f.mainWell)

    f.main = CreateFrame("Frame", nil, f.mainWell)
    f.main:SetPoint("TOPLEFT", 10, -10)
    f.main:SetPoint("BOTTOMRIGHT", -10, 10)

    f.profSectionLabel = f.main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.profSectionLabel:SetPoint("TOPLEFT", 0, 0)
    f.profSectionLabel:SetText("Professions")
    f.profSectionLabel:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])

    f.charDetail = f.main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.charDetail:SetPoint("TOPLEFT", f.profSectionLabel, "BOTTOMLEFT", 0, -2)
    f.charDetail:SetPoint("RIGHT", 0, 0)
    f.charDetail:SetJustifyH("LEFT")
    f.charDetail:SetWordWrap(false)
    f.charDetail:SetTextColor(THEME.subtitle[1], THEME.subtitle[2], THEME.subtitle[3])
    f.charDetail:SetText("Select an alt, then Scan on that character.")

    f.chipHost = CreateFrame("Frame", nil, f.main)
    f.chipHost:SetPoint("TOPLEFT", f.charDetail, "BOTTOMLEFT", 0, -8)
    f.chipHost:SetPoint("TOPRIGHT", f.main, "TOPRIGHT", 0, -40)
    f.chipHost:SetHeight(84)
    -- Compat alias used by older chip helpers.
    f.charPanel = { chipHost = f.chipHost, title = f.charDetail, detail = f.charDetail, icon = nil }

    f.matsLabel = f.main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.matsLabel:SetPoint("TOPLEFT", f.chipHost, "BOTTOMLEFT", 0, -10)
    f.matsLabel:SetText("Mapped Materials")
    f.matsLabel:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])

    f.matsRule = GoldRule(f.main, 0.35)
    f.matsRule:SetPoint("LEFT", f.matsLabel, "RIGHT", 8, 0)
    f.matsRule:SetPoint("RIGHT", f.main, "RIGHT", 0, 0)

    f.searchBox = CreateFrame("EditBox", "SnapPostForeverMaterialSearch", f.main, "InputBoxTemplate")
    f.searchBox:SetSize(180, 22)
    f.searchBox:SetPoint("TOPLEFT", f.matsLabel, "BOTTOMLEFT", 6, -8)
    f.searchBox:SetAutoFocus(false)
    f.searchBox:SetMaxLetters(64)
    f.searchBox:SetText(materialSearch)
    f.searchBox:SetTextInsets(0, 18, 0, 0)

    f.searchHint = f.searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.searchHint:SetPoint("LEFT", 2, 0)
    f.searchHint:SetText("Search materials...")

    local function SyncSearchHint()
        local empty = (f.searchBox:GetText() or "") == ""
        f.searchHint:SetShown(empty and not f.searchBox:HasFocus())
        f.searchClear:SetShown(not empty)
    end

    local function ClearSearch()
        materialSearch = ""
        f.searchBox:SetText("")
        f.searchBox:ClearFocus()
        SyncSearchHint()
        UI:RefreshMapper()
    end

    f.searchClear = CreateFrame("Button", nil, f.searchBox)
    f.searchClear:SetSize(16, 16)
    f.searchClear:SetPoint("RIGHT", -2, 0)
    f.searchClear.label = f.searchClear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.searchClear.label:SetPoint("CENTER")
    f.searchClear.label:SetText("x")
    f.searchClear:SetScript("OnClick", ClearSearch)
    f.searchClear:SetScript("OnEnter", function(self)
        self.label:SetTextColor(1, 1, 1)
    end)
    f.searchClear:SetScript("OnLeave", function(self)
        self.label:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])
    end)

    f.searchBox:SetScript("OnTextChanged", function(self)
        SyncSearchHint()
        local text = self:GetText() or ""
        if text == materialSearch then
            return
        end
        materialSearch = text
        UI:RefreshMapper()
    end)
    f.searchBox:SetScript("OnEditFocusGained", SyncSearchHint)
    f.searchBox:SetScript("OnEditFocusLost", SyncSearchHint)
    f.searchBox:SetScript("OnEscapePressed", function(self)
        if (self:GetText() or "") ~= "" then
            ClearSearch()
        else
            self:ClearFocus()
        end
    end)
    f.searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    SyncSearchHint()

    f.expDrop = ns.Dropdown.Create(f.main, 170, {
        getSelected = function()
            return selectedExpansion, ns.ExpansionLabel[selectedExpansion] or selectedExpansion
        end,
        onSelect = function(value)
            selectedExpansion = value
            UI:RefreshMapper()
        end,
    })
    f.expDrop:SetPoint("LEFT", f.searchBox, "RIGHT", 12, 0)

    -- Hidden profession dropdown kept for RefreshMapper SetOptions/Refresh calls.
    f.profDrop = ns.Dropdown.Create(f.main, 1, {
        getSelected = function()
            if not selectedProf or selectedProf == "" then
                return nil, "—"
            end
            return selectedProf, selectedProf
        end,
        onSelect = function(value)
            selectedProf = value
            showAllMaterials = false
            UI:RefreshMapper()
        end,
    })
    f.profDrop:Hide()

    f.scopeAllBtn = CreateFrame("Button", nil, f.main, "UIPanelButtonTemplate")
    f.scopeAllBtn:SetSize(96, 22)
    f.scopeAllBtn:SetPoint("LEFT", f.expDrop, "RIGHT", 8, 0)
    f.scopeAllBtn:SetText("All mats")
    f.scopeAllBtn:SetScript("OnClick", function()
        showAllMaterials = not showAllMaterials
        showSharedOnly = false
        UI:RefreshMapper()
    end)
    f.scopeAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("All mats", 1, 0.82, 0)
        GameTooltip:AddLine("Every profession's mats for the selected expansion.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("Searching looks across all expansions.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    f.scopeAllBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    f.sharedBtn = CreateFrame("Button", nil, f.main, "UIPanelButtonTemplate")
    f.sharedBtn:SetSize(76, 22)
    f.sharedBtn:SetPoint("LEFT", f.scopeAllBtn, "RIGHT", 6, 0)
    f.sharedBtn:SetText("Shared")
    f.sharedBtn:SetScript("OnClick", function()
        showSharedOnly = not showSharedOnly
        showAllMaterials = false
        UI:RefreshMapper()
    end)
    f.sharedBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Shared mats", 1, 0.82, 0)
        GameTooltip:AddLine(
            "Mats used by more than one profession in the selected expansion, for the focused profession chip.",
            0.8, 0.8, 0.8, true
        )
        GameTooltip:Show()
    end)
    f.sharedBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Compat stubs for old radio refresh paths.
    f.radioProf = nil
    f.radioAll = nil

    f.mapDEBtn = CreateFrame("Button", nil, f.main, "UIPanelButtonTemplate")
    f.mapDEBtn:SetSize(90, 20)
    f.mapDEBtn:SetPoint("TOPLEFT", f.searchBox, "BOTTOMLEFT", -4, -8)
    f.mapDEBtn:SetText("DE greens")
    f.mapDEBtn:SetScript("OnClick", function()
        local me = ns.PlayerKey()
        local ok, owner = ns.Mapper:SetDEFodderChar(me)
        if not ok then
            ns.Mapper:ExplainDenied(owner)
            return
        end
        ns.Print("Low-value green gear -> %s", me)
        UI:RefreshMapper()
    end)

    f.clearDEBtn = CreateFrame("Button", nil, f.main, "UIPanelButtonTemplate")
    f.clearDEBtn:SetSize(76, 20)
    f.clearDEBtn:SetPoint("LEFT", f.mapDEBtn, "RIGHT", 6, 0)
    f.clearDEBtn:SetText("Clear DE")
    f.clearDEBtn:SetScript("OnClick", function()
        local ok, owner = ns.Mapper:SetDEFodderChar(nil)
        if not ok then
            ns.Mapper:ExplainDenied(owner)
            return
        end
        ns.Print("Cleared green DE fodder recipient.")
        UI:RefreshMapper()
    end)

    f.mapStatus = f.main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.mapStatus:SetPoint("LEFT", f.clearDEBtn, "RIGHT", 10, 0)
    f.mapStatus:SetPoint("RIGHT", 0, 0)
    f.mapStatus:SetJustifyH("LEFT")
    f.mapStatus:SetWordWrap(false)

    f.listCount = f.main:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.listCount:SetPoint("TOPLEFT", f.mapDEBtn, "BOTTOMLEFT", 0, -6)
    f.listCount:SetPoint("RIGHT", 0, 0)
    f.listCount:SetJustifyH("LEFT")
    f.listCount:SetWordWrap(false)

    f.scroll = CreateFrame("ScrollFrame", "SnapPostForeverMapperScroll", f.main, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", f.listCount, "BOTTOMLEFT", 4, -8)
    f.scroll:SetPoint("BOTTOMRIGHT", f.main, "BOTTOMRIGHT", -22, 0)

    f.listWell = CreateFrame("Frame", nil, f.main, "BackdropTemplate")
    f.listWell:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", -6, 6)
    f.listWell:SetPoint("BOTTOMRIGHT", f.scroll, "BOTTOMRIGHT", 24, -6)
    ApplyInset(f.listWell)
    f.listWell:SetFrameLevel(f.main:GetFrameLevel() + 1)
    f.scroll:SetFrameLevel(f.listWell:GetFrameLevel() + 2)

    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(520, 1)
    f.scroll:SetScrollChild(f.content)

    -- Footer: Claim My Profs | N mapped | Scan
    f.autoMapBtn = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    f.autoMapBtn:SetSize(140, 26)
    f.autoMapBtn:SetPoint("BOTTOMLEFT", hostPad, 8)
    f.autoMapBtn:SetText("Claim My Profs")
    f.autoMapBtn:SetScript("OnClick", function()
        local mapped = ns.Mapper:AutoMapOwnProfessions()
        ns.Print("Claimed %d unmapped profession(s) for %s.", mapped, ns.PlayerKey())
        UI:RefreshMapper()
    end)

    f.footerCount = host:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.footerCount:SetPoint("BOTTOM", 0, 14)
    f.footerCount:SetText("0 materials mapped")

    f.scanBtn = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    f.scanBtn:SetSize(120, 26)
    f.scanBtn:SetPoint("BOTTOMRIGHT", -hostPad, 8)
    f.scanBtn:SetText("Scan")
    f.scanBtn:SetScript("OnClick", function()
        local key = ns.CharDB:ScanPlayer()
        SelectMapChar(key)
        ns.Print("Professions saved for %s", key or ns.PlayerKey())
    end)

    mapperFrame = f
    return f
end

function UI:AssignItemToSelected(itemId)
    if not ns.Mapper:CanEditChar(selectedMapChar) then
        ns.Mapper:ExplainDenied(selectedMapChar)
        return
    end
    local ok, owner = ns.Mapper:SetItemMap(itemId, selectedMapChar)
    if not ok then
        ns.Mapper:ExplainDenied(owner)
        return
    end
    self:RefreshMapper()
end

--- Right-click: clear an item-specific map (profession auto-maps are unchanged).
function UI:UnmapItem(itemId)
    local current = ns.Mapper:GetItemMap(itemId)
    if current then
        local ok, owner = ns.Mapper:SetItemMap(itemId, nil)
        if not ok then
            ns.Mapper:ExplainDenied(owner)
            return
        end
        ns.Print("Unmapped item from %s.", ShortCharName(current, ns.CharDB:Get(current)))
    else
        local entry = ns.MaterialById and ns.MaterialById[itemId]
        local resolved = entry and ns.Mapper:ResolveRecipient(entry)
        if resolved then
            ns.Print("No item override — still auto-mapped via profession. Toggle the profession chip to clear.")
        else
            ns.Print("Item is not mapped.")
        end
    end
    self:RefreshMapper()
end

local function GetCharTab(i)
    local tab = charTabs[i]
    if tab then
        return tab
    end

    local parent = mapperFrame.sidebarContent or mapperFrame
    tab = CreateFrame("Button", "SnapPostForeverCharTab" .. i, parent, "BackdropTemplate")
    tab:EnableMouse(true)
    tab:RegisterForClicks("AnyUp")
    tab:SetBackdrop(CHIP_BACKDROP)
    tab:SetBackdropColor(0.55, 0.52, 0.48, 1)
    tab:SetBackdropBorderColor(THEME.insetBorder[1], THEME.insetBorder[2], THEME.insetBorder[3], 0.8)
    tab:SetWidth((SIDEBAR_W - 40))

    tab.iconFrame, tab.icon = IconFrame(tab, TAB_SIZE_DEFAULT)
    tab.iconFrame:SetPoint("LEFT", 4, 0)

    tab.name = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tab.name:SetPoint("LEFT", tab.iconFrame, "RIGHT", 6, 0)
    tab.name:SetPoint("RIGHT", -6, 0)
    tab.name:SetJustifyH("LEFT")
    tab.name:SetWordWrap(false)

    tab.selectFill = tab:CreateTexture(nil, "BORDER")
    tab.selectFill:SetTexture(WHITE)
    tab.selectFill:SetVertexColor(0.16, 0.45, 0.95, 0.55)
    tab.selectFill:SetPoint("TOPLEFT", 3, -3)
    tab.selectFill:SetPoint("BOTTOMRIGHT", -3, 3)
    tab.selectFill:Hide()

    tab.selectedGlow = tab:CreateTexture(nil, "OVERLAY")
    tab.selectedGlow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    tab.selectedGlow:SetBlendMode("ADD")
    tab.selectedGlow:SetAllPoints()
    tab.selectedGlow:SetAlpha(0.45)
    tab.selectedGlow:Hide()

    tab.highlight = tab:CreateTexture(nil, "HIGHLIGHT")
    tab.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    tab.highlight:SetBlendMode("ADD")
    tab.highlight:SetAllPoints()

    ApplyCharTabMetrics(tab)
    charTabs[i] = tab
    return tab
end

local function GetProfChip(i)
    local chip = profChips[i]
    if chip then
        return chip
    end
    local host = mapperFrame.chipHost or (mapperFrame.charPanel and mapperFrame.charPanel.chipHost)
    -- Shorts-style wide chip: icon left, label right; focused chip glows gold.
    chip = CreateFrame("Button", nil, host, "BackdropTemplate")
    chip:SetSize(CHIP_W, CHIP_H)
    chip:SetBackdrop(CHIP_BACKDROP)

    chip.fill = chip:CreateTexture(nil, "BORDER")
    chip.fill:SetTexture(WHITE)
    chip.fill:SetPoint("TOPLEFT", 2, -2)
    chip.fill:SetPoint("BOTTOMRIGHT", -2, 2)
    chip.fill:Hide()

    chip.glow = chip:CreateTexture(nil, "OVERLAY")
    chip.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    chip.glow:SetBlendMode("ADD")
    chip.glow:SetVertexColor(1, 0.80, 0.25, 0.9)
    chip.glow:SetPoint("TOPLEFT", -4, 4)
    chip.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    chip.glow:Hide()

    chip.iconFrame, chip.icon = IconFrame(chip, CHIP_H - 14)
    chip.iconFrame:SetPoint("LEFT", 4, 0)
    chip.text = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    chip.text:SetPoint("LEFT", chip.iconFrame, "RIGHT", 6, 0)
    chip.text:SetPoint("RIGHT", -8, 0)
    chip.text:SetJustifyH("LEFT")
    chip.text:SetWordWrap(false)

    chip.mark = chip:CreateTexture(nil, "OVERLAY")
    chip.mark:SetTexture(WHITE)
    chip.mark:SetSize(6, 6)
    chip.mark:SetPoint("TOPRIGHT", -5, -5)
    chip.mark:SetVertexColor(0.35, 0.95, 0.40, 1)
    chip.mark:Hide()

    chip.prio = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.prio:SetPoint("BOTTOMRIGHT", -5, 3)
    chip.prio:Hide()
    chip:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    chip.highlight = chip:CreateTexture(nil, "HIGHLIGHT")
    chip.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    chip.highlight:SetBlendMode("ADD")
    chip.highlight:SetPoint("TOPLEFT", 3, -3)
    chip.highlight:SetPoint("BOTTOMRIGHT", -3, 3)
    profChips[i] = chip
    return chip
end

local function RefreshCharTabsAndPanel(f)
    local chars = ns.CharDB:List()
    -- Ensure the logged-in character exists so the mapper is never empty after /reload.
    if #chars == 0 and ns.db then
        local key = ns.CharDB:ScanPlayer()
        if key then
            chars = ns.CharDB:List()
        end
    end

    if #chars == 0 then
        selectedMapChar = nil
    elseif not selectedMapChar then
        local me = ns.PlayerKey()
        local found
        for _, c in ipairs(chars) do
            if c.key == me then
                found = me
                break
            end
        end
        selectedMapChar = found or chars[1].key
    else
        local still = false
        for _, c in ipairs(chars) do
            if c.key == selectedMapChar then
                still = true
                break
            end
        end
        if not still then
            selectedMapChar = chars[1].key
        end
    end

    local y = 0
    local rowH = math.max(SIDEBAR_ROW_H, CharTabSize() + 12)
    for i = 1, math.max(#chars, #charTabs) do
        local tab = GetCharTab(i)
        local c = chars[i]
        if c then
            local selected = c.key == selectedMapChar
            ApplyCharTabMetrics(tab)
            SetCharTabIcon(tab, c.info and c.info.class)
            local classFile = ClassFileOf(c.info)
            local r, g, b = ClassRGB(classFile)
            if tab.name then
                tab.name:SetText(ShortCharName(c.key, c.info))
                tab.name:SetTextColor(r, g, b)
            end
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", f.sidebarContent, "TOPLEFT", 0, -y)
            tab:SetPoint("TOPRIGHT", f.sidebarContent, "TOPRIGHT", 0, -y)
            y = y + rowH + SIDEBAR_GAP

            if selected then
                tab:SetBackdropColor(1, 1, 1, 1)
                tab:SetBackdropBorderColor(0.55, 0.80, 1.0, 1)
                tab.selectFill:Show()
                if tab.selectedGlow then
                    tab.selectedGlow:Show()
                end
            else
                tab:SetBackdropColor(0.55, 0.52, 0.48, 1)
                tab:SetBackdropBorderColor(THEME.insetBorder[1], THEME.insetBorder[2], THEME.insetBorder[3], 0.8)
                tab.selectFill:Hide()
                if tab.selectedGlow then
                    tab.selectedGlow:Hide()
                end
            end
            tab:SetScript("OnClick", function()
                SelectMapChar(c.key)
            end)
            tab:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(ShortCharName(c.key, c.info), r, g, b)
                GameTooltip:AddLine(c.key, 0.65, 0.65, 0.65)
                local profs = {}
                for pk in pairs((c.info and c.info.professions) or {}) do
                    profs[#profs + 1] = pk
                end
                table.sort(profs)
                if #profs > 0 then
                    GameTooltip:AddLine(table.concat(profs, ", "), 0.8, 0.8, 0.8, true)
                else
                    GameTooltip:AddLine("No professions scanned", 0.6, 0.6, 0.6)
                end
                GameTooltip:AddLine("Click to map materials for this character.", 0.55, 0.75, 1)
                GameTooltip:Show()
            end)
            tab:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            tab:Show()
        else
            tab:Hide()
        end
    end
    if f.sidebarContent then
        f.sidebarContent:SetHeight(math.max(1, y))
    end

    local info = selectedMapChar and ns.CharDB:Get(selectedMapChar)
    local detail = f.charDetail or (f.charPanel and f.charPanel.detail)
    if not selectedMapChar or not info then
        if detail then
            detail:SetText("Log each alt and click Scan.")
        end
        for _, chip in ipairs(profChips) do
            chip:Hide()
        end
        return
    end

    local mappedProfs, itemCount, isDE = SummarizeMapsForChar(selectedMapChar)
    local known = {}
    for pk in pairs(info.professions or {}) do
        known[#known + 1] = pk
    end
    table.sort(known)

    local bits = {
        DestLabel(selectedMapChar, info),
    }
    if #known > 0 then
        bits[#bits + 1] = "Knows " .. table.concat(known, ", ")
    else
        bits[#bits + 1] = "No professions scanned"
    end
    if #mappedProfs > 0 then
        bits[#bits + 1] = "Receives " .. table.concat(mappedProfs, ", ")
    end
    if itemCount > 0 then
        bits[#bits + 1] = itemCount .. " items"
    end
    if isDE then
        bits[#bits + 1] = "|cffb57edcDE greens|r"
    end
    if detail then
        detail:SetText(table.concat(bits, "  ·  "))
    end

    -- Large profession buttons (mockup-style).
    local chipHost = f.chipHost or (f.charPanel and f.charPanel.chipHost)
    local chipIndex = 0
    local chipX, chipY = 0, 0
    local hostW = chipHost and chipHost:GetWidth() or 0
    if not hostW or hostW < 50 then
        hostW = 520
    end
    local chipW, chipH, chipGap = CHIP_W, CHIP_H, CHIP_GAP
    for _, p in ipairs(ns.Professions) do
        local has = info.professions and info.professions[p.key]
        local mappedTo = ns.db.maps.byProfession[p.key]
        local mappedHere = mappedTo == selectedMapChar
        if has or mappedHere then
            chipIndex = chipIndex + 1
            local chip = GetProfChip(chipIndex)
            chip.text:SetText(p.label or p.key)
            if chip.icon then
                chip.icon:SetTexture(PROF_ICONS[p.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
                chip.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            if chipX > 0 and (chipX + chipW) > hostW then
                chipX = 0
                chipY = chipY - (chipH + chipGap)
            end
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", chipHost, "TOPLEFT", chipX, chipY)
            chipX = chipX + chipW + chipGap

            local focused = selectedProf == p.key and not showAllMaterials
            chip.mark:SetShown(mappedHere)
            local prio = ns.Mapper:GetPriority(selectedMapChar, p.key)
            if prio == ns.Mapper.PRIORITY_HIGH then
                chip.prio:SetText("high")
                chip.prio:SetTextColor(1, 0.82, 0.2)
                chip.prio:Show()
            elseif prio == ns.Mapper.PRIORITY_LOW then
                chip.prio:SetText("low")
                chip.prio:SetTextColor(0.6, 0.6, 0.6)
                chip.prio:Show()
            else
                chip.prio:Hide()
            end
            chip.glow:SetShown(focused)
            if focused then
                chip:SetBackdropColor(1, 1, 1, 1)
                chip:SetBackdropBorderColor(1, 0.85, 0.30, 1)
                chip.fill:SetVertexColor(0.85, 0.62, 0.12, 0.70)
                chip.fill:Show()
                chip.text:SetTextColor(1, 0.97, 0.80)
            elseif mappedHere then
                chip:SetBackdropColor(0.80, 0.80, 0.80, 1)
                chip:SetBackdropBorderColor(0.45, 0.80, 0.45, 1)
                chip.fill:SetVertexColor(0.15, 0.45, 0.18, 0.35)
                chip.fill:Show()
                chip.text:SetTextColor(0.60, 1, 0.60)
            elseif has then
                chip:SetBackdropColor(0.80, 0.80, 0.80, 1)
                chip:SetBackdropBorderColor(THEME.insetBorder[1], THEME.insetBorder[2], THEME.insetBorder[3], 0.8)
                chip.fill:Hide()
                chip.text:SetTextColor(THEME.parchment[1], THEME.parchment[2], THEME.parchment[3])
            else
                chip:SetBackdropColor(0.80, 0.70, 0.70, 1)
                chip:SetBackdropBorderColor(0.60, 0.32, 0.30, 1)
                chip.fill:SetVertexColor(0.45, 0.12, 0.10, 0.35)
                chip.fill:Show()
                chip.text:SetTextColor(0.95, 0.65, 0.60)
            end
            local profKey = p.key
            chip:SetScript("OnClick", function(_, button)
                if not selectedMapChar then
                    return
                end
                if button == "RightButton" then
                    local level, owner = ns.Mapper:CyclePriority(selectedMapChar, profKey)
                    if level then
                        ns.Print("%s priority for shared mats: %s", profKey, ns.Mapper.PRIORITY_LABEL[level])
                    else
                        ns.Mapper:ExplainDenied(owner)
                    end
                    UI:RefreshMapper()
                    return
                end
                showAllMaterials = false
                if has then
                    selectedProf = profKey
                end
                if not ns.Mapper:CanEditChar(selectedMapChar) then
                    -- Other alts are view-only: focus the list, leave their routing alone.
                    UI:RefreshMapper()
                    return
                end
                local ok, owner
                if ns.db.maps.byProfession[profKey] == selectedMapChar then
                    ok, owner = ns.Mapper:SetProfessionMap(profKey, nil)
                    if ok then
                        ns.Print("Cleared %s profession map.", profKey)
                    end
                else
                    ok, owner = ns.Mapper:SetProfessionMap(profKey, selectedMapChar)
                    if ok then
                        ns.Print("%s -> %s", profKey, selectedMapChar)
                    end
                end
                if not ok then
                    ns.Mapper:ExplainDenied(owner)
                end
                UI:RefreshMapper()
            end)
            chip:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(p.label, 1, 0.82, 0)
                if has then
                    GameTooltip:AddLine("This character knows this profession.", 0.7, 0.9, 0.7)
                else
                    GameTooltip:AddLine("Mapped here, but not in their last scan.", 0.9, 0.7, 0.5)
                end
                if not ns.Mapper:CanEditChar(selectedMapChar) then
                    GameTooltip:AddLine("View only — log in on this character to change its routing.", 0.9, 0.6, 0.4)
                elseif mappedHere then
                    GameTooltip:AddLine("Click to clear profession map (and focus list).", 0.8, 0.8, 0.8)
                else
                    local owner = ns.db.maps.byProfession[profKey]
                    if owner and owner ~= selectedMapChar then
                        GameTooltip:AddLine("Claimed by " .. owner .. " — only they can release it.", 0.9, 0.6, 0.4)
                    else
                        GameTooltip:AddLine("Click to send this profession's mats here.", 0.8, 0.8, 0.8)
                    end
                end
                local level = ns.Mapper:GetPriority(selectedMapChar, profKey)
                GameTooltip:AddLine(
                    "Shared-mat priority: " .. ns.Mapper.PRIORITY_LABEL[level],
                    1, 0.82, 0.2
                )
                GameTooltip:AddLine(
                    "Mats several of your alts' professions use go to the highest priority.",
                    0.7, 0.7, 0.7, true
                )
                if ns.Mapper:CanEditChar(selectedMapChar) then
                    GameTooltip:AddLine("Right-click: cycle normal / high / low", 0.7, 0.85, 1)
                end
                GameTooltip:Show()
            end)
            chip:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            chip:Show()
        end
    end
    for i = chipIndex + 1, #profChips do
        profChips[i]:Hide()
    end
end

local function GetMapperRow(i)
    local row = mapperRows[i]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, mapperFrame.content, "BackdropTemplate")
    row:SetHeight(34)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ApplyInset(row, THEME.row[1], THEME.row[2], THEME.row[3], THEME.row[4])
    row:SetBackdropBorderColor(THEME.rowBorder[1], THEME.rowBorder[2], THEME.rowBorder[3], THEME.rowBorder[4])

    row.iconFrame, row.icon = IconFrame(row, 22)
    row.iconFrame:SetPoint("LEFT", 5, 0)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", row.iconFrame, "RIGHT", 8, 0)
    row.text:SetTextColor(THEME.parchment[1], THEME.parchment[2], THEME.parchment[3])
    row.text:SetPoint("RIGHT", row, "CENTER", -4, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    row.dest = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.dest:SetPoint("LEFT", row, "CENTER", 4, 0)
    row.dest:SetPoint("RIGHT", -34, 0)
    row.dest:SetJustifyH("RIGHT")
    row.dest:SetWordWrap(false)

    -- Dropdown-style chevron well (Shorts row look); the whole row is the click target.
    row.chevronBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.chevronBox:SetSize(20, 20)
    row.chevronBox:SetPoint("RIGHT", -7, 0)
    row.chevronBox:SetBackdrop(CHIP_BACKDROP)
    row.chevronBox:SetBackdropColor(0.45, 0.42, 0.38, 1)
    row.chevronBox:SetBackdropBorderColor(THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.8)
    row.chevron = row.chevronBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.chevron:SetPoint("CENTER", 0, 0)
    row.chevron:SetText("v")
    row.chevron:SetTextColor(THEME.gold[1], THEME.gold[2], THEME.gold[3])

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    row.highlight:SetBlendMode("ADD")
    row.highlight:SetAlpha(0.35)
    row.highlight:SetPoint("TOPLEFT", 3, -3)
    row.highlight:SetPoint("BOTTOMRIGHT", -3, 3)

    mapperRows[i] = row
    return row
end

function UI:RescaleCharTabs()
    if mapperFrame and mapperFrame:IsShown() then
        self:RefreshMapper()
    end
end

function UI:RefreshMapper()
    local f = EnsureMapper()
    ns.Dropdown.CloseAll()

    local okTabs, errTabs = pcall(RefreshCharTabsAndPanel, f)
    if not okTabs then
        ns.Print("Character tabs refresh failed: %s", tostring(errTabs))
    end

    ClampSelectedProfession(selectedMapChar)

    f.expDrop:SetOptions(ExpansionOptions())
    f.expDrop:Refresh()
    f.profDrop:SetOptions(ProfessionOptionsForChar(selectedMapChar))
    f.profDrop:Refresh()

    local profLabel = selectedProf and selectedProf ~= "" and selectedProf or "—"
    local profMap = selectedProf and ns.db.maps.byProfession[selectedProf]
    local deChar = ns.Mapper:GetDEFodderChar()
    local deSettings = ns.db.settings.deFodder or {}
    local deOn = deSettings.enabled ~= false and deChar
    f.mapStatus:SetText(string.format(
        "%s > %s%s",
        profLabel,
        profMap and ("|cff7dcea0" .. ShortCharName(profMap, ns.CharDB:Get(profMap)) .. "|r") or "|cff888888unmapped|r",
        deOn and ("    DE > |cffb57edc" .. ShortCharName(deChar, ns.CharDB:Get(deChar)) .. "|r") or ""
    ) .. (ns.Mapper:CanEditChar(selectedMapChar) and "" or "    |cffe0a060view only|r"))
    if f.mapDEBtn then
        f.mapDEBtn:SetEnabled((ns.Mapper:CanChangeMap(deChar, ns.PlayerKey())))
    end
    if f.clearDEBtn then
        f.clearDEBtn:SetEnabled(deChar ~= nil and (ns.Mapper:CanChangeMap(deChar, nil)))
    end

    local needle = (materialSearch or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local rows = {}
    for _, entry in ipairs(ns.Materials) do
        if not entry.placeholder then
            local ok
            if showAllMaterials then
                ok = needle ~= "" or entry.expansion == selectedExpansion
            elseif showSharedOnly then
                ok = entry.expansion == selectedExpansion and #ns.MaterialProfessions(entry) > 1
                    and (not selectedProf or ns.MaterialUsesProfession(entry, selectedProf))
            else
                ok = entry.expansion == selectedExpansion and ns.MaterialUsesProfession(entry, selectedProf)
            end
            if ok and needle ~= "" then
                local name = (entry.name or ""):lower()
                local base = (entry.baseName or ""):lower()
                ok = string.find(name, needle, 1, true) ~= nil
                    or string.find(base, needle, 1, true) ~= nil
            end
            if ok then
                rows[#rows + 1] = entry
            end
        end
    end
    table.sort(rows, function(a, b)
        local an = a.baseName or a.name or ""
        local bn = b.baseName or b.name or ""
        if an == bn then
            return (a.quality or 0) < (b.quality or 0)
        end
        return an < bn
    end)

    if f.scopeAllBtn then
        f.scopeAllBtn:SetText(showAllMaterials and "By profession" or "All mats")
    end
    if f.sharedBtn then
        f.sharedBtn:SetText(showSharedOnly and "|cffffd100Shared|r" or "Shared")
        if showSharedOnly then
            f.sharedBtn:LockHighlight()
        else
            f.sharedBtn:UnlockHighlight()
        end
    end
    local expLabel = tostring(ns.ExpansionLabel[selectedExpansion] or selectedExpansion or "?")
    if f.searchBox and f.searchBox:GetText() ~= materialSearch then
        f.searchBox:SetText(materialSearch or "")
    end
    if f.listCount then
        local matchSuffix = needle ~= "" and (" matching |cffffffff" .. tostring(materialSearch) .. "|r") or ""
        if showAllMaterials then
            f.listCount:SetText(string.format(
                "Showing |cffffffff%d|r material(s)%s",
                #rows,
                needle ~= "" and (matchSuffix .. " (all expansions)")
                    or (" for |cffffffff" .. expLabel .. "|r (all professions)")
            ))
        elseif showSharedOnly then
            f.listCount:SetText(string.format(
                "Showing |cffffffff%d|r shared material(s) for |cffffffff%s|r / |cffffffff%s|r%s",
                #rows,
                expLabel,
                tostring(profLabel or "—"),
                matchSuffix
            ))
        else
            f.listCount:SetText(string.format(
                "Showing |cffffffff%d|r material(s) for |cffffffff%s|r / |cffffffff%s|r%s",
                #rows,
                tostring(selectedExpansion or "?"),
                tostring(profLabel or "—"),
                matchSuffix
            ))
        end
    end

    local mappedTotal = 0
    if ns.db and ns.db.maps then
        for _ in pairs(ns.db.maps.byItem or {}) do
            mappedTotal = mappedTotal + 1
        end
        for _ in pairs(ns.db.maps.byProfession or {}) do
            mappedTotal = mappedTotal + 1
        end
    end
    if f.footerCount then
        local ties = 0
        for _, entry in ipairs(ns.Materials) do
            if not entry.placeholder and not ns.Mapper:GetItemMap(entry.itemId) then
                local claims, _, tie = ns.Mapper:Conflict(entry)
                if claims and tie then
                    ties = ties + 1
                end
            end
        end
        f.footerCount:SetText(string.format("%d materials mapped", mappedTotal)
            .. (ties > 0 and string.format("  ·  |cffffb347%d shared tie(s)|r", ties) or ""))
    end

    local prev
    for i = 1, math.max(#rows, #mapperRows) do
        local row = GetMapperRow(i)
        local entry = rows[i]
        if entry then
            local mapped = ns.Mapper:GetItemMap(entry.itemId)
            local resolved = ns.Mapper:ResolveRecipient(entry)
            local claims, _, tie = ns.Mapper:Conflict(entry)
            local destKey = mapped or resolved
            local destInfo = destKey and ns.CharDB:Get(destKey)
            local label
            if mapped and destInfo then
                label = DestLabel(mapped, destInfo)
            elseif mapped then
                label = "|cff7dcea0" .. ShortCharName(mapped, nil) .. "|r"
            elseif resolved and destInfo then
                label = "|cffaaaaaaauto |r" .. DestLabel(resolved, destInfo)
            elseif resolved then
                label = "|cffaaaaaaauto " .. ShortCharName(resolved, nil) .. "|r"
            else
                label = "|cff666666unmapped|r"
            end
            if claims then
                local tagColor = (tie and not mapped) and "ffb347" or "8a8a8a"
                label = string.format("|cff%sshared|r  %s", tagColor, label)
            end
            if claims and tie and not mapped then
                row:SetBackdropBorderColor(1, 0.62, 0.25, 0.9)
            else
                row:SetBackdropBorderColor(THEME.rowBorder[1], THEME.rowBorder[2], THEME.rowBorder[3], THEME.rowBorder[4])
            end
            local nameBit = entry.name or "?"
            local profs = ns.MaterialProfessions(entry)
            if showAllMaterials then
                if #profs > 0 then
                    nameBit = string.format("%s  |cff777777%s|r", nameBit, table.concat(profs, ", "))
                end
            elseif #profs > 1 then
                local others = {}
                for _, p in ipairs(profs) do
                    if p ~= selectedProf then
                        others[#others + 1] = p
                    end
                end
                nameBit = string.format("%s  |cff9a8a6aalso %s|r", nameBit, table.concat(others, ", "))
            end
            if row.icon then
                row.icon:SetTexture(MaterialItemIcon(entry.itemId))
                row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            row.text:SetText(nameBit)
            if row.dest then
                row.dest:SetText(label)
            end
            row:ClearAllPoints()
            if prev then
                row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
                row:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -4)
            else
                row:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, 0)
                row:SetPoint("TOPRIGHT", f.content, "TOPRIGHT", 0, 0)
            end
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row:SetScript("OnClick", function(_, button)
                if button == "RightButton" then
                    UI:UnmapItem(entry.itemId)
                else
                    UI:AssignItemToSelected(entry.itemId)
                end
            end)
            row:SetScript("OnEnter", function(owner)
                GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
                GameTooltip:AddLine(entry.name or "Material", 1, 0.82, 0)
                if ns.Mapper:CanEditChar(selectedMapChar) then
                    GameTooltip:AddLine("Left-click: map to this character", 0.7, 0.85, 1)
                    GameTooltip:AddLine("Right-click: unmap your item override", 0.7, 0.85, 1)
                else
                    GameTooltip:AddLine("View only — log in on this character to change its routing.", 0.9, 0.6, 0.4)
                end
                if mapped then
                    GameTooltip:AddLine(
                        "Item map: " .. ShortCharName(mapped, ns.CharDB:Get(mapped)),
                        0.5,
                        0.9,
                        0.5
                    )
                elseif resolved then
                    GameTooltip:AddLine(
                        "Auto via profession: " .. ShortCharName(resolved, ns.CharDB:Get(resolved)),
                        0.7,
                        0.7,
                        0.7
                    )
                end
                if claims then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Shared mat — wanted by:", 1, 0.82, 0)
                    for idx, c in ipairs(claims) do
                        local gets = (mapped and c.charKey == mapped) or (not mapped and idx == 1)
                        GameTooltip:AddLine(string.format(
                            "%s %s — %s (%s%s)",
                            gets and "|cff7dcea0>|r" or " ",
                            ShortCharName(c.charKey, ns.CharDB:Get(c.charKey)),
                            c.prof,
                            ns.Mapper.PRIORITY_LABEL[c.priority],
                            c.reason == "expansion" and ", expansion map" or ""
                        ), gets and 0.49 or 0.6, gets and 0.81 or 0.6, gets and 0.63 or 0.6)
                    end
                    if mapped then
                        GameTooltip:AddLine("Settled by an item map.", 0.6, 0.6, 0.6)
                    elseif tie then
                        GameTooltip:AddLine(
                            "Tie — decided by catalog order. Left-click to keep it on this character,"
                                .. " or right-click a profession chip to raise its priority.",
                            1, 0.62, 0.25, true
                        )
                    else
                        GameTooltip:AddLine("Decided by priority. Left-click to override for this item.", 0.6, 0.6, 0.6)
                    end
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            row:Show()
            prev = row
        else
            row:Hide()
        end
    end

    local contentHeight = math.max(1, #rows * 38)
    f.content:SetHeight(contentHeight)
    f.scroll:SetVerticalScroll(0)
end

function UI:ShowMapper(opts)
    local f = EnsureMapper()
    ns.LearnUsesFromProfessionMaster()
    f:Show()
    self:RefreshMapper()
    if not (opts and opts.noIntro) and ns.Intro and ns.Intro.MaybeShowOnOpen then
        ns.Intro:MaybeShowOnOpen()
    end
end

function UI:ToggleMapper()
    local f = EnsureMapper()
    if f:IsShown() then
        ns.Dropdown.CloseAll()
        f:Hide()
    else
        self:ShowMapper()
    end
end

-- Mail prompt
local mailRows = {}

local function MailWho(charKey)
    local info = ns.db and ns.db.chars and ns.db.chars[charKey]
    if info and info.mailName and info.mailName ~= "" then
        return info.mailName
    end
    return charKey
end

local function ResetMailFrame()
    if mailFrame then
        mailFrame:Hide()
        mailFrame:SetParent(nil)
        mailFrame = nil
    end
    wipe(mailRows)
end

local function EnsureMailPrompt()
    if mailFrame and mailFrame.layoutVersion ~= MAIL_LAYOUT then
        ResetMailFrame()
    end
    if mailFrame then
        return mailFrame
    end

    local f = CreateFrame("Frame", "SnapPostForeverMailPrompt", UIParent, "BackdropTemplate")
    f.layoutVersion = MAIL_LAYOUT
    f:SetSize(460, 540)
    f:SetPoint("CENTER", 0, 40)
    ApplyWindow(f)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true)
    f:Hide()
    tinsert(UISpecialFrames, "SnapPostForeverMailPrompt")
    -- Esc hides the frame directly; stop the queue so it never sends with the prompt closed.
    f:SetScript("OnHide", function()
        if ns.MailQueue and ns.MailQueue:IsActive() then
            ns.MailQueue:Cancel("closed by user")
        end
    end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -18)
    f.title:SetText("SnapPost Forever Mail")
    f.title:SetTextColor(THEME.title[1], THEME.title[2], THEME.title[3])
    f.title:SetShadowColor(0, 0, 0, 1)
    f.title:SetShadowOffset(1, -1)

    f.titleRule = GoldRule(f, 0.6)
    f.titleRule:SetPoint("TOPLEFT", 40, -42)
    f.titleRule:SetPoint("TOPRIGHT", -40, -42)

    f.body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.body:SetPoint("TOPLEFT", 18, -50)
    f.body:SetPoint("TOPRIGHT", -18, -50)
    f.body:SetJustifyH("LEFT")
    f.body:SetWordWrap(true)
    f.body:SetHeight(36)
    f.body:SetTextColor(THEME.parchment[1], THEME.parchment[2], THEME.parchment[3])

    f.listWell = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.listWell:SetPoint("TOPLEFT", 14, -90)
    f.listWell:SetPoint("BOTTOMRIGHT", -14, 116)
    ApplyInset(f.listWell)

    f.scroll = CreateFrame("ScrollFrame", "SnapPostForeverMailScroll", f.listWell, "UIPanelScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 6, -6)
    f.scroll:SetPoint("BOTTOMRIGHT", -28, 6)

    f.content = CreateFrame("Frame", nil, f.scroll)
    f.content:SetSize(386, 1)
    f.scroll:SetScrollChild(f.content)

    -- Progress card (Shorts "Sending securely..." look).
    f.card = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.card:SetPoint("BOTTOMLEFT", 14, 50)
    f.card:SetPoint("BOTTOMRIGHT", -14, 50)
    f.card:SetHeight(58)
    ApplyInset(f.card)
    f.cardIconFrame, f.cardIcon = IconFrame(f.card, 36)
    f.cardIconFrame:SetPoint("LEFT", 8, 0)
    f.cardIcon:SetTexture("Interface\\Icons\\INV_Letter_15")
    f.cardIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    f.cardTitle = f.card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.cardTitle:SetPoint("TOPLEFT", f.cardIconFrame, "TOPRIGHT", 10, -1)
    f.cardTitle:SetText("SnapPost Forever Mail")
    f.cardTitle:SetTextColor(THEME.parchment[1], THEME.parchment[2], THEME.parchment[3])

    f.progress = CreateFrame("StatusBar", nil, f.card, "BackdropTemplate")
    f.progress:SetPoint("LEFT", f.cardIconFrame, "RIGHT", 10, 0)
    f.progress:SetPoint("RIGHT", f.card, "RIGHT", -12, 0)
    f.progress:SetHeight(10)
    f.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.progress:SetStatusBarColor(0.35, 0.85, 0.15)
    f.progress:SetMinMaxValues(0, 1)
    f.progress:SetValue(0)
    f.progress:SetBackdrop({
        bgFile = WHITE,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f.progress:SetBackdropColor(0, 0, 0, 0.8)
    f.progress:SetBackdropBorderColor(THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.7)

    f.status = f.card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("BOTTOMLEFT", f.cardIconFrame, "BOTTOMRIGHT", 10, 1)
    f.status:SetPoint("RIGHT", f.card, "RIGHT", -12, 0)
    f.status:SetJustifyH("LEFT")
    f.status:SetWordWrap(false)
    f.status:SetTextColor(0.80, 0.80, 0.80)

    f.bulk = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.bulk:SetSize(160, 28)
    f.bulk:SetPoint("BOTTOMLEFT", 16, 14)
    f.bulk:SetText("Send remaining")

    f.cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.cancel:SetSize(100, 28)
    f.cancel:SetPoint("BOTTOMRIGHT", -16, 14)
    f.cancel:SetText("Close")
    f.cancel:SetScript("OnClick", function()
        UI:HideMailPrompt("closed by user")
    end)

    -- If the mailbox UI disappears without MAIL_CLOSED (Forever quirk), close with it.
    f:SetScript("OnUpdate", function(self, elapsed)
        self._spfMailCheck = (self._spfMailCheck or 0) + elapsed
        if self._spfMailCheck < 0.25 then
            return
        end
        self._spfMailCheck = 0
        if not UI:IsMailboxOpen() then
            UI:HideMailPrompt("Mailbox closed")
        end
    end)

    mailFrame = f

    ns.MailQueue:SetUpdateHandler(function(st)
        if mailFrame and mailFrame:IsShown() then
            mailFrame.status:SetText(st.status or "")
            UI:SetMailProgress(st)
        end
    end)

    return f
end

local function ItemIconTexture(stack)
    if stack.bag ~= nil and stack.slot and C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(stack.bag, stack.slot)
        if info and (info.iconFileID or info.icon) then
            return info.iconFileID or info.icon
        end
    end
    if stack.itemId and C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(stack.itemId)
    end
    if stack.itemId and GetItemIcon then
        return GetItemIcon(stack.itemId)
    end
end

local function GetMailRow(parent, i)
    local row = mailRows[i]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(30)
    ApplyInset(row, THEME.row[1], THEME.row[2], THEME.row[3], THEME.row[4])
    row:SetBackdropBorderColor(THEME.rowBorder[1], THEME.rowBorder[2], THEME.rowBorder[3], THEME.rowBorder[4])
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", 4, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 30, 0)
    row.text:SetPoint("RIGHT", -78, 0)
    row.text:SetJustifyH("LEFT")
    row.skip = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.skip:SetSize(64, 20)
    row.skip:SetPoint("RIGHT", -4, 0)
    mailRows[i] = row
    return row
end

function UI:RefreshMailList()
    local f = mailFrame
    local plan = f and f.plan
    if not f or not plan then
        return
    end

    local stacks, items = ns.BagScan:ActiveCounts(plan)
    if plan.totalStacks == 0 then
        f.body:SetText(
            "No mapped profession materials found in bags for other characters.\n"
                .. "Open the mapper (/spostf), assign professions or items, then reopen the mailbox."
        )
        f.bulk:Disable()
        for _, row in ipairs(mailRows) do
            row:Hide()
        end
        return
    end

    if stacks == 0 then
        f.body:SetText(
            "Bags are clear of mapped materials for other characters.\n"
                .. "Open the mapper (/spostf) if you still need to assign professions or items."
        )
        f.bulk:Disable()
    else
        f.body:SetText(string.format(
            "Sending |cffffffff%d|r stack(s) (|cffffffff%d|r items). Click Skip to leave a stack in your bags. Delay |cffffffff%.1fs|r.",
            stacks, items, ns.db.settings.sendDelay or 3
        ))
        f.bulk:Enable()
    end

    local lines = {}
    for _, group in ipairs(plan.recipients) do
        lines[#lines + 1] = { kind = "header", group = group }
        for _, stack in ipairs(group.stacks) do
            lines[#lines + 1] = { kind = "stack", group = group, stack = stack }
        end
    end

    local prev
    for i = 1, math.max(#lines, #mailRows) do
        local row = GetMailRow(f.content, i)
        local line = lines[i]
        if line then
            row:ClearAllPoints()
            if prev then
                row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
                row:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -2)
            else
                row:SetPoint("TOPLEFT", f.content, "TOPLEFT", 0, 0)
                row:SetPoint("TOPRIGHT", f.content, "TOPRIGHT", 0, 0)
            end
            row.icon:Hide()
            row.text:SetPoint("LEFT", 8, 0)
            if line.kind == "header" then
                row:SetBackdropColor(0.14, 0.14, 0.16, 1)
                row:SetBackdropBorderColor(0.55, 0.50, 0.35, 1)
                row.text:SetText("|cffffd100To|r  " .. MailWho(line.group.charKey))
                row.skip:SetText("Send")
                row.skip:Show()
                row.skip:SetScript("OnClick", function()
                    if ns.MailQueue:IsActive() then
                        return
                    end
                    ns.MailQueue:Start(plan, "one", line.group.charKey)
                end)
                row:SetScript("OnClick", nil)
            else
                local stack = line.stack
                row.text:SetPoint("LEFT", 30, 0)
                local icon = ItemIconTexture(stack)
                if icon then
                    row.icon:SetTexture(icon)
                    row.icon:Show()
                end
                local deTag = (stack.reason == "defodder") and "  |cffb57edcDE|r" or ""
                if stack.excluded then
                    row:SetBackdropColor(0.14, 0.10, 0.10, 1)
                    row:SetBackdropBorderColor(0.40, 0.28, 0.28, 1)
                    row.icon:SetDesaturated(true)
                    row.icon:SetAlpha(0.45)
                    row.text:SetText(string.format("|cff888888%s x%d  (skipped)|r", stack.name or "?", stack.count or 1))
                    row.skip:SetText("Keep")
                else
                    row:SetBackdropColor(THEME.row[1], THEME.row[2], THEME.row[3], THEME.row[4])
                    row:SetBackdropBorderColor(
                        THEME.rowBorder[1],
                        THEME.rowBorder[2],
                        THEME.rowBorder[3],
                        THEME.rowBorder[4]
                    )
                    row.icon:SetDesaturated(false)
                    row.icon:SetAlpha(1)
                    row.text:SetText(string.format("%s  |cffffffffx%d|r%s", stack.name or "?", stack.count or 1, deTag))
                    row.skip:SetText("Skip")
                end
                row.skip:Show()
                row.skip:SetScript("OnClick", function()
                    if ns.MailQueue:IsActive() then
                        return
                    end
                    stack.excluded = not stack.excluded
                    UI:RefreshMailList()
                end)
                row:SetScript("OnClick", function()
                    if ns.MailQueue:IsActive() then
                        return
                    end
                    stack.excluded = not stack.excluded
                    UI:RefreshMailList()
                end)
            end
            row:Show()
            prev = row
        else
            row:Hide()
        end
    end

    f.content:SetHeight(math.max(1, #lines * 30))
end

function UI:SetMailProgress(st)
    local f = mailFrame
    if not (f and f.progress) then
        return
    end
    st = st or (ns.MailQueue and ns.MailQueue:GetState()) or {}
    local total = st.jobs and #st.jobs or 0
    local value = 0
    if st.status == "done" then
        value = 1
    elseif st.active and total > 0 then
        local finished = (st.jobIndex or 1) - 1
        value = (finished + (st.waiting and 0.5 or 0)) / total
    end
    f.progress:SetValue(math.max(0, math.min(1, value)))
    if st.active then
        f.progress:SetStatusBarColor(0.35, 0.85, 0.15)
    elseif st.status ~= "done" and st.status ~= "idle" and value < 1 and value > 0 then
        f.progress:SetStatusBarColor(0.80, 0.30, 0.20)
    end
end

function UI:IsMailboxOpen()
    if MailFrame and MailFrame:IsShown() then
        return true
    end
    if InboxFrame and InboxFrame:IsShown() then
        return true
    end
    if SendMailFrame and SendMailFrame:IsShown() then
        return true
    end
    if C_PlayerInteractionManager and C_PlayerInteractionManager.IsInteractingWithNpcOfType
        and Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo then
        return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo)
    end
    return false
end

function UI:HideMailPrompt(reason)
    if ns.MailQueue and ns.MailQueue:IsActive() then
        ns.MailQueue:Cancel(reason or "Mailbox closed")
    end
    if mailFrame then
        mailFrame:Hide()
    end
end

local mailFrameHooksInstalled
function UI:EnsureMailFrameHooks()
    if mailFrameHooksInstalled then
        return
    end
    local function onMailboxHide()
        UI:HideMailPrompt("Mailbox closed")
    end
    if MailFrame then
        MailFrame:HookScript("OnHide", onMailboxHide)
        mailFrameHooksInstalled = true
    end
end

local function CollectExcluded(plan)
    local byItem = {}
    if not plan then
        return byItem
    end
    for _, group in ipairs(plan.recipients or {}) do
        for _, stack in ipairs(group.stacks or {}) do
            if stack.excluded and stack.itemId then
                byItem[stack.itemId] = (byItem[stack.itemId] or 0) + 1
            end
        end
    end
    return byItem
end

local function ApplyExcluded(plan, byItem)
    if not plan or not byItem then
        return
    end
    for _, group in ipairs(plan.recipients or {}) do
        for _, stack in ipairs(group.stacks or {}) do
            local n = byItem[stack.itemId]
            if n and n > 0 then
                stack.excluded = true
                byItem[stack.itemId] = n - 1
            end
        end
    end
end

--- Rebuild the mail list from current bags (keeps Skip marks where possible).
function UI:RescanMailPlan()
    if not mailFrame or not mailFrame:IsShown() or not ns.BagScan then
        return nil
    end
    local excluded = CollectExcluded(mailFrame.plan)
    local plan = ns.BagScan:BuildPlan()
    ApplyExcluded(plan, excluded)
    mailFrame.plan = plan
    self:RefreshMailList()
    return plan
end

function UI:ShowMailPrompt(plan)
    self:EnsureMailFrameHooks()
    if not self:IsMailboxOpen() then
        return
    end
    local f = EnsureMailPrompt()
    f.plan = plan
    if not (ns.MailQueue and ns.MailQueue:IsActive()) then
        f.status:SetText("Ready — Send one alt or Send remaining.")
        f.progress:SetValue(0)
        f.progress:SetStatusBarColor(0.35, 0.85, 0.15)
    end
    f.bulk:SetScript("OnClick", function()
        if ns.MailQueue:IsActive() then
            return
        end
        -- Always send from the latest scan, not a stale closure.
        local current = f.plan or plan
        ns.MailQueue:Start(current, "bulk")
    end)
    self:RefreshMailList()
    f:Show()
end
