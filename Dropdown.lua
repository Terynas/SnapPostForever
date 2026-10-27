local _, ns = ...

ns.Dropdown = ns.Dropdown or {}

local openMenu

local function CloseMenu()
    if openMenu then
        openMenu:Hide()
        openMenu = nil
    end
end

-- Simple custom dropdown (avoids fragile Blizzard dropdown template churn).
function ns.Dropdown.Create(parent, width, opts)
    -- opts: { onSelect = function(value, text), getSelected = function() return value, text end }
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 160, 26)
    btn:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    btn:SetBackdropColor(0.08, 0.07, 0.06, 1)
    btn:SetBackdropBorderColor(0.72, 0.58, 0.22, 1)

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.label:SetPoint("LEFT", 8, 0)
    btn.label:SetPoint("RIGHT", -18, 0)
    btn.label:SetJustifyH("LEFT")

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")

    btn.options = {}
    btn.onSelect = opts and opts.onSelect
    btn.getSelected = opts and opts.getSelected

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    menu:SetBackdropColor(0.08, 0.08, 0.10, 1)
    menu:SetBackdropBorderColor(0.50, 0.50, 0.55, 1)
    menu:Hide()
    menu.buttons = {}
    btn.menu = menu

    local function RefreshLabel()
        if btn.getSelected then
            local _, text = btn.getSelected()
            btn.label:SetText(text or "—")
        end
    end

    function btn:SetOptions(list)
        -- list: { { value = ..., text = ... }, ... }
        self.options = list or {}
        RefreshLabel()
    end

    function btn:Refresh()
        RefreshLabel()
    end

    local function BuildMenu()
        local list = btn.options
        local height = 6
        local maxW = btn:GetWidth()
        for i, opt in ipairs(list) do
            local row = menu.buttons[i]
            if not row then
                row = CreateFrame("Button", nil, menu, "BackdropTemplate")
                row:SetHeight(24)
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(0.14, 0.14, 0.16, 1)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.text:SetPoint("LEFT", 8, 0)
                row.text:SetPoint("RIGHT", -8, 0)
                row.text:SetJustifyH("LEFT")
                row:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.28, 0.24, 0.12, 1)
                end)
                row:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0.14, 0.14, 0.16, 1)
                end)
                menu.buttons[i] = row
            end
            row.text:SetText(opt.text)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 24)
            row:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * 24)
            row:SetScript("OnClick", function()
                if btn.onSelect then
                    btn.onSelect(opt.value, opt.text)
                end
                CloseMenu()
                RefreshLabel()
            end)
            row:Show()
            height = height + 24
            local tw = row.text:GetStringWidth() + 24
            if tw > maxW then
                maxW = tw
            end
        end
        for i = #list + 1, #menu.buttons do
            menu.buttons[i]:Hide()
        end
        menu:SetSize(math.max(btn:GetWidth(), maxW), height + 4)
    end

    btn:SetScript("OnClick", function()
        if openMenu == menu and menu:IsShown() then
            CloseMenu()
            return
        end
        CloseMenu()
        BuildMenu()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        menu:Show()
        openMenu = menu
    end)

    if not ns._dropdownCloser then
        ns._dropdownCloser = CreateFrame("Frame")
        ns._dropdownCloser:SetScript("OnMouseDown", function()
            CloseMenu()
        end)
        -- Not enabling mouse on world; Escape via UISpecial handled separately.
    end

    btn:SetScript("OnHide", CloseMenu)
    RefreshLabel()
    return btn
end

function ns.Dropdown.CloseAll()
    CloseMenu()
end
