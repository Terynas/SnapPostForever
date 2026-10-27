local _, ns = ...

ns.MailQueue = ns.MailQueue or {}
local MailQueue = ns.MailQueue

local state = {
    active = false,
    waiting = false,
    jobs = {},
    jobIndex = 1,
    status = "idle",
    onUpdate = nil,
    waitTimer = nil,
}

local function MaxAttachments()
    return ATTACHMENTS_MAX_SEND or 12
end

local function Notify()
    if state.onUpdate then
        state.onUpdate(state)
    end
end

local function CancelWaitTimer()
    if state.waitTimer then
        state.waitTimer:Cancel()
        state.waitTimer = nil
    end
end

function MailQueue:IsActive()
    return state.active
end

function MailQueue:GetState()
    return state
end

function MailQueue:SetUpdateHandler(fn)
    state.onUpdate = fn
end

local function RescanMailUI()
    if ns.UI and ns.UI.RescanMailPlan then
        -- Bags update a beat after MAIL_SEND_SUCCESS.
        C_Timer.After(0.15, function()
            ns.UI:RescanMailPlan()
        end)
    end
end

function MailQueue:Cancel(reason)
    if not state.active then
        return
    end
    CancelWaitTimer()
    state.active = false
    state.waiting = false
    state.status = reason or "cancelled"
    wipe(state.jobs)
    Notify()
    ns.PrintMailProgress("Mail queue stopped: %s", state.status)
    RescanMailUI()
end

local function RecipientName(charKey)
    local info = ns.db.chars[charKey]
    if info then
        -- Forever mail To: full first + surname (never first-name alone).
        if info.mailName and info.mailName ~= "" then
            return info.mailName
        end
        if info.firstName and info.surname and info.surname ~= "" then
            return ns.ComposeFullName(info.firstName, info.surname)
        end
        if info.name and info.name ~= "" then
            -- Regional unique names: do not append realm; full name is enough.
            if ns.HasRegionalUniqueNames and ns.HasRegionalUniqueNames() then
                return info.name
            end
            local playerRealm = (GetNormalizedRealmName() or GetRealmName() or ""):gsub("%s+", "")
            if info.realm and info.realm ~= "" and info.realm ~= playerRealm then
                return info.name .. "-" .. info.realm
            end
            return info.name
        end
    end
    -- CharKey is "Full Name-Realm" — strip trailing -Realm only.
    local name = charKey:match("^(.+)-[^-]+$") or charKey:match("^([^-]+)")
    return name or charKey
end

local function EnsureSendMailTab()
    if SendMailFrame and SendMailFrame:IsShown() then
        return true
    end
    -- Switch MailFrame to Send tab (tab 2)
    if MailFrameTab_OnClick and MailFrameTab2 then
        MailFrameTab_OnClick(MailFrameTab2, 2)
    elseif MailFrameTab2 and MailFrameTab2.Click then
        MailFrameTab2:Click()
    end
    return SendMailFrame and (SendMailFrame:IsShown() or MailFrame and MailFrame:IsShown())
end

local function ClearOutgoing()
    if ClearSendMail then
        ClearSendMail()
    end
    ClearCursor()
end

local function FindFreeAttachSlot()
    local maxA = MaxAttachments()
    for i = 1, maxA do
        local name = GetSendMailItem and GetSendMailItem(i)
        if not name then
            return i
        end
    end
    return nil
end

local function CountAttachments()
    local n = 0
    for i = 1, MaxAttachments() do
        if GetSendMailItem and GetSendMailItem(i) then
            n = n + 1
        end
    end
    return n
end

-- Postal-style attach: click empty slot, pick bag item, click slot again.
local function AttachStack(bag, slot)
    ClearCursor()
    local attachSlot = FindFreeAttachSlot()
    if not attachSlot then
        return false
    end

    if ClickSendMailItemButton then
        ClickSendMailItemButton(attachSlot)
    end

    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then
        PickupContainerItem(bag, slot)
    else
        return false
    end

    if CursorHasItem and not CursorHasItem() then
        return false
    end

    if ClickSendMailItemButton then
        ClickSendMailItemButton(attachSlot)
    end
    ClearCursor()

    local name = GetSendMailItem and GetSendMailItem(attachSlot)
    return name ~= nil
