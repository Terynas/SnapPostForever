local _, ns = ...

-- Dragonflight gathering + core craft reagents (all quality tiers where known).

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
        expansion = "DF",
        profession = profession,
        professions = professions,
        quality = quality,
        baseName = name,
    }
end

ns.RegisterMaterials({
    -- Herbs
    Q(191460, "Hochenblume", "Herbalism", 1),
    Q(191461, "Hochenblume", "Herbalism", 2),
    Q(191462, "Hochenblume", "Herbalism", 3),
    Q(191464, "Saxifrage", "Herbalism", 1),
    Q(191465, "Saxifrage", "Herbalism", 2),
    Q(191466, "Saxifrage", "Herbalism", 3),
    Q(191467, "Bubble Poppy", "Herbalism", 1),
    Q(191468, "Bubble Poppy", "Herbalism", 2),
    Q(191469, "Bubble Poppy", "Herbalism", 3),
    Q(191470, "Writhebark", "Herbalism", 1),
    Q(191471, "Writhebark", "Herbalism", 2),
    Q(191472, "Writhebark", "Herbalism", 3),

    -- Ores (also consumed by Blacksmithing alloys / smelting)
    Q(190394, "Serevite Ore", "Mining", 1, { "Blacksmithing" }),
    Q(190395, "Serevite Ore", "Mining", 2, { "Blacksmithing" }),
    Q(190396, "Serevite Ore", "Mining", 3, { "Blacksmithing" }),
    Q(188658, "Draconium Ore", "Mining", 1, { "Blacksmithing" }),
    Q(189143, "Draconium Ore", "Mining", 2, { "Blacksmithing" }),
    Q(190311, "Draconium Ore", "Mining", 3, { "Blacksmithing" }),
    Q(190312, "Khaz'gorite Ore", "Mining", 1, { "Blacksmithing" }),
    Q(190313, "Khaz'gorite Ore", "Mining", 2, { "Blacksmithing" }),
    Q(190314, "Khaz'gorite Ore", "Mining", 3, { "Blacksmithing" }),

    -- Cloth
    Q(193050, "Tattered Wildercloth", "Tailoring", 1),
    Q(193051, "Tattered Wildercloth", "Tailoring", 2),
    Q(193052, "Tattered Wildercloth", "Tailoring", 3),
    { itemId = 193922, name = "Wildercloth", expansion = "DF", profession = "Tailoring", baseName = "Wildercloth" },
    { itemId = 193923, name = "Wildercloth Bolt", expansion = "DF", profession = "Tailoring", baseName = "Wildercloth Bolt" },
    { itemId = 193924, name = "Vibrant Wildercloth Bolt", expansion = "DF", profession = "Tailoring",
        baseName = "Vibrant Wildercloth Bolt" },
    { itemId = 193925, name = "Chronocloth Bolt", expansion = "DF", profession = "Tailoring", baseName = "Chronocloth Bolt" },
    { itemId = 193926, name = "Azureweave Bolt", expansion = "DF", profession = "Tailoring", baseName = "Azureweave Bolt" },

    -- Leather / scales / hides
    Q(193208, "Resilient Leather", "Leatherworking", 1),
    Q(193210, "Resilient Leather", "Leatherworking", 2),
    Q(193211, "Resilient Leather", "Leatherworking", 3),
    Q(193213, "Adamant Scales", "Leatherworking", 1),
    Q(193214, "Adamant Scales", "Leatherworking", 2),
    Q(193215, "Adamant Scales", "Leatherworking", 3),
    Q(193216, "Dense Hide", "Leatherworking", 1),
    Q(193217, "Dense Hide", "Leatherworking", 2),
    Q(193218, "Dense Hide", "Leatherworking", 3),
    { itemId = 193222, name = "Lustrous Scaled Hide", expansion = "DF", profession = "Leatherworking", baseName = "Lustrous Scaled Hide" },
    { itemId = 193224, name = "Stonecrust Hide", expansion = "DF", profession = "Leatherworking", baseName = "Stonecrust Hide" },
    { itemId = 193226, name = "Crystalspine Fur", expansion = "DF", profession = "Skinning", baseName = "Crystalspine Fur" },
    { itemId = 193229, name = "Salamanther Scales", expansion = "DF", profession = "Skinning", baseName = "Salamanther Scales" },
    { itemId = 193236, name = "Rockfang Leather", expansion = "DF", profession = "Skinning", baseName = "Rockfang Leather" },
    { itemId = 193248, name = "Windsong Plumage", expansion = "DF", profession = "Skinning", baseName = "Windsong Plumage" },
    { itemId = 193253, name = "Fire-Infused Hide", expansion = "DF", profession = "Skinning", baseName = "Fire-Infused Hide" },
    { itemId = 193255, name = "Flawless Proto Dragon Scale", expansion = "DF", profession = "Skinning",
        baseName = "Flawless Proto Dragon Scale" },
    { itemId = 193258, name = "Cacophonous Thunderscale", expansion = "DF", profession = "Skinning",
        baseName = "Cacophonous Thunderscale" },
    { itemId = 193261, name = "Pristine Vorquin Horn", expansion = "DF", profession = "Skinning", baseName = "Pristine Vorquin Horn" },

    -- Enchanting
    { itemId = 194123, name = "Chromatic Dust", expansion = "DF", profession = "Enchanting", baseName = "Chromatic Dust" },
    { itemId = 194124, name = "Vibrant Shard", expansion = "DF", profession = "Enchanting", baseName = "Vibrant Shard" },
    { itemId = 200113, name = "Resonant Crystal", expansion = "DF", profession = "Enchanting", baseName = "Resonant Crystal" },

    -- Blacksmithing / Engineering / Alchemy shared
    { itemId = 190530, name = "Primal Flux", expansion = "DF", profession = "Blacksmithing", baseName = "Primal Flux" },
    { itemId = 189541, name = "Primal Molten Alloy", expansion = "DF", profession = "Blacksmithing", baseName = "Primal Molten Alloy" },
    { itemId = 190452, name = "Primal Chaos", expansion = "DF", profession = "Engineering", baseName = "Primal Chaos",
        professions = { "Engineering", "Blacksmithing", "Jewelcrafting", "Inscription" } },
    { itemId = 190456, name = "Artisan's Mettle", expansion = "DF", profession = "Alchemy", baseName = "Artisan's Mettle",
        professions = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Inscription", "Jewelcrafting",
            "Leatherworking", "Tailoring" } },
    -- Herbs/ores/cloth/leather/enchanting above cover primary DF mapping;
    -- specialty JC/Inscription/Cooking packs can expand as IDs are confirmed.
}, "mainline")
