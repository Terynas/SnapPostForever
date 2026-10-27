local _, ns = ...

ns.Mapper = ns.Mapper or {}
local Mapper = ns.Mapper

local function Blank(v)
    return v == nil or v == ""
end

--- True when the logged-in character may manage routing for charKey (only itself).
function Mapper:CanEditChar(charKey)
    return charKey ~= nil and charKey == ns.PlayerKey()
end

--- Each character owns its own routing: it may claim an unowned slot (or one whose
--- owner no longer exists) for itself, and release only its own claims.
--- Returns ok, ownerKey (the blocking owner when refused).
function Mapper:CanChangeMap(currentOwner, newOwner)
    local me = ns.PlayerKey()
    if Blank(newOwner) then
        return Blank(currentOwner) or currentOwner == me, currentOwner
    end
    if newOwner ~= me then
        return false, newOwner
    end
    if Blank(currentOwner) or currentOwner == me then
        return true
    end
    local chars = ns.db and ns.db.chars
    if not (chars and chars[currentOwner]) then
        return true
    end
    return false, currentOwner
end

function Mapper:ExplainDenied(ownerKey)
    if ownerKey and ownerKey ~= "" then
        ns.Print("Only %s can change that — log in on that character.", ownerKey)
    else
        ns.Print("Only the logged-in character can change its own routing.")
    end
end

local function Assign(tbl, key, charKey)
    local ok, owner = Mapper:CanChangeMap(tbl[key], charKey)
    if not ok then
        return false, owner
    end
    tbl[key] = (not Blank(charKey)) and charKey or nil
    return true
end

function Mapper:SetItemMap(itemId, charKey)
    if not itemId or itemId <= 0 then
        return false
    end
    return Assign(ns.db.maps.byItem, itemId, charKey)
end

function Mapper:SetProfessionMap(profKey, charKey)
    if not profKey then
        return false
    end
    return Assign(ns.db.maps.byProfession, profKey, charKey)
end

function Mapper:SetExpansionProfessionMap(expansion, profKey, charKey)
    if not expansion or not profKey then
        return false
    end
    return Assign(ns.db.maps.byExpansionProfession, expansion .. ":" .. profKey, charKey)
end

function Mapper:GetItemMap(itemId)
    return ns.db.maps.byItem[itemId]
end

-- Claim priority ------------------------------------------------------------
-- When a mat is used by several mapped professions owned by different characters,
-- the highest-priority claim wins. Each character sets priority for its own
-- professions only.

Mapper.PRIORITY_HIGH, Mapper.PRIORITY_NORMAL, Mapper.PRIORITY_LOW = 3, 2, 1
Mapper.PRIORITY_LABEL = { [3] = "high", [2] = "normal", [1] = "low" }

local function PriorityTable()
    ns.db.claimPriority = ns.db.claimPriority or {}
    return ns.db.claimPriority
end

function Mapper:GetPriority(charKey, profKey)
    local byChar = charKey and PriorityTable()[charKey]
    return byChar and byChar[profKey] or self.PRIORITY_NORMAL
end

function Mapper:SetPriority(charKey, profKey, level)
    if not profKey or not self:CanEditChar(charKey) then
        return false, charKey
    end
    local all = PriorityTable()
    local byChar = all[charKey] or {}
    byChar[profKey] = (level ~= self.PRIORITY_NORMAL) and level or nil
    all[charKey] = next(byChar) and byChar or nil
    return true
end

--- Normal → High → Low → Normal.
function Mapper:CyclePriority(charKey, profKey)
    local cur = self:GetPriority(charKey, profKey)
    local nextLevel = (cur == self.PRIORITY_NORMAL and self.PRIORITY_HIGH)
        or (cur == self.PRIORITY_HIGH and self.PRIORITY_LOW)
        or self.PRIORITY_NORMAL
    local ok, owner = self:SetPriority(charKey, profKey, nextLevel)
    return ok and nextLevel or nil, owner
end

local SPECIFICITY = { expansion = 2, profession = 1 }

