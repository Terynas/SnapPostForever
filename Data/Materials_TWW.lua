local _, ns = ...

-- The War Within gathering + core craft reagents (quality tiers where known).

local function Q(itemId, name, profession, quality, extraProfs)
    local professions = { profession }
    if extraProfs then
        for i = 1, #extraProfs do
            professions[#professions + 1] = extraProfs[i]
        end
    end
    return {
        itemId = itemId,
        name = quality and (name .. " (Q" .. quality .. ")") or name,
        expansion = "TWW",
        profession = profession,
        professions = professions,
        quality = quality,
        baseName = name,
    }
end

ns.RegisterMaterials({
    -- Herbs
    Q(210796, "Mycobloom", "Herbalism", 1),
    Q(210797, "Mycobloom", "Herbalism", 2),
    Q(210798, "Mycobloom", "Herbalism", 3),
    Q(210799, "Luredrop", "Herbalism", 1),
    Q(210800, "Luredrop", "Herbalism", 2),
    Q(210801, "Luredrop", "Herbalism", 3),
    Q(210802, "Orbinid", "Herbalism", 1),
    Q(210803, "Orbinid", "Herbalism", 2),
    Q(210804, "Orbinid", "Herbalism", 3),
    Q(210805, "Blessing Blossom", "Herbalism", 1),
    Q(210806, "Blessing Blossom", "Herbalism", 2),
    Q(210807, "Blessing Blossom", "Herbalism", 3),
    Q(210808, "Arathor's Spear", "Herbalism", 1),
    Q(210809, "Arathor's Spear", "Herbalism", 2),
    Q(210810, "Arathor's Spear", "Herbalism", 3),

    -- Ores (also consumed by Blacksmithing alloys)
    Q(210930, "Bismuth", "Mining", 1, { "Blacksmithing" }),
    Q(210931, "Bismuth", "Mining", 2, { "Blacksmithing" }),
    Q(210932, "Bismuth", "Mining", 3, { "Blacksmithing" }),
    Q(210933, "Aqirite", "Mining", 1, { "Blacksmithing" }),
    Q(210934, "Aqirite", "Mining", 2, { "Blacksmithing" }),
    Q(210935, "Aqirite", "Mining", 3, { "Blacksmithing" }),
    Q(210936, "Ironclaw Ore", "Mining", 1, { "Blacksmithing" }),
    Q(210937, "Ironclaw Ore", "Mining", 2, { "Blacksmithing" }),
    Q(210938, "Ironclaw Ore", "Mining", 3, { "Blacksmithing" }),
    { itemId = 210939, name = "Null Stone", expansion = "TWW", profession = "Mining", baseName = "Null Stone",
        professions = { "Mining", "Blacksmithing" } },
    { itemId = 213399, name = "Glittering Glass", expansion = "TWW", profession = "Mining", baseName = "Glittering Glass" },
    { itemId = 213610, name = "Crystalline Powder", expansion = "TWW", profession = "Mining", baseName = "Crystalline Powder" },

    -- Cloth
    { itemId = 224828, name = "Weavercloth", expansion = "TWW", profession = "Tailoring", baseName = "Weavercloth" },
    { itemId = 222804, name = "Duskweave", expansion = "TWW", profession = "Tailoring", baseName = "Duskweave" },
    { itemId = 222799, name = "Mosswool Thread", expansion = "TWW", profession = "Tailoring", baseName = "Mosswool Thread" },
    { itemId = 224832, name = "Weavercloth Bolt", expansion = "TWW", profession = "Tailoring", baseName = "Weavercloth Bolt" },
    { itemId = 228930, name = "Adorning Ribbon", expansion = "TWW", profession = "Tailoring", baseName = "Adorning Ribbon" },

    -- Leatherworking / skinning staples (quality variants)
    Q(212664, "Stormcharged Leather", "Leatherworking", 1),
    Q(212665, "Stormcharged Leather", "Leatherworking", 2),
    Q(212666, "Stormcharged Leather", "Leatherworking", 3),
    Q(212667, "Gloom Chitin", "Leatherworking", 1),
    Q(212668, "Gloom Chitin", "Leatherworking", 2),
    Q(212669, "Gloom Chitin", "Leatherworking", 3),
    Q(212670, "Thunderous Hide", "Leatherworking", 1),
    Q(212671, "Thunderous Hide", "Leatherworking", 2),
    Q(212672, "Thunderous Hide", "Leatherworking", 3),
    Q(212674, "Sunless Carapace", "Leatherworking", 1),
    Q(212675, "Sunless Carapace", "Leatherworking", 2),
    Q(212676, "Sunless Carapace", "Leatherworking", 3),
    { itemId = 219013, name = "Legendary Hides", expansion = "TWW", profession = "Skinning", baseName = "Legendary Hides" },

    -- Enchanting
    { itemId = 219946, name = "Storm Dust", expansion = "TWW", profession = "Enchanting", baseName = "Storm Dust" },
    { itemId = 219949, name = "Refulgent Crystal", expansion = "TWW", profession = "Enchanting", baseName = "Refulgent Crystal" },
    { itemId = 219952, name = "Gleaming Shard", expansion = "TWW", profession = "Enchanting", baseName = "Gleaming Shard" },

    -- Shared craft reagents
    { itemId = 210814, name = "Artisan's Acuity", expansion = "TWW", profession = "Alchemy", baseName = "Artisan's Acuity",
        professions = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Inscription", "Jewelcrafting",
            "Leatherworking", "Tailoring" } },
    { itemId = 221853, name = "Handful of Bismuth Bolts", expansion = "TWW", profession = "Engineering",
        baseName = "Handful of Bismuth Bolts" },
    { itemId = 221856, name = "Whimsical Wiring", expansion = "TWW", profession = "Engineering", baseName = "Whimsical Wiring" },
    { itemId = 221859, name = "Entropy Enhancer", expansion = "TWW", profession = "Engineering", baseName = "Entropy Enhancer" },
    { itemId = 222417, name = "Core Alloy", expansion = "TWW", profession = "Blacksmithing", baseName = "Core Alloy" },
    { itemId = 222420, name = "Charged Alloy", expansion = "TWW", profession = "Blacksmithing", baseName = "Charged Alloy" },
    { itemId = 222419, name = "Sanctified Alloy", expansion = "TWW", profession = "Blacksmithing", baseName = "Sanctified Alloy" },

    -- Jewelcrafting / Inscription / Cooking use gathering reagents above + acuity;
    -- expand specialty gems/inks as Wowhead IDs are confirmed.
}, "mainline")