end

-- Re-locate stack by itemId if original bag/slot moved.
local function ResolveStackLocation(stack)
    local bag, slot = stack.bag, stack.slot
    local id = stack.itemId
    if id and C_Container and C_Container.GetContainerItemID then
        local cur = C_Container.GetContainerItemID(bag, slot)
        if cur == id then
            return bag, slot
        end
        for _, b in ipairs(ns.BagScan:IterBags()) do
            local slots = C_Container.GetContainerNumSlots(b) or 0
            for s = 1, slots do
                if C_Container.GetContainerItemID(b, s) == id then
                    return b, s
                end
            end
        end
    end
    return bag, slot
end

local function SetMailFields(recipient, subject, body)
    if SendMailNameEditBox then
        SendMailNameEditBox:SetText(recipient or "")
        if SendMailNameEditBox.ClearFocus then
            SendMailNameEditBox:ClearFocus()
        end
    end
    if SendMailSubjectEditBox then
        SendMailSubjectEditBox:SetText(subject or " ")
        if SendMailSubjectEditBox.ClearFocus then
            SendMailSubjectEditBox:ClearFocus()
        end
    end
    if SendMailBodyEditBox and body then
        SendMailBodyEditBox:SetText(body)
    end
end

local function DoSend(recipient, subject, body)
    SetMailFields(recipient, subject, body)

    -- Prefer Blizzard helper (reads edit boxes) — same path as the Send button.
    if SendMailFrame_SendMail then
        SendMailFrame_SendMail()
        return "SendMailFrame_SendMail"
    end

    if SendMailMailButton and SendMailMailButton:IsEnabled() then
        SendMailMailButton:Click()
        return "SendMailMailButton"
    end

    SendMail(recipient, subject or " ", body or "")
    return "SendMail"
end

