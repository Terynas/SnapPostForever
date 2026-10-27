local _, ns = ...

ns.BagScan = ns.BagScan or {}
local BagScan = ns.BagScan

local function IsSoulbound(bag, slot)
    if not C_Item or not C_Item.IsBound then
        return false
    end
    local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not loc or not C_Item.DoesItemExist(loc) then
        return false
    end
    -- IsBound can be true for account-bound too; skip anything bound that mail rejects.
    local ok, bound = pcall(C_Item.IsBound, loc)
    return ok and bound
end

local function GetItemId(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    end
    return GetContainerItemID and GetContainerItemID(bag, slot)
end

local function GetStackCount(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.stackCount or 1
        end
    end
    local _, count = GetContainerItemInfo(bag, slot)
    return count or 1
end

function BagScan:IterBags()
    local bags = {}
    if Enum and Enum.BagIndex then
        bags = {
            Enum.BagIndex.Backpack,
            Enum.BagIndex.Bag_1,
            Enum.BagIndex.Bag_2,
            Enum.BagIndex.Bag_3,
            Enum.BagIndex.Bag_4,
            Enum.BagIndex.ReagentBag,
        }
    else
        for i = 0, 4 do
            bags[#bags + 1] = i
        end
        bags[#bags + 1] = 5 -- reagent bag guess
    end
    return bags
end

function BagScan:BuildPlan()
    local selfKey = ns.PlayerKey()
    local byRecipient = {}
    local totalStacks = 0
    local skipBound = ns.db.settings.skipSoulbound ~= false

    for _, bag in ipairs(self:IterBags()) do
        local slots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)
        slots = slots or (GetContainerNumSlots and GetContainerNumSlots(bag)) or 0
        for slot = 1, slots do
            local itemId = GetItemId(bag, slot)
            if itemId and itemId > 0 and not (skipBound and IsSoulbound(bag, slot)) then
                local recipient, reason, displayName, expansion, profession
                local entry = ns.MaterialById[itemId]
                if entry then
                    recipient, reason = ns.Mapper:ResolveRecipient(entry)
                    displayName = entry.name
                    expansion = entry.expansion
                    profession = entry.profession
                end

                -- Low-value green gear → enchanter (when not already mapped as a reagent).
                if (not recipient or recipient == selfKey)
                    and ns.DEFodder
                    and ns.DEFodder:IsEnabled() then
                    local ok, meta = ns.DEFodder:Evaluate(itemId)
                    if ok then
                        local deChar = ns.DEFodder:GetRecipient()
                        if deChar and deChar ~= selfKey then
                            recipient = deChar
                            reason = "defodder"
                            displayName = (type(meta) == "table" and meta.name) or displayName or ("item:" .. itemId)
                            profession = "Enchanting"
                            expansion = expansion or "Classic"
                        end
                    end
                end

                if recipient and recipient ~= selfKey then
                    local count = GetStackCount(bag, slot)
                    byRecipient[recipient] = byRecipient[recipient] or {
                        charKey = recipient,
                        stacks = {},
                        stackCount = 0,
                        itemCount = 0,
                    }
                    local group = byRecipient[recipient]
                    group.stacks[#group.stacks + 1] = {
                        bag = bag,
                        slot = slot,
                        itemId = itemId,
                        count = count,
                        name = displayName or ("item:" .. itemId),
                        expansion = expansion,
                        profession = profession,
                        reason = reason,
                    }
                    group.stacks[#group.stacks].excluded = false
                    group.stackCount = group.stackCount + 1
                    group.itemCount = group.itemCount + count
                    totalStacks = totalStacks + 1
                end
            end
        end
    end

    local recipients = {}
    for _, group in pairs(byRecipient) do
        recipients[#recipients + 1] = group
    end
    table.sort(recipients, function(a, b)
        return a.charKey < b.charKey
    end)

    return {
        recipients = recipients,
        totalStacks = totalStacks,
        selfKey = selfKey,
    }
end

function BagScan:ActiveCounts(plan)
    local stacks, items = 0, 0
    if not plan then
        return stacks, items
    end
    for _, group in ipairs(plan.recipients or {}) do
        for _, stack in ipairs(group.stacks or {}) do
            if not stack.excluded then
                stacks = stacks + 1
                items = items + (stack.count or 1)
            end
        end
    end
    return stacks, items
end
