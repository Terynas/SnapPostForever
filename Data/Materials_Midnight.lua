local _, ns = ...

-- Midnight (The War Within follow-up) gathering + craft reagents.
-- Item IDs pulled from Wowhead (2026-10); refresh via scripts/import_midnight_materials.py.

local function M(itemId, name, profession, extra)
    local e = {
        itemId = itemId,
        name = name,
        expansion = "Midnight",
        profession = profession,
        baseName = name,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            e[k] = v
        end
    end
    return e
end

ns.RegisterMaterials({
    -- Herbs
    M(236780, "Nocturnal Lotus", "Herbalism"),
    M(236774, "Azeroot", "Herbalism"),
    M(236770, "Sanguithorn", "Herbalism"),
    M(236778, "Mana Lily", "Herbalism"),
    M(236776, "Argentleaf", "Herbalism"),
    M(236761, "Tranquility Bloom", "Herbalism"),

    -- Ores / metals
    M(237359, "Refulgent Copper Ore", "Mining"),
    M(237364, "Brilliant Silver Ore", "Mining"),
    M(237362, "Umbral Tin Ore", "Mining"),
    M(237366, "Dazzling Thorium", "Mining"),
    M(238198, "Refulgent Copper Ingot", "Blacksmithing", { professions = { "Blacksmithing", "Engineering", "Jewelcrafting" } }),
    M(238202, "Gloaming Alloy", "Blacksmithing"),
    M(238204, "Sterling Alloy", "Blacksmithing"),
    M(243060, "Luminant Flux", "Blacksmithing"),
    M(251283, "Tormented Tantalum", "Blacksmithing"),

    -- Patch 12.1 gathering specials
    M(274777, "Neutralized Venom Clot", "Herbalism", { professions = { "Herbalism", "Mining" } }),
    M(274781, "Cursebound Globe", "Mining", { professions = { "Herbalism", "Mining" } }),

    -- Cloth / bolts
    M(236963, "Bright Linen", "Tailoring"),
    M(239700, "Bright Linen Bolt", "Tailoring"),
    M(239702, "Imbued Bright Linen Bolt", "Tailoring"),
    M(237015, "Sunfire Silk", "Tailoring"),
    M(239201, "Sunfire Silk Bolt", "Tailoring"),
    M(240158, "Arcanoweave", "Tailoring"),
    M(239198, "Arcanoweave Bolt", "Tailoring"),
    M(251665, "Silverleaf Thread", "Tailoring"),
    M(251691, "Embroidery Floss", "Tailoring"),

    -- Leather / hide
    M(244632, "Scalewoven Hide", "Leatherworking", { professions = { "Leatherworking", "Skinning" } }),
    M(244633, "Infused Scalewoven Hide", "Leatherworking"),
    M(238511, "Void-Tempered Leather", "Leatherworking"),
    M(238518, "Void-Tempered Hide", "Leatherworking"),
    M(238513, "Void-Tempered Scales", "Leatherworking"),
    M(238520, "Void-Tempered Plating", "Blacksmithing", { professions = { "Blacksmithing", "Leatherworking" } }),
    M(238529, "Majestic Hide", "Skinning", { professions = { "Skinning", "Leatherworking" } }),
    M(238528, "Majestic Claw", "Skinning"),
    M(238525, "Fantastic Fur", "Skinning"),

    -- Enchanting
    M(243599, "Eversinging Dust", "Enchanting"),
    M(243602, "Radiant Shard", "Enchanting"),
    M(243605, "Dawn Crystal", "Enchanting"),
    M(244749, "Aetherlume", "Enchanting"),
    M(243581, "Evercore", "Enchanting"),

    -- Inscription
    M(245803, "Argentleaf Pigment", "Inscription"),
    M(245865, "Sanguithorn Pigment", "Inscription"),
    M(245867, "Mana Lily Pigment", "Inscription"),
    M(245801, "Munsell Ink", "Inscription"),
    M(245805, "Sienna Ink", "Inscription"),
    M(245807, "Powder Pigment", "Inscription"),
    M(245881, "Lexicologist's Vellum", "Inscription"),
    M(245766, "Soul Cipher", "Inscription"),

    -- Jewelcrafting
    M(242554, "Amani Lapis", "Jewelcrafting"),
    M(242607, "Harandar Peridot", "Jewelcrafting"),
    M(242553, "Sanguine Garnet", "Jewelcrafting"),
    M(242606, "Tenebrous Amethyst", "Jewelcrafting"),
    M(242608, "Eversong Diamond", "Jewelcrafting"),
    M(242620, "Glimmering Gemdust", "Jewelcrafting"),
    M(242787, "Crystalline Glass", "Jewelcrafting"),
    M(253307, "Infused Heliotrope", "Jewelcrafting"),

    -- Alchemy / shared
    M(240991, "Sunglass Vial", "Alchemy"),
    M(247811, "Oil of Heartwood", "Alchemy"),
    M(256963, "Thalassian Lumber", "Engineering", { professions = { "Engineering", "Blacksmithing", "Inscription" } }),
    M(244637, "Silvermoon Weapon Wrap", "Blacksmithing"),

    -- Motes / rare
    M(236949, "Mote of Light", "Enchanting", { professions = { "Enchanting", "Jewelcrafting", "Inscription" } }),
    M(236950, "Mote of Primal Energy", "Alchemy", { professions = { "Alchemy", "Enchanting" } }),
    M(236951, "Mote of Wild Magic", "Enchanting"),
    M(236952, "Mote of Pure Void", "Enchanting", { professions = { "Enchanting", "Jewelcrafting", "Blacksmithing" } }),
}, "mainline")
