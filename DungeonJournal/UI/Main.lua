-- Main window: header bar, page switching and navigation.
local DJ = DungeonJournal
local L = DJ.L

local FRAME_W, FRAME_H = 880, 600
DJ.pages = {}

local frame = CreateFrame("Frame", "DungeonJournalFrame", UIParent)
DJ.frame = frame
DJ.Size(frame, FRAME_W, FRAME_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("HIGH")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
table.insert(UISpecialFrames, "DungeonJournalFrame")

frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame.OnTheme = function(self, t)
    self:SetBackdropColor(t.frame[1], t.frame[2], t.frame[3], t.frame[4])
    self:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 1)
end
table.insert(DJ.themedRegions, frame)

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    DJ.db.point = { point, relPoint, x, y }
end)

-- Header ---------------------------------------------------------------
local header = DJ.Panel(frame, "header", "border")
header:SetPoint("TOPLEFT", 6, -6)
header:SetPoint("TOPRIGHT", -6, -6)
header:SetHeight(36)
frame.header = header

local bookIcon = header:CreateTexture(nil, "ARTWORK")
DJ.Size(bookIcon, 26, 26)
bookIcon:SetPoint("LEFT", 6, 0)
bookIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
bookIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local title = DJ.Text(header, "GameFontNormalLarge", 16)
title:SetPoint("LEFT", bookIcon, "RIGHT", 8, 0)
title:SetText(L.TITLE)
frame.titleText = title
header.OnTheme = function(self, t)
    title:SetTextColor(t.title[1], t.title[2], t.title[3])
end

local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
close:SetPoint("RIGHT", 2, 0)
close:SetScript("OnClick", function() frame:Hide() end)

local homeButton = DJ.Button(header, L.HOME, 70, 24, function() DJ.ShowHome() end)
homeButton:SetPoint("LEFT", title, "RIGHT", 18, 0)
frame.homeButton = homeButton

local backButton = DJ.Button(header, "<", 26, 24, function() DJ.GoBack() end)
backButton:SetPoint("LEFT", homeButton, "RIGHT", 4, 0)
frame.backButton = backButton

-- Search box
local search = CreateFrame("EditBox", "DungeonJournalSearchBox", header, "InputBoxTemplate")
DJ.Size(search, 230, 20)
search:SetPoint("RIGHT", close, "LEFT", -10, 0)
search:SetAutoFocus(false)
search:SetMaxLetters(60)
search.hint = DJ.Text(search, "GameFontDisable", 11)
search.hint:SetPoint("LEFT", 2, 0)
search.hint:SetText(L.SEARCH_HINT)
search:SetScript("OnEditFocusGained", function(self) self.hint:Hide() end)
search:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self.hint:Show() end
end)
search:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)
search:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local text = strtrim(self:GetText())
    if text ~= "" then DJ.ShowSearch(text) end
end)
search:SetScript("OnTextChanged", function(self, userInput)
    local text = strtrim(self:GetText())
    if text ~= "" then self.hint:Hide() end
    if userInput and #text >= 3 then DJ.ShowSearch(text, true) end
end)
frame.search = search

-- Body: every page is a child of this frame.
local body = CreateFrame("Frame", nil, frame)
body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
body:SetPoint("BOTTOMRIGHT", -6, 6)
frame.body = body

-- Resize grip: dragging the corner scales the whole window.
local grip = CreateFrame("Button", nil, frame)
DJ.Size(grip, 16, 16)
grip:SetPoint("BOTTOMRIGHT", -3, 3)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetFrameLevel(frame:GetFrameLevel() + 20)
grip:RegisterForClicks("RightButtonUp")
grip:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" then return end
    local x = GetCursorPosition()
    self.startX, self.startScale = x, frame:GetScale()
    self:SetScript("OnUpdate", function()
        local cx = GetCursorPosition()
        local scale = self.startScale * (1 + (cx - self.startX) / (FRAME_W * UIParent:GetEffectiveScale() * self.startScale))
        DJ.SetScale(scale)
    end)
