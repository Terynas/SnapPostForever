local _, ns = ...

ns.defaults = {
    settings = {
        autoPrompt = true,
        chatMailProgress = true, -- Queuing / Sent to / finished lines in chat
        sendDelay = 3.0,
        mailSubject = "SnapPost Forever materials",
        skipSoulbound = true,
        onlyMapped = true,
        showMinimap = true,
        charTabSize = 28, -- mapper sidebar alt icon size (20–40)
        skipIntro = false, -- Options: never show first-time guide
        deFodder = {
            -- Green armor/weapons under these caps → maps.deFodderChar (enchanter).
            enabled = true,
            maxLevel = 40,           -- max(reqLevel, itemLevel)
            maxVendorCopper = 50000, -- 5g vendor sell
            maxAuctionCopper = 10000, -- 1g Auctionator AH (skip if higher)
            skipIfVendorBeatsDE = true, -- if Auctionator DE value ≤ vendor, keep for vendor
        },
    },
    minimap = {
        hide = false,
        angle = 200,
    },
    introSeen = {}, -- [CharKey] = true after first-time guide on that character
    chars = {},
    maps = {
        byItem = {},
        byProfession = {},
        byExpansionProfession = {},
        deFodderChar = nil, -- CharKey for low-value green DE fodder
    },
    claimPriority = {}, -- [CharKey][profKey] = 3 high / 1 low (normal omitted)
}

SLASH_SNAPPOSTFOREVER1 = "/spostf"
SLASH_SNAPPOSTFOREVER2 = "/snappostf"
SLASH_SNAPPOSTFOREVER3 = "/snappost"
SlashCmdList["SNAPPOSTFOREVER"] = function(msg)
    local raw = (msg or ""):match("^%s*(.-)%s*$") or ""
    local cmd = raw:lower()

    if cmd == "" or cmd == "open" or cmd == "mapper" then
        if ns.UI then
            ns.UI:ToggleMapper()
        end
        return
    end

    if cmd == "options" or cmd == "config" or cmd == "settings" then
        if ns.Options then
            ns.Options:Open()
        end
        return
    end

    if cmd == "minimap" then
        if ns.MinimapButton then
            local show = not ns.MinimapButton:IsShown()
            ns.MinimapButton:SetShown(show)
            if ns.db and ns.db.settings then
                ns.db.settings.showMinimap = show
            end
            ns.Print("Minimap icon %s.", show and "shown" or "hidden")
        end
        return
    end

    if cmd == "scan" then
        if ns.CharDB then
            local key = ns.CharDB:ScanPlayer()
            ns.Print("Scanned %s professions.", key or ns.PlayerKey())
        end
        return
    end

    if cmd == "bags" then
        if ns.BagScan and ns.UI then
            local plan = ns.BagScan:BuildPlan()
            ns.UI:ShowMailPrompt(plan)
        end
        return
    end

    if cmd:match("^delay") then
        local n = tonumber(cmd:match("delay%s+([%d%.]+)"))
        if n and n >= 1 and n <= 30 then
            ns.db.settings.sendDelay = n
            ns.Print("Send delay set to %.1fs.", n)
        else
            ns.Print("Usage: /spostf delay 3")
        end
        return
    end

    if cmd == "reset" then
        local keepChars = ns.db.chars
        SnapPostForeverDB = ns.DeepCopy(ns.defaults)
        SnapPostForeverDB.chars = keepChars
        ns.db = SnapPostForeverDB
        ns.Print("Maps/settings reset (characters kept).")
        return
    end

    -- /spostf de me   or   /spostf de clear  (only the logged-in char may set/clear itself)
    if cmd == "de" or cmd == "defodder" or cmd:match("^de%s+") or cmd:match("^defodder%s+") then
        local arg = raw:match("^[Dd][Ee]%s+(.+)$") or raw:match("^[Dd][Ee][Ff][Oo][Dd][Dd][Ee][Rr]%s+(.+)$")
        if not arg or arg == "" then
            local who = ns.Mapper and ns.Mapper:GetDEFodderChar()
            if who then
                ns.Print("DE greens > |cffffffff%s|r  (only that character can change it: /spostf de me | clear)", who)
            else
                ns.Print("No DE recipient. /spostf de me (or the mapper DE greens button) on your enchanter.")
            end
            return
        end
        arg = arg:match("^%s*(.-)%s*$")
        local argLower = arg:lower()
        if argLower == "me" then
            arg = ns.PlayerKey()
        end
        local clearing = argLower == "clear" or argLower == "none" or argLower == "off"
        local ok, owner = ns.Mapper:SetDEFodderChar(not clearing and arg or nil)
        if not ok then
            ns.Mapper:ExplainDenied(owner)
        elseif clearing then
            ns.Print("Cleared green DE fodder recipient.")
        else
            ns.Print("Low-value green gear > |cffffffff%s|r", arg)
        end
        return
    end

    -- /spostf setmail … (preserve case for names)
    local setKey, setMail = raw:match("^[Ss][Ee][Tt][Mm][Aa][Ii][Ll]%s+(.+)%s+%-%s+(.+)$")
    if not setKey then
        setKey, setMail = raw:match("^[Ss][Ee][Tt][Mm][Aa][Ii][Ll]%s+(%S+)%s+(.+)$")
    end
    if setKey and setMail then
        setKey = setKey:match("^%s*(.-)%s*$")
        setMail = setMail:match("^%s*(.-)%s*$")
        ns.db.chars[setKey] = ns.db.chars[setKey]
            or { name = setMail, realm = setKey:match("-([^-]+)$") or "", professions = {} }
        ns.db.chars[setKey].mailName = setMail
        ns.db.chars[setKey].name = setMail
        local first, surname = setMail:match("^(%S+)%s+(.+)$")
        if first and surname then
            ns.db.chars[setKey].firstName = first
            ns.db.chars[setKey].surname = surname
        end
        ns.Print("Mail To for %s set to |cffffffff%s|r", setKey, setMail)
        return
    end

    if cmd:match("^setmail") then
        ns.Print("Usage: /spostf setmail <Char-Realm> <First Last>")
        ns.Print("Example: /spostf setmail Grina Dartfall-ClassicBetaPvE - Grina Dartfall")
        return
    end

    ns.Print(
        "Commands: /spostf | options | minimap | scan | bags | de me|clear"
            .. " | delay <sec> | setmail <Char-Realm> <First Last> | reset"
    )
end
