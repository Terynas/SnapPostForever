local _, ns = ...

-- Forever: Vanilla set (First Aid, no JC / Inscription).
ns.ProfessionsByFlavor = {
    forever = {
        { key = "Alchemy",        label = "Alchemy",         kind = "craft" },
        { key = "Blacksmithing",  label = "Blacksmithing",   kind = "craft" },
        { key = "Enchanting",     label = "Enchanting",      kind = "craft" },
        { key = "Engineering",    label = "Engineering",     kind = "craft" },
        { key = "Leatherworking", label = "Leatherworking",  kind = "craft" },
        { key = "Tailoring",      label = "Tailoring",       kind = "craft" },
        { key = "Herbalism",      label = "Herbalism",       kind = "gather" },
        { key = "Mining",         label = "Mining",          kind = "gather" },
        { key = "Skinning",       label = "Skinning",        kind = "gather" },
        { key = "Cooking",        label = "Cooking",         kind = "secondary" },
        { key = "Fishing",        label = "Fishing",         kind = "secondary" },
        { key = "First Aid",      label = "First Aid",       kind = "secondary" },
    },
    mainline = {
        { key = "Alchemy",        label = "Alchemy",         kind = "craft" },
        { key = "Blacksmithing",  label = "Blacksmithing",   kind = "craft" },
        { key = "Enchanting",     label = "Enchanting",      kind = "craft" },
        { key = "Engineering",    label = "Engineering",     kind = "craft" },
        { key = "Inscription",    label = "Inscription",     kind = "craft" },
        { key = "Jewelcrafting",  label = "Jewelcrafting",   kind = "craft" },
        { key = "Leatherworking", label = "Leatherworking",  kind = "craft" },
        { key = "Tailoring",      label = "Tailoring",       kind = "craft" },
        { key = "Herbalism",      label = "Herbalism",       kind = "gather" },
        { key = "Mining",         label = "Mining",          kind = "gather" },
        { key = "Skinning",       label = "Skinning",        kind = "gather" },
        { key = "Cooking",        label = "Cooking",         kind = "secondary" },
        { key = "Fishing",        label = "Fishing",         kind = "secondary" },
    },
}

ns.ProfessionAliases = {
    alchemy = "Alchemy",
    blacksmithing = "Blacksmithing",
    enchanting = "Enchanting",
    engineering = "Engineering",
    inscription = "Inscription",
    jewelcrafting = "Jewelcrafting",
    leatherworking = "Leatherworking",
    tailoring = "Tailoring",
    herbalism = "Herbalism",
    mining = "Mining",
    skinning = "Skinning",
    cooking = "Cooking",
    fishing = "Fishing",
    ["first aid"] = "First Aid",
    firstaid = "First Aid",
}

if ns.ApplyClientFlavor then
    ns.ApplyClientFlavor()
end
