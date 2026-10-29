local _, ns = ...

ns.CharDB = ns.CharDB or {}
local CharDB = ns.CharDB

local function ResolveProfessionKey(skillName)
    if not skillName then
        return nil
    end
    if type(issecretvalue) == "function" and issecretvalue(skillName) then
        return nil
    end
    local direct = ns.ProfessionNameToKey[skillName]
    if direct then
        return direct
    end
    local lower = string.lower(tostring(skillName))
    local aliases = ns.ProfessionAliases or {}
    if aliases[lower] then
        return aliases[lower]
    end
    local bestKey, bestLen
    for alias, key in pairs(aliases) do
        if lower:find(alias, 1, true) then
            local len = #alias
            if not bestLen or len > bestLen then
                bestLen = len
                bestKey = key
            end
        end
    end
    return bestKey
end

local function AddProfession(professions, name, rank)
    local profKey = ResolveProfessionKey(name)
    if not profKey then
        return
    end
    local skill = rank or 1
    if type(issecretvalue) == "function" and issecretvalue(skill) then
        skill = 1
    end
    professions[profKey] = skill
end

local function ScanViaGetProfessions(professions)
    if not GetProfessions or not GetProfessionInfo then
        return false
    end
    local indices = { GetProfessions() }
    local found = false
    for i = 1, #indices do
        local idx = indices[i]
        if idx then
            local skillName, _, skillRank = GetProfessionInfo(idx)
            if skillName then
                AddProfession(professions, skillName, skillRank)
                found = true
            end
        end
    end
    return found
end

local function ScanViaTradeSkillUI(professions)
    if not C_TradeSkillUI then
        return false
    end
    local found = false

    -- Preferred modern path
    if C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if type(lines) == "table" then
            for i = 1, #lines do
                local skillLineID = lines[i]
                if skillLineID and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
                    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                    if info then
                        local name = info.parentProfessionName or info.professionName
                        local rank = info.skillLevel
                        -- skillLevel 0 (or missing) means the line exists in the catalog
                        -- but this character has not learned it. Without this check, a
                        -- character with no professions was marked as knowing every one.
                        if name and type(rank) == "number" and rank > 0 then
                            AddProfession(professions, name, rank)
                            found = true
                        end
                    end
                end
            end
        end
    end

    -- Fallback: player's learned professions enum helpers when available
    if not found and C_TradeSkillUI.GetProfessionSkillLineID and Enum and Enum.Profession then
        for _, enumVal in pairs(Enum.Profession) do
            if type(enumVal) == "number" then
                local skillLineID = C_TradeSkillUI.GetProfessionSkillLineID(enumVal)
                if skillLineID and skillLineID > 0 and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
                    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                    if info and info.skillLevel and info.skillLevel > 0 then
                        local name = info.parentProfessionName or info.professionName
                        if name then
                            AddProfession(professions, name, info.skillLevel)
                            found = true
                        end
                    end
                end
            end
        end
    end

    return found
end

--- Classic Era (and Forever's classic skill tab): professions are plain skill lines.
--- Lines under a collapsed Skills header are not returned; the last good scan is kept.
local function ScanViaSkillLines(professions)
    local getNum = (C_SkillInfo and C_SkillInfo.GetNumSkillLines) or GetNumSkillLines
    local getInfo = (C_SkillInfo and C_SkillInfo.GetSkillLineInfo) or GetSkillLineInfo
    if type(getNum) ~= "function" or type(getInfo) ~= "function" then
        return false
    end
    local n = getNum()
    if type(n) ~= "number" or n <= 0 then
        return false
    end
    local found = false
    for i = 1, n do
        local name, isHeader, _, rank = getInfo(i)
        if type(name) == "table" then
            local info = name
            isHeader = info.header or info.isHeader
            name = info.name or info.skillName
            rank = info.rank or info.skillRank or info.skillLevel
        end
        if name and not isHeader and ResolveProfessionKey(name) then
            AddProfession(professions, name, rank)
            found = true
        end
    end
    return found
end

function CharDB:ScanPlayer()
    local fullName, firstName, surname = ns.PlayerFullName()
    local realm = GetNormalizedRealmName() or GetRealmName()
    local key = ns.CharKey(fullName, realm)
    local _, classFile = UnitClass("player")
    local faction = UnitFactionGroup("player")

    -- Migrate pre-surname keys (First-Realm → "First Last"-Realm) on Forever only.
    if ns.UsesSurnameNames and ns.UsesSurnameNames() and firstName and firstName ~= fullName then
        local legacyKey = ns.CharKey(firstName, realm)
        if legacyKey ~= key then
            ns.MigrateCharKey(legacyKey, key)
        end
    end

    -- Forever mail To: full first + surname; Mainline: character name (realm appended later if needed).
    local mailName = fullName

    local professions = {}
    if not ScanViaGetProfessions(professions) and not ScanViaTradeSkillUI(professions) then
        ScanViaSkillLines(professions)
    end

    local prev = ns.db.chars[key]
    if prev and prev.professions and next(professions) == nil then
        -- Keep last good profession scan if this pass found nothing.
        professions = prev.professions
    end

    ns.db.chars[key] = {
        name = fullName,
        firstName = firstName,
        surname = surname,
        mailName = mailName,
        realm = ns.SafeString(realm, "Realm"):gsub("%s+", ""),
        class = classFile,
        faction = faction,
        professions = professions,
        lastSeen = time(),
        client = ns.clientFlavor or (ns.isForever and "forever" or "mainline"),
    }

    return key, ns.db.chars[key]
end

function CharDB:Get(key)
    return ns.db.chars[key]
end

function CharDB:List()
    local list = {}
    for key, info in pairs(ns.db.chars) do
        list[#list + 1] = { key = key, info = info }
    end
    table.sort(list, function(a, b)
        return a.key < b.key
    end)
    return list
end

function CharDB:CharsWithProfession(profKey)
    local out = {}
    for key, info in pairs(ns.db.chars) do
        if info.professions and info.professions[profKey] then
            out[#out + 1] = { key = key, info = info, skill = info.professions[profKey] }
        end
    end
    table.sort(out, function(a, b)
        return (a.skill or 0) > (b.skill or 0)
    end)
    return out
end

function CharDB:SuggestCharForMaterial(entry)
    if not entry then
        return nil
    end
    local maps = ns.db.maps
    if maps.byItem[entry.itemId] then
        return maps.byItem[entry.itemId]
    end
    local profs = ns.MaterialProfessions(entry)
    local expansion = entry.expansion or "?"
    for _, prof in ipairs(profs) do
        local expProf = expansion .. ":" .. prof
        if maps.byExpansionProfession[expProf] then
            return maps.byExpansionProfession[expProf]
        end
    end
    for _, prof in ipairs(profs) do
        if maps.byProfession[prof] then
            return maps.byProfession[prof]
        end
    end
    for _, prof in ipairs(profs) do
        local cands = self:CharsWithProfession(prof)
        if cands[1] then
            return cands[1].key
        end
    end
    return nil
end
