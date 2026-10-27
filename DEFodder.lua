local _, ns = ...

--- Low-value Uncommon (green) armor/weapons → enchanter for disenchant.
ns.DEFodder = ns.DEFodder or {}
local DE = ns.DEFodder

local CALLER = "SnapPostForever"
local QUALITY_UNCOMMON = 2

local function Settings()
    local s = ns.db and ns.db.settings and ns.db.settings.deFodder
    return s or {}
end

local function ClassIsGear(classID)
    if not classID then
        return false
    end
    if Enum and Enum.ItemClass then
        return classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Armor
    end
    -- Classic fallbacks: 2 = Weapon, 4 = Armor
    return classID == 2 or classID == 4
end

local function GetItemInfoParts(itemId)
    if C_Item and C_Item.GetItemInfo then
        local name, link, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, sellPrice, classID =
            C_Item.GetItemInfo(itemId)
        return name, link, quality, itemLevel, reqLevel, equipLoc, sellPrice, classID
    end
    if GetItemInfo then
        local name, link, quality, itemLevel, reqLevel, _, _, _, equipLoc, _, sellPrice, classID =
            GetItemInfo(itemId)
        return name, link, quality, itemLevel, reqLevel, equipLoc, sellPrice, classID
    end
end

function DE:GetAuctionPrice(itemId)
    if not itemId then
        return nil
    end
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not api or not api.GetAuctionPriceByItemID then
        return nil
    end
    local ok, price = pcall(api.GetAuctionPriceByItemID, CALLER, itemId)
    if ok and type(price) == "number" and price > 0 then
        return price
    end
    return nil
end

function DE:GetDisenchantPrice(itemId)
    if not itemId then
        return nil
    end
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not api or not api.GetDisenchantPriceByItemID then
        return nil
    end
    local ok, price = pcall(api.GetDisenchantPriceByItemID, CALLER, itemId)
    if ok and type(price) == "number" and price > 0 then
        return price
    end
    return nil
end

--- Returns true, meta if this item is green DE fodder under current settings.
function DE:Evaluate(itemId)
    local s = Settings()
    if s.enabled == false then
        return false, "disabled"
    end
    if not itemId or itemId <= 0 then
        return false, "badid"
    end

    local name, _, quality, itemLevel, reqLevel, equipLoc, sellPrice, classID = GetItemInfoParts(itemId)
    if not name then
        return false, "noinfo"
    end
    if quality ~= QUALITY_UNCOMMON then
        return false, "quality"
    end
    if not ClassIsGear(classID) then
        return false, "class"
    end
    -- Skip non-equippable armor odds (e.g. some misc) when slot is empty and not a weapon.
    if (not equipLoc or equipLoc == "") and classID ~= (Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2) then
        return false, "equip"
    end

    local maxLevel = tonumber(s.maxLevel) or 40
    local level = math.max(tonumber(reqLevel) or 0, tonumber(itemLevel) or 0)
    if level > maxLevel then
        return false, "level"
    end

    local maxVendor = tonumber(s.maxVendorCopper) or 50000 -- 5g
    sellPrice = tonumber(sellPrice) or 0
    if sellPrice > maxVendor then
        return false, "vendor"
    end

    local maxAuction = tonumber(s.maxAuctionCopper) or 10000 -- 1g
    local ah = self:GetAuctionPrice(itemId)
    if ah and ah > maxAuction then
        return false, "auction"
    end

    -- If Auctionator knows DE shard value and it's below vendor, vendor instead.
    if s.skipIfVendorBeatsDE ~= false then
        local dePrice = self:GetDisenchantPrice(itemId)
        if dePrice and sellPrice > 0 and sellPrice >= dePrice then
            return false, "vendor_beats_de"
        end
    end

    return true, {
        name = name,
        quality = quality,
        level = level,
        sellPrice = sellPrice,
        auctionPrice = ah,
        reason = "defodder",
    }
end

function DE:GetRecipient()
    if not ns.db or not ns.db.maps then
        return nil
    end
    local key = ns.db.maps.deFodderChar
    if key and key ~= "" then
        return key
    end
    return nil
end

function DE:SetRecipient(charKey)
    if not ns.db or not ns.db.maps then
        return
    end
    if charKey == nil or charKey == "" then
        ns.db.maps.deFodderChar = nil
    else
        ns.db.maps.deFodderChar = charKey
        local s = ns.db.settings.deFodder
        if s then
            s.enabled = true
        end
    end
end

function DE:IsEnabled()
    local s = Settings()
    return s.enabled ~= false and self:GetRecipient() ~= nil
end
