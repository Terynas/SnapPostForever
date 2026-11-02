local addonName, ns = ...

ns.addonName = addonName
ns.version = "0.2.23"
ns.PRINT_PREFIX = "|cffc9a227[SnapPost Forever]|r "

ns.Materials = ns.Materials or {}
ns.MaterialById = ns.MaterialById or {}

local frame = CreateFrame("Frame")
ns.eventFrame = frame

--- Forever (Camelot), Classic Era (vanilla) or Mainline/Midnight (standard).
--- Detect before Data/*.lua runs. Era shares Forever's vanilla data packs but
--- keeps realm-style names (no surnames).
local function DetectClientFlavor()
    local iface = select(4, GetBuildInfo())
    ns.isForever, ns.isEra = false, false
    if WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
        ns.isForever = true
    elseif WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        ns.isEra = true
    elseif WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        ns.isForever = false
    elseif type(iface) == "number" then
        ns.isForever = iface > 16000 and iface < 20000
        ns.isEra = iface > 11000 and iface < 20000 and not ns.isForever
    end
    ns.usesVanillaData = ns.isForever or ns.isEra
    ns.isMainline = not ns.usesVanillaData
    ns.clientFlavor = (ns.isForever and "forever") or (ns.isEra and "era") or "mainline"
end

DetectClientFlavor()

function ns.ApplyClientFlavor()
    local key = ns.clientFlavor
    local expansions = ns.ExpansionsByFlavor and ns.ExpansionsByFlavor[key]
    local professions = ns.ProfessionsByFlavor and ns.ProfessionsByFlavor[key]
    if expansions then
        ns.Expansions = expansions
        ns.ExpansionLabel = {}
        for _, e in ipairs(expansions) do
            ns.ExpansionLabel[e.key] = e.label
        end
    end
    if professions then
        ns.Professions = professions
        ns.ProfessionLabel = {}
        ns.ProfessionNameToKey = {}
        for _, p in ipairs(professions) do
            ns.ProfessionLabel[p.key] = p.label
            ns.ProfessionNameToKey[p.label] = p.key
        end
    end
end

function ns.Print(...)
    print(ns.PRINT_PREFIX .. string.format(...))
end

--- Progress lines while mailing (can be turned off in Options). Errors still use ns.Print.
function ns.PrintMailProgress(...)
    if ns.db and ns.db.settings and ns.db.settings.chatMailProgress == false then
        return
    end
    ns.Print(...)
end

function ns.SafeString(value, fallback)
    if value == nil then
        return fallback or "?"
    end
    if type(issecretvalue) == "function" and issecretvalue(value) then
        return fallback or "?"
    end
    return tostring(value)
end

--- Forever: first + surname (UnitName's 2nd return is surname, not realm).
function ns.SurnameSeparator()
    local consts = Constants and Constants.CharacterNameSeparatorConsts
    if consts and consts.CHARACTERNAME_SURNAME_SEPARATOR then
        return consts.CHARACTERNAME_SURNAME_SEPARATOR
    end
    return " "
end

function ns.HasRegionalUniqueNames()
    return type(RegionalUniqueNamesEnabled) == "function" and RegionalUniqueNamesEnabled()
end

function ns.UsesSurnameNames()
    return ns.isForever or ns.HasRegionalUniqueNames()
end

--- Returns firstName, surname for a unit.
--- On Forever, UnitName / UnitNameUnmodified return (first, surname) — not (name, realm).
function ns.GetUnitNameParts(unit)
    unit = unit or "player"
    local first, second
    if UnitNameUnmodified then
        first, second = UnitNameUnmodified(unit)
    else
        first, second = UnitName(unit)
    end
    first = ns.SafeString(first, nil)
    if not first or first == "?" then
        first = ns.SafeString(UnitName(unit), "Player")
    end

    if not ns.UsesSurnameNames() then
        return first, nil
    end

    local surname
    if second and second ~= "" and not (type(issecretvalue) == "function" and issecretvalue(second)) then
        -- Forever Camelot NameUtil treats the 2nd return as surname (realm comes from GetRealmName).
        surname = tostring(second)
    end
    -- Some APIs already glue first+surname into the first return.
    if (not surname or surname == "") and NameUtil and NameUtil.SplitPlayerNameIntoParts then
        local a, b = NameUtil.SplitPlayerNameIntoParts(first)
        if a and b and b ~= "" then
            first, surname = a, b
        end
    elseif (not surname or surname == "") then
        local sep = ns.SurnameSeparator()
        if sep == " " then
            local a, b = string.match(first, "^(%S+)%s+(.+)$")
            if a and b and b ~= "" then
                first, surname = a, b
            end
        elseif sep and sep ~= "" and sep ~= "-" then
            local pos = string.find(first, sep, 1, true)
            if pos and pos > 1 then
                first, surname = string.sub(first, 1, pos - 1), string.sub(first, pos + #sep)
            end
        end
    end

    return first, surname
end

function ns.ComposeFullName(firstName, surname)
    firstName = ns.SafeString(firstName, "Player")
    if not surname or surname == "" then
        return firstName
    end
    surname = ns.SafeString(surname, "")
    if surname == "" or surname == "?" then
        return firstName
    end
    if NameUtil and NameUtil.GetFullNameWithoutRealm then
        local composed = NameUtil.GetFullNameWithoutRealm(firstName, surname)
        if composed and composed ~= "" then
            return ns.SafeString(composed, firstName .. ns.SurnameSeparator() .. surname)
        end
    end
    return firstName .. ns.SurnameSeparator() .. surname
end

--- Full display / mail name: "First Last" on Forever; UnitName on Mainline.
function ns.PlayerFullName()
    local first, surname = ns.GetUnitNameParts("player")
    if ns.UsesSurnameNames() then
        return ns.ComposeFullName(first, surname), first, surname
    end
    return first, first, nil
end

function ns.CharKey(name, realm)
    if not name then
        name = select(1, ns.PlayerFullName())
    end
    realm = realm or GetNormalizedRealmName() or GetRealmName() or "Unknown"
    name = ns.SafeString(name, "Player")
    realm = ns.SafeString(realm, "Realm"):gsub("%s+", "")
    return name .. "-" .. realm
end

function ns.PlayerKey()
    return ns.CharKey()
end

--- Move a character entry + map values from oldKey → newKey (single-name → full-name).
function ns.MigrateCharKey(oldKey, newKey)
    if not oldKey or not newKey or oldKey == newKey or not ns.db then
        return false
    end
    local chars = ns.db.chars
    if chars and chars[oldKey] then
        if not chars[newKey] then
            chars[newKey] = chars[oldKey]
        else
            -- Prefer keeping professions from either side.
            local dest = chars[newKey]
            local src = chars[oldKey]
            if src.professions then
                dest.professions = dest.professions or {}
                for k, v in pairs(src.professions) do
                    if dest.professions[k] == nil then
                        dest.professions[k] = v
                    end
                end
            end
        end
        chars[oldKey] = nil
    end
    local maps = ns.db.maps
    if maps then
        for _, bucket in pairs(maps) do
            if type(bucket) == "table" then
                for k, v in pairs(bucket) do
                    if v == oldKey then
                        bucket[k] = newKey
                    end
                end
            end
        end
    end
    local prio = ns.db.claimPriority
    if prio and prio[oldKey] then
        prio[newKey] = prio[newKey] or prio[oldKey]
        prio[oldKey] = nil
    end
    return true
end

function ns.DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    local out = {}
    for k, v in pairs(src) do
        out[k] = ns.DeepCopy(v)
    end
    return out
end

local function MergeDefaults(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            MergeDefaults(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

--- Normalize profession / professions[] on a material entry.
function ns.NormalizeMaterialEntry(entry)
    if not entry then
        return entry
    end
    local set = {}
    if type(entry.professions) == "table" then
        for _, p in ipairs(entry.professions) do
            if type(p) == "string" and p ~= "" then
                set[p] = true
            end
        end
        -- Also accept dictionary-style { Blacksmithing = true }
        for k, v in pairs(entry.professions) do
            if type(k) == "string" and v then
                set[k] = true
            end
        end
    end
    if type(entry.profession) == "string" and entry.profession ~= "" then
        set[entry.profession] = true
    end
    local list = {}
    for p in pairs(set) do
        list[#list + 1] = p
    end
    table.sort(list)
    entry.professions = list
    if not entry.profession or entry.profession == "" then
        entry.profession = list[1]
    end
    return entry
end

function ns.MaterialProfessions(entry)
    if not entry then
        return {}
    end
    if type(entry.professions) == "table" and #entry.professions > 0 then
        return entry.professions
    end
    if entry.profession then
        return { entry.profession }
    end
    return {}
end

function ns.MaterialUsesProfession(entry, profKey)
    if not entry or not profKey then
        return false
    end
    for _, p in ipairs(ns.MaterialProfessions(entry)) do
        if p == profKey then
            return true
        end
    end
    return false
end

function ns.RebuildMaterialIndex()
    wipe(ns.MaterialById)
    for _, entry in ipairs(ns.Materials) do
        ns.NormalizeMaterialEntry(entry)
        if entry.itemId and entry.itemId > 0 and not entry.placeholder then
            ns.MaterialById[entry.itemId] = entry
        end
    end
end

--- Add professions seen in ProfessionMaster's live recipe scans to known mats.
--- Only extends existing entries; never adds new items. Returns the count added.
function ns.LearnUsesFromProfessionMaster()
    local pm = _G.ProfessionMasterDB
    local live = type(pm) == "table" and pm.liveRecipes
    if type(live) ~= "table" then
        return 0
    end
    local added = 0
    for _, recipe in pairs(live) do
        local prof = type(recipe) == "table" and recipe.profession
        if type(prof) == "string" and prof ~= "" and not recipe.gather and type(recipe.reagents) == "table" then
            for _, reagent in ipairs(recipe.reagents) do
                local entry = type(reagent) == "table" and ns.MaterialById[reagent[1]]
                if entry and not ns.MaterialUsesProfession(entry, prof) then
                    entry.professions[#entry.professions + 1] = prof
                    table.sort(entry.professions)
                    added = added + 1
                end
            end
        end
    end
    return added
end

--- pack: "forever" (vanilla mats, Forever + Classic Era) | "mainline" — skip registration on the other client.
function ns.RegisterMaterials(list, pack)
    if pack == "forever" and not ns.usesVanillaData then
        return
    end
    if pack == "mainline" and not ns.isMainline then
        return
    end
    for i = 1, #list do
        local entry = list[i]
        if entry and entry.itemId and entry.itemId > 0 and not entry.placeholder then
            ns.NormalizeMaterialEntry(entry)
            ns.Materials[#ns.Materials + 1] = entry
        end
    end
end

function frame:ADDON_LOADED(loaded)
    if loaded ~= addonName then
        return
    end
    ns.ApplyClientFlavor()
    SnapPostForeverDB = SnapPostForeverDB or {}
    MergeDefaults(SnapPostForeverDB, ns.defaults)
    ns.db = SnapPostForeverDB
    ns.RebuildMaterialIndex()
    self:UnregisterEvent("ADDON_LOADED")
    if ns.Options then
        ns.Options:Register()
    end
    -- Keep minimap.hide in sync with settings.showMinimap for older SavedVariables.
    if ns.db.settings and ns.db.settings.showMinimap == false then
        ns.db.minimap = ns.db.minimap or {}
        ns.db.minimap.hide = true
    end
    local flavorLabel = (ns.isForever and "WoW Forever") or (ns.isEra and "Classic Era") or "Midnight / Mainline"
    ns.Print(
        "v%s loaded for %s (%d mats). |cffffffff/spostf|r mapper · |cffffffff/spostf options|r.",
        ns.version,
        flavorLabel,
        ns.MaterialById and (function()
            local n = 0
            for _ in pairs(ns.MaterialById) do
                n = n + 1
            end
            return n
        end)() or 0
    )
end

function frame:PLAYER_LOGIN()
    ns.LearnUsesFromProfessionMaster()
    if ns.CharDB then
        ns.CharDB:ScanPlayer()
    end
    if ns.MinimapButton then
        ns.MinimapButton:Refresh()
    end
end

function frame:SKILL_LINES_CHANGED()
    if ns.CharDB then
        ns.CharDB:ScanPlayer()
    end
end

function frame:MAIL_SHOW()
    if ns.UI then
        ns.UI:EnsureMailFrameHooks()
    end
    if ns.db and ns.db.settings and ns.db.settings.autoPrompt == false then
        return
    end
    if ns.BagScan and ns.UI then
        C_Timer.After(0.35, function()
            if not ns.UI:IsMailboxOpen() then
                return
            end
            local plan = ns.BagScan:BuildPlan()
            if plan and plan.totalStacks > 0 then
                ns.UI:ShowMailPrompt(plan)
            end
        end)
    end
end

function frame:MAIL_CLOSED()
    if ns.UI then
        ns.UI:HideMailPrompt("Mailbox closed")
    elseif ns.MailQueue then
        ns.MailQueue:Cancel("Mailbox closed")
    end
end

function frame:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(interactionType)
    if Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.MailInfo
        and interactionType == Enum.PlayerInteractionType.MailInfo then
        if ns.UI then
            ns.UI:HideMailPrompt("Mailbox closed")
        elseif ns.MailQueue then
            ns.MailQueue:Cancel("Mailbox closed")
        end
    end
end

function frame:MAIL_SEND_SUCCESS()
    if ns.MailQueue then
        ns.MailQueue:OnSendSuccess()
    end
end

function frame:MAIL_FAILED()
    if ns.MailQueue then
        ns.MailQueue:OnSendFailed()
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("MAIL_SEND_SUCCESS")
frame:RegisterEvent("MAIL_FAILED")
if C_PlayerInteractionManager then
    frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
end
