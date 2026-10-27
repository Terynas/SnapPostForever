local _, ns = ...

ns.MinimapButton = ns.MinimapButton or {}
local MB = ns.MinimapButton

local button

local function EnsureDb()
    if not ns.db then
        return nil
    end
    ns.db.minimap = ns.db.minimap or {}
    if ns.db.minimap.hide == nil then
        ns.db.minimap.hide = false
    end
    if ns.db.minimap.angle == nil then
        ns.db.minimap.angle = 200
    end
    return ns.db.minimap
end

local function UpdatePosition(btn)
    local db = EnsureDb()
    if not db or not Minimap then
        return
    end
    local angle = math.rad(db.angle or 200)
    local radius = (Minimap:GetWidth() / 2) + 5
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateButton()
    if button then
        return button
    end

    local btn = CreateFrame("Button", "SnapPostForeverMinimapButton", Minimap)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    btn:SetSize(32, 32)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    btn:RegisterForClicks("AnyUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\INV_Letter_15")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER")
    btn.icon = icon

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffc9a227SnapPost Forever|r", 1, 1, 1)
        GameTooltip:AddLine("Left-click: open mapper", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Right-click: options", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Drag: move icon", 0.65, 0.65, 0.65)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if ns.UI then
                ns.UI:ToggleMapper()
            end
        elseif mouseButton == "RightButton" then
            if ns.Options then
                ns.Options:Open()
            elseif ns.UI then
                ns.UI:ToggleMapper()
            end
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function(frame)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local db = EnsureDb()
            if db then
                local deg = math.deg(math.atan2(py - my, px - mx))
                if deg < 0 then
                    deg = deg + 360
                end
                db.angle = deg
            end
            UpdatePosition(frame)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
        UpdatePosition(self)
    end)

    if Minimap then
        Minimap:HookScript("OnSizeChanged", function()
            if button and button:IsShown() then
                UpdatePosition(button)
            end
        end)
    end

    button = btn
    return btn
end

function MB:Refresh()
    local db = EnsureDb()
    if not db or not Minimap then
        return
    end
    local btn = CreateButton()
    UpdatePosition(btn)
    if db.hide then
        btn:Hide()
    else
        btn:Show()
    end
end

function MB:SetShown(shown)
    local db = EnsureDb()
    if not db then
        return
    end
    db.hide = not shown
    self:Refresh()
end

function MB:IsShown()
    local db = EnsureDb()
    return db and not db.hide
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    -- Minimap exists after login; db is ready from ADDON_LOADED.
    C_Timer.After(0.1, function()
        if ns.db then
            MB:Refresh()
        end
    end)
end)
