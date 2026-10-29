local _, ns = ...

-- Forever: classic-era content only.
ns.ExpansionsByFlavor = {
    forever = {
        { key = "Classic", label = "WoW Forever (Classic)", order = 1 },
    },
    era = {
        { key = "Classic", label = "Classic Era", order = 1 },
    },
    mainline = {
        { key = "Classic",  label = "Classic",           order = 1 },
        { key = "TBC",      label = "The Burning Crusade", order = 2 },
        { key = "WotLK",    label = "Wrath of the Lich King", order = 3 },
        { key = "Cata",     label = "Cataclysm",         order = 4 },
        { key = "MoP",      label = "Mists of Pandaria", order = 5 },
        { key = "WoD",      label = "Warlords of Draenor", order = 6 },
        { key = "Legion",   label = "Legion",            order = 7 },
        { key = "BfA",      label = "Battle for Azeroth", order = 8 },
        { key = "SL",       label = "Shadowlands",       order = 9 },
        { key = "DF",       label = "Dragonflight",      order = 10 },
        { key = "TWW",      label = "The War Within",    order = 11 },
        { key = "Midnight", label = "Midnight",          order = 12 },
    },
}

if ns.ApplyClientFlavor then
    ns.ApplyClientFlavor()
end