end)
grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
grip:SetScript("OnClick", function() DJ.SetScale(1) end)
grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Drag to scale the window\nRight-click to reset", 1, 1, 1)
    GameTooltip:Show()
end)
grip:SetScript("OnLeave", GameTooltip_Hide)

function DJ.SetScale(scale)
    scale = math.max(0.6, math.min(1.5, scale))
    DJ.db.scale = scale
    local left, top = frame:GetLeft(), frame:GetTop()
    local old = frame:GetScale()
    frame:SetScale(scale)
    if left and top then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * old / scale, top * old / scale)
        local point, _, relPoint, x, y = frame:GetPoint()
        DJ.db.point = { point, relPoint, x, y }
    end
    DJ.Fire("SCALE_CHANGED", scale)
end

function DJ.ResetPosition()
    DJ.db.point = nil
    DJ.db.scale = 1
    frame:SetScale(1)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
end

------------------------------------------------------------------------
-- Pages and history
------------------------------------------------------------------------
function DJ.RegisterPage(name, page)
    page:SetParent(body)
    page:SetAllPoints(body)
    page:Hide()
    DJ.pages[name] = page
end

local history = {}
local current

local function Show(name, state, noHistory)
    local samePage = current and current.name == name
        and (name ~= "instance" or (current.state and state and current.state.inst == state.inst))
    if current and not noHistory and not samePage then
        history[#history + 1] = current
        if #history > 30 then table.remove(history, 1) end
    end
    for n, p in pairs(DJ.pages) do
        if n ~= name then p:Hide() end
    end
    current = { name = name, state = state }
    local page = DJ.pages[name]
    page:Show()
    if page.Open then page:Open(state) end
    if #history > 0 then backButton:Enable() else backButton:Disable() end
    DJ.StyleButton(backButton)
    if not frame:IsShown() then frame:Show() end
end

function DJ.GoBack()
    local prev = table.remove(history)
    if prev then Show(prev.name, prev.state, true) end
end

function DJ.CurrentPage()
    return current and current.name
end

function DJ.ShowHome()
    DJ.ApplyTheme(DJ.THEMES.home)
    Show("home", {})
end

function DJ.OpenInstance(inst, bossIndex, mode, tab)
    if type(inst) == "string" then inst = DJ.GetInstance(inst) end
    if not inst then return end
    DJ.cdb.lastInstance = inst.key
    DJ.ApplyTheme(DJ.GetTheme(inst))
    Show("instance", { inst = inst, boss = bossIndex, mode = mode, tab = tab })
end

function DJ.ShowSearch(text, typing)
    if search:GetText() ~= text then search:SetText(text) end
    if current and current.name == "search" and typing then
        current.state.text = text
        DJ.pages.search:Open(current.state)
        return
    end
    DJ.ApplyTheme(DJ.THEMES.home)
    Show("search", { text = text })
end

function DJ.Open()
    if frame:IsShown() then return end
    if DJ.db.autoOpenCurrent then
        local inst, mode = DJ.CurrentInstance()
        if inst then
            DJ.OpenInstance(inst, nil, mode)
            return
        end
    end
    if current then
        frame:Show()
        return
    end
    DJ.ShowHome()
end

function DJ.Toggle()
    if frame:IsShown() then frame:Hide() else DJ.Open() end
end

-- Keybinding handler (Bindings.xml)
function DungeonJournal_Toggle()
    DJ.Toggle()
end

DJ.On("DB_READY", function()
    frame:SetScale(DJ.db.scale or 1)
    local p = DJ.db.point
    if p then
        frame:ClearAllPoints()
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    end
    DJ.ApplyTheme(DJ.THEMES.home)
end)

frame:SetScript("OnShow", function() PlaySound("igSpellBookOpen") end)
frame:SetScript("OnHide", function()
    PlaySound("igSpellBookClose")
    search:ClearFocus()
    DJ.Fire("FRAME_HIDDEN")
end)
