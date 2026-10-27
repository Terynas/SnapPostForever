local _, ns = ...

ns.Intro = ns.Intro or {}
local Intro = ns.Intro

local introFrame
local stepIndex = 1

local STEPS = {
    {
        title = "Welcome to SnapPost Forever",
        body = "This addon maps classic profession materials to your alts and helps you mail them"
            .. " from any mailbox with safe delays.\n\nA short tour takes about a minute."
            .. " You can skip it anytime, or turn the guide off in Options.",
    },
    {
        title = "1. Scan each crafting alt",
        body = "Log onto every character that crafts, then click |cffffffffScan|r in the mapper"
            .. " (or run |cffffffff/spostf scan|r).\n\nEach alt appears in the left sidebar with class icon + name."
            .. " SnapPost remembers their professions for the whole account.",
    },
    {
        title = "2. Map materials to characters",
        body = "Each character sets up its own routing — log in on the alt that should receive the mats."
            .. " Other alts in the sidebar are view-only.\n\n"
            .. "• Click a profession button to send that profession's mats to you (gold border = focused list).\n"
            .. "• Left-click a material row to map only that item; right-click to clear.\n"
            .. "• |cffffffffClaim My Profs|r claims every unmapped profession this character knows.\n"
            .. "• On your enchanter, use |cffffffffDE greens|r to receive low-value Uncommon gear.",
    },
    {
        title = "3. Send from the mailbox",
        body = "Gather on farm toons, then open a mailbox. SnapPost lists mapped stacks with icons.\n\n"
            .. "Skip anything you want to keep, then Send one recipient or |cffffffffSend remaining|r."
            .. " Delay between mails is set in Options (default 3 seconds).",
    },
    {
        title = "You're ready",
        body = "Open the mapper anytime with |cffffffff/spostf|r or the minimap letter icon.\n\n"
            .. "Options live under |cffffffffEsc > Options > AddOns > SnapPost Forever|r — including"
            .. " |cffffffffSkip first-time guide|r if you never want this tour again.",
    },
}

local function PlayerKey()
    if ns.PlayerKey then
        return ns.PlayerKey()
    end
    return UnitName("player") or "Unknown"
end

local function SkipEnabled()
    return ns.db and ns.db.settings and ns.db.settings.skipIntro == true
end

function Intro:WasSeenForPlayer()
    if not ns.db then
        return true
    end
    ns.db.introSeen = ns.db.introSeen or {}
    return ns.db.introSeen[PlayerKey()] == true
end

function Intro:MarkSeen()
    if not ns.db then
        return
    end
    ns.db.introSeen = ns.db.introSeen or {}
    ns.db.introSeen[PlayerKey()] = true
end

function Intro:ShouldShow()
    if not ns.db then
        return false
    end
    if SkipEnabled() then
        return false
    end
    return not self:WasSeenForPlayer()
end

local function RefreshStep()
    if not introFrame then
        return
    end
    local step = STEPS[stepIndex]
    if not step then
        return
    end
        introFrame.title:SetText(step.title)
        introFrame.title:SetTextColor(1, 0.82, 0)
        introFrame.body:SetText(step.body)
    introFrame.progress:SetText(string.format("Step %d of %d", stepIndex, #STEPS))

    if stepIndex <= 1 then
        introFrame.back:Disable()
    else
        introFrame.back:Enable()
    end

    if stepIndex >= #STEPS then
        introFrame.next:SetText("Finish")
    else
        introFrame.next:SetText("Next")
    end
end

local function CloseIntro(markSeen)
    if markSeen then
        Intro:MarkSeen()
    end
    if introFrame then
        introFrame:Hide()
    end
end

local INTRO_LAYOUT = 2

local function EnsureFrame()
    if introFrame and introFrame.layoutVersion ~= INTRO_LAYOUT then
        introFrame:Hide()
        introFrame:SetParent(nil)
        introFrame = nil
    end
    if introFrame then
        return introFrame
    end

    local f = CreateFrame("Frame", "SnapPostForeverIntroFrame", UIParent, "BackdropTemplate")
    f.layoutVersion = INTRO_LAYOUT
    f:SetSize(480, 320)
    f:SetPoint("CENTER", 0, 40)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:EnableMouse(true)
    f:Hide()
    tinsert(UISpecialFrames, "SnapPostForeverIntroFrame")

    if ns.UI and ns.UI.ApplyWindowChrome then
        ns.UI.ApplyWindowChrome(f)
    else
        f:SetBackdrop({
            bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 256,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        f:SetBackdropColor(0.06, 0.07, 0.10, 1)
        f:SetBackdropBorderColor(0.55, 0.55, 0.60, 1)
    end

    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.header:SetPoint("TOPLEFT", 22, -18)
    f.header:SetText("SnapPost Forever")
    f.header:SetTextColor(1, 0.82, 0)

    f.progress = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.progress:SetPoint("TOPRIGHT", -22, -22)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 22, -48)
    f.title:SetPoint("TOPRIGHT", -22, -48)
    f.title:SetJustifyH("LEFT")

    f.body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.body:SetPoint("TOPLEFT", 22, -78)
    f.body:SetPoint("BOTTOMRIGHT", -22, 56)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")
    f.body:SetWordWrap(true)
    f.body:SetSpacing(3)

    f.skip = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.skip:SetSize(90, 24)
    f.skip:SetPoint("BOTTOMLEFT", 22, 20)
    f.skip:SetText("Skip")
    f.skip:SetScript("OnClick", function()
        CloseIntro(true)
    end)

    f.back = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.back:SetSize(90, 24)
    f.back:SetPoint("BOTTOMRIGHT", -214, 20)
    f.back:SetText("Back")
    f.back:SetScript("OnClick", function()
        if stepIndex > 1 then
            stepIndex = stepIndex - 1
            RefreshStep()
        end
    end)

    f.next = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.next:SetSize(100, 24)
    f.next:SetPoint("BOTTOMRIGHT", -22, 20)
    f.next:SetText("Next")
    f.next:SetScript("OnClick", function()
        if stepIndex >= #STEPS then
            CloseIntro(true)
        else
            stepIndex = stepIndex + 1
            RefreshStep()
        end
    end)

    f:SetScript("OnHide", function()
        -- Esc / close still dismisses the guide for this character.
        Intro:MarkSeen()
    end)

    introFrame = f
    return f
end

function Intro:Show(force)
    if not force and not self:ShouldShow() then
        return false
    end
    stepIndex = 1
    local f = EnsureFrame()
    RefreshStep()
    f:Show()
    f:Raise()
    return true
end

function Intro:MaybeShowOnOpen()
    if self:ShouldShow() then
        -- Defer one frame so the mapper is visible behind the guide.
        C_Timer.After(0.05, function()
            if Intro:ShouldShow() then
                Intro:Show(false)
            end
        end)
        return true
    end
    return false
end
