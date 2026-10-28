-- Minimap button: left-click toggles the journal, right-click opens the options, drag to move.
local DJ = DungeonJournal
local L = DJ.L

local button = CreateFrame("Button", "DungeonJournalMinimapButton", Minimap)
DJ.Size(button, 31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local icon = button:CreateTexture(nil, "BACKGROUND")
DJ.Size(icon, 20, 20)
icon:SetPoint("TOPLEFT", 7, -5)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
local border = button:CreateTexture(nil, "OVERLAY")
DJ.Size(border, 53, 53)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdatePosition()
    local angle = math.rad(DJ.db.minimap.angle or 205)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
end

button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        DJ.db.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
        UpdatePosition()
    end)
end)
button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then DJ.OpenOptions() else DJ.Toggle() end
end)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(L.TITLE, 1, 0.82, 0)
    GameTooltip:AddLine(L.MINIMAP_TIP, 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", GameTooltip_Hide)

function DJ.UpdateMinimapButton()
    if DJ.db.minimap.show then
        UpdatePosition()
        button:Show()
    else
        button:Hide()
    end
end

DJ.On("DB_READY", DJ.UpdateMinimapButton)