--- Every character claiming this mat through a profession map, best claim first:
--- { charKey, prof, reason = "expansion"|"profession", priority }, one per character.
function Mapper:Claims(entry)
    local out = {}
    if not entry then
        return out
    end
    local maps = ns.db.maps
    local expansion = entry.expansion or "?"
    local best = {}
    for order, prof in ipairs(ns.MaterialProfessions(entry)) do
        local candidates = {
            { maps.byExpansionProfession[expansion .. ":" .. prof], "expansion" },
            { maps.byProfession[prof], "profession" },
        }
        for _, c in ipairs(candidates) do
            local charKey, reason = c[1], c[2]
            if not Blank(charKey) then
                local claim = {
                    charKey = charKey,
                    prof = prof,
                    reason = reason,
                    priority = self:GetPriority(charKey, prof),
                    order = order,
                }
                local prev = best[charKey]
                if not prev or Mapper.ClaimBeats(claim, prev) then
                    best[charKey] = claim
                end
            end
        end
    end
    for _, claim in pairs(best) do
        out[#out + 1] = claim
    end
    table.sort(out, Mapper.ClaimBeats)
    return out
end

function Mapper.ClaimBeats(a, b)
    if a.priority ~= b.priority then
        return a.priority > b.priority
    end
    if a.reason ~= b.reason then
        return SPECIFICITY[a.reason] > SPECIFICITY[b.reason]
    end
    if a.order ~= b.order then
        return a.order < b.order
    end
    return a.charKey < b.charKey
end

--- Contested mat: more than one character claims it.
--- Returns claims (winner first), itemOverride, tie (winner decided only by catalog order).
function Mapper:Conflict(entry)
    local claims = self:Claims(entry)
    if #claims < 2 then
        return nil
    end
    local a, b = claims[1], claims[2]
    local tie = a.priority == b.priority and a.reason == b.reason
    return claims, entry.itemId and ns.db.maps.byItem[entry.itemId], tie
end

function Mapper:ResolveRecipient(entry)
    if not entry then
        return nil, "unknown"
    end
    if entry.itemId and entry.itemId > 0 and ns.db.maps.byItem[entry.itemId] then
        return ns.db.maps.byItem[entry.itemId], "item"
    end

    local winner = self:Claims(entry)[1]
    if winner then
        return winner.charKey, winner.reason
    end

    if not ns.db.settings.onlyMapped then
        local suggested = ns.CharDB:SuggestCharForMaterial(entry)
        if suggested then
            return suggested, "auto"
        end
    end
    return nil, "none"
end

function Mapper:SetDEFodderChar(charKey)
    if not (ns.db and ns.db.maps) then
        return false
    end
    local ok, owner = self:CanChangeMap(self:GetDEFodderChar(), charKey)
    if not ok then
        return false, owner
    end
    if ns.DEFodder then
        ns.DEFodder:SetRecipient(charKey)
    else
        ns.db.maps.deFodderChar = (not Blank(charKey)) and charKey or nil
    end
    return true
end

function Mapper:GetDEFodderChar()
    if ns.DEFodder then
        return ns.DEFodder:GetRecipient()
    end
    return ns.db and ns.db.maps and ns.db.maps.deFodderChar
end

--- Claim every unmapped profession the logged-in character knows.
function Mapper:AutoMapOwnProfessions()
    local me = ns.PlayerKey()
    local info = ns.CharDB:Get(me)
    local mapped = 0
    if not (info and info.professions) then
        return mapped
    end
    for _, p in ipairs(ns.Professions or {}) do
        local skill = info.professions[p.key]
        if type(skill) == "number" and skill > 0 and Blank(ns.db.maps.byProfession[p.key]) then
            if self:SetProfessionMap(p.key, me) then
                mapped = mapped + 1
            end
        end
    end
    return mapped
end

function Mapper:ListMappedSummary()
    local summary = {}
    for itemId, charKey in pairs(ns.db.maps.byItem) do
        summary[#summary + 1] = { kind = "item", id = itemId, charKey = charKey }
    end
    for profKey, charKey in pairs(ns.db.maps.byProfession) do
        summary[#summary + 1] = { kind = "profession", id = profKey, charKey = charKey }
    end
    for expProf, charKey in pairs(ns.db.maps.byExpansionProfession) do
        summary[#summary + 1] = { kind = "expansion", id = expProf, charKey = charKey }
    end
    table.sort(summary, function(a, b)
        if a.kind == b.kind then
            return tostring(a.id) < tostring(b.id)
        end
        return a.kind < b.kind
    end)
    return summary
end
