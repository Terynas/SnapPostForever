local _, ns = ...

ns.Tooltip = ns.Tooltip or {}

local function IsBagOwner(owner)
    if not owner or type(owner.GetObjectType) ~= "function" then
        return false
    end
    if owner.GetObjectType and owner:GetObjectType() ~= "Button" and owner:GetObjectType() ~= "Frame" then
        return false
    end
    if owner.GetBagID or owner.bagID or owner.bag then
        return true
    end
    local name = owner.GetName and owner:GetName()
    if type(name) == "string" then
        if name:find("ContainerFrame", 1, true)
            or name:find("Bagnon", 1, true)
            or name:find("AdiBag", 1, true)
            or name:find("BagSlot", 1, true)
            or name:find("ReagentBag", 1, true) then
            return true
        end
    end
    local parent = owner.GetParent and owner:GetParent()
    if parent and parent.GetName then
        local pname = parent:GetName()
        if type(pname) == "string" and (pname:find("ContainerFrame", 1, true) or pname:find("Bagnon", 1, true)) then
            return true
        end
    end
    return false
end

local function RecipientText(charKey)
    local info = ns.db and ns.db.chars and ns.db.chars[charKey]
    if info then
        if info.mailName and info.mailName ~= "" then
            return info.mailName
        end
        if info.name and info.name ~= "" then
            return info.name
        end
    end
    return charKey
end

function ns.Tooltip:Annotate(tooltip, itemId)
    if not tooltip or not itemId or itemId <= 0 or not ns.db or not ns.Mapper then
        return
    end
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if not IsBagOwner(owner) then
        return
    end

    local entry = ns.MaterialById and ns.MaterialById[itemId]
    local recipient, reason
    if entry then
        recipient, reason = ns.Mapper:ResolveRecipient(entry)
    end

    local selfKey = ns.PlayerKey and ns.PlayerKey()
    if (not recipient or recipient == selfKey)
        and ns.DEFodder
        and ns.DEFodder:IsEnabled() then
        local ok = ns.DEFodder:Evaluate(itemId)
        if ok then
            local deChar = ns.DEFodder:GetRecipient()
            if deChar and deChar ~= selfKey then
                recipient, reason = deChar, "defodder"
            end
        end
    end

    if not entry and reason ~= "defodder" then
        return
    end

    local line, r, g, b

    if not recipient then
        line, r, g, b = "SnapPost: unmapped", 0.7, 0.7, 0.7
    elseif selfKey and recipient == selfKey then
        line, r, g, b = "SnapPost: stays on this character", 0.8, 0.8, 0.55
    else
        local who = RecipientText(recipient)
        local via = ""
        if reason == "item" then
            via = " (item map)"
        elseif reason == "profession" then
            via = " (profession)"
        elseif reason == "expansion" then
            via = " (expansion)"
        elseif reason == "auto" then
            via = " (auto)"
        elseif reason == "defodder" then
            via = " (DE fodder)"
        end
        if (reason == "profession" or reason == "expansion") and ns.Mapper:Conflict(entry) then
            via = via .. " · shared"
        end
        line, r, g, b = "SnapPost > " .. who .. via, 0.45, 0.9, 0.55
    end

    tooltip:AddLine(line, r, g, b)
    tooltip:Show()
end

local function OnItemTooltip(tooltip, data)
    local itemId = data and data.id
    if not itemId and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if type(link) == "string" then
            itemId = tonumber(link:match("item:(%d+)"))
        end
    end
    ns.Tooltip:Annotate(tooltip, itemId)
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        OnItemTooltip(tooltip)
    end)
end