function MailQueue:Start(plan, mode, onlyCharKey)
    if state.active then
        ns.Print("Queue already running.")
        return false
    end
    if not MailFrame or not MailFrame:IsShown() then
        ns.Print("Open a mailbox first.")
        return false
    end
    if not plan or not plan.recipients or #plan.recipients == 0 then
        ns.Print("Nothing to send.")
        return false
    end

    EnsureSendMailTab()

    wipe(state.jobs)
    for _, group in ipairs(plan.recipients) do
        if mode ~= "one" or group.charKey == onlyCharKey then
            local pending = {}
            for _, stack in ipairs(group.stacks) do
                if not stack.excluded then
                    pending[#pending + 1] = stack
                end
            end
            local i = 1
            while i <= #pending do
                local chunk = {}
                for _ = 1, MaxAttachments() do
                    if pending[i] then
                        chunk[#chunk + 1] = pending[i]
                        i = i + 1
                    else
                        break
                    end
                end
                if #chunk > 0 then
                    state.jobs[#state.jobs + 1] = {
                        charKey = group.charKey,
                        recipient = RecipientName(group.charKey),
                        stacks = chunk,
                    }
                end
            end
        end
    end

    if #state.jobs == 0 then
        ns.Print("No matching recipients in plan.")
        return false
    end

    state.active = true
    state.waiting = false
    state.jobIndex = 1
    state.status = "running"
    Notify()
    ns.PrintMailProgress("Queuing %d mail(s) to send…", #state.jobs)
    -- Keep first send on the same click execution path (no timer).
    self:ProcessNext()
    return true
end

function MailQueue:ProcessNext()
    if not state.active then
        return
    end
    if state.waiting then
        return
    end
    if not MailFrame or not MailFrame:IsShown() then
        self:Cancel("Mailbox closed")
        return
    end

    local job = state.jobs[state.jobIndex]
    if not job then
        CancelWaitTimer()
        state.active = false
        state.status = "done"
        Notify()
        ns.PrintMailProgress("Mail queue finished.")
        RescanMailUI()
        return
    end

    EnsureSendMailTab()
    ClearOutgoing()

    local subject = ns.db.settings.mailSubject or "SnapPost Forever"
    -- Use first item name as subject if default — Blizzard does this too.
    if job.stacks[1] and job.stacks[1].name then
        subject = job.stacks[1].name
    end

    SetMailFields(job.recipient, subject, "Sent by SnapPost Forever")

    local attached = 0
    job.sent = {}
    for _, stack in ipairs(job.stacks) do
        local bag, slot = ResolveStackLocation(stack)
        if AttachStack(bag, slot) then
            attached = attached + 1
            job.sent[#job.sent + 1] = string.format("%s x%d", stack.name or ("item " .. tostring(stack.itemId)), stack.count or 1)
        end
    end

    if attached == 0 or CountAttachments() == 0 then
        ns.Print("Could not attach items for %s — skipping. Is the Send Mail tab open?", job.recipient)
        state.jobIndex = state.jobIndex + 1
        C_Timer.After(0.25, function()
            if state.active then
                MailQueue:ProcessNext()
            end
        end)
        return
    end

    -- Re-apply fields after attach (some clients clear subject).
    SetMailFields(job.recipient, subject, "Sent by SnapPost Forever")

    state.waiting = true
    state.status = string.format("Sending %d/%d to %s (%d stacks)", state.jobIndex, #state.jobs, job.recipient, attached)
    Notify()

    local method = DoSend(job.recipient, subject, "Sent by SnapPost Forever")
    ns.PrintMailProgress("Send via %s -> %s", method, job.recipient)

    -- If neither success nor fail arrives, retry once via button then abort.
    CancelWaitTimer()
    state.waitTimer = C_Timer.NewTimer(4, function()
        if not state.active or not state.waiting then
            return
        end
        ns.PrintMailProgress("No mail response yet — retrying Send button…")
        if SendMailMailButton then
            SetMailFields(job.recipient, subject, "Sent by SnapPost Forever")
            if SendMailMailButton:IsEnabled() then
                SendMailMailButton:Click()
            elseif SendMailFrame_SendMail then
                SendMailFrame_SendMail()
            end
        end
        state.waitTimer = C_Timer.NewTimer(4, function()
            if state.active and state.waiting then
                ns.Print("Mail send timed out. Check the To name (try full name) and postage gold.")
                MailQueue:Cancel("send timed out")
            end
        end)
    end)
end

function MailQueue:OnSendSuccess()
    if not state.active or not state.waiting then
        return
    end
    CancelWaitTimer()
    state.waiting = false
    local job = state.jobs[state.jobIndex]
    state.jobIndex = state.jobIndex + 1
    local delay = tonumber(ns.db.settings.sendDelay) or 3
    if delay < 1 then
        delay = 1
    end
    local sentList = job and job.sent and table.concat(job.sent, ", ") or ""
    local who = job and job.recipient or "?"
    state.status = string.format("Sent to %s. Waiting %.1fs…", who, delay)
    Notify()
    if sentList ~= "" then
        ns.PrintMailProgress("Sent to |cffffffff%s|r: %s", who, sentList)
    else
        ns.PrintMailProgress("Sent to |cffffffff%s|r.", who)
    end
    RescanMailUI()
    C_Timer.After(delay, function()
        if state.active then
            MailQueue:ProcessNext()
        end
    end)
end

function MailQueue:OnSendFailed()
    if not state.active or not state.waiting then
        return
    end
    CancelWaitTimer()
    state.waiting = false
    local job = state.jobs[state.jobIndex]
    local who = tostring(job and job.recipient or "?")
    ns.Print("Mail FAILED for %s. Check character name, gold for postage, and soulbound items.", who)
    self:Cancel("send failed")
end
