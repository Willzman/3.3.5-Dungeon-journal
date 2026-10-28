-- Minimal mock of the WoW 3.3.5a client API, enough to load Dungeon Journal and
-- drive its UI from tools/test/run.py. Widget methods are a whitelist: calling a
-- method the 3.3.5a client does not have raises an error.

local METHODS = {
    -- Region / Frame
    "SetPoint", "ClearAllPoints", "SetAllPoints", "GetPoint", "SetWidth", "SetHeight", "SetSize", "GetWidth", "GetHeight",
    "Show", "Hide", "IsShown", "IsVisible", "SetParent", "GetParent", "GetName", "SetAlpha", "GetAlpha", "SetScale", "GetScale",
    "GetEffectiveScale", "GetLeft", "GetTop", "GetRight", "GetBottom", "GetCenter", "SetFrameStrata", "SetFrameLevel",
    "GetFrameLevel", "SetToplevel", "SetMovable", "EnableMouse", "EnableMouseWheel", "SetClampedToScreen", "RegisterForDrag",
    "StartMoving", "StopMovingOrSizing", "SetScript", "GetScript", "HookScript", "RegisterEvent", "UnregisterEvent",
    "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "CreateTexture", "CreateFontString", "SetHitRectInsets",
    "SetID", "GetID", "IsMouseOver", "SetResizable", "SetMinResize",
    -- Button
    "SetText", "GetText", "RegisterForClicks", "SetNormalTexture", "SetPushedTexture", "SetHighlightTexture",
    "SetDisabledTexture", "Enable", "Disable", "IsEnabled", "Click", "GetFontString", "SetFontString",
    -- CheckButton
    "SetChecked", "GetChecked",
    -- Texture
    "SetTexture", "GetTexture", "SetTexCoord", "SetVertexColor", "SetBlendMode", "SetGradientAlpha", "SetGradient",
    "SetDesaturated", "SetDrawLayer",
    -- FontString
    "SetFont", "GetFont", "SetTextColor", "SetJustifyH", "SetJustifyV", "GetStringWidth", "SetFontObject", "SetShadowOffset",
    "SetNonSpaceWrap",
    -- EditBox
    "SetAutoFocus", "SetMaxLetters", "ClearFocus", "SetFocus", "HighlightText",
    -- Slider
    "SetOrientation", "SetThumbTexture", "GetThumbTexture", "SetMinMaxValues", "GetMinMaxValues", "SetValue", "GetValue",
    "SetValueStep",
    -- Model / PlayerModel
    "SetCreature", "SetDisplayInfo", "SetCamera", "ClearModel", "GetModel", "SetFacing", "GetFacing", "SetModelScale",
    "SetPosition", "SetUnit",
    -- GameTooltip
    "SetOwner", "SetHyperlink", "AddLine", "AddDoubleLine", "NumLines", "IsOwned", "GetItem", "ClearLines",
    -- MessageFrame
    "AddMessage",
}
local ALLOWED = {}
for _, m in ipairs(METHODS) do ALLOWED[m] = true end

local frames = {}
local Widget = {}

local function new(kind, name, parent)
    local o = { kind = kind, name = name, parent = parent, shown = (kind ~= "Frame" and kind ~= "Button") or true,
        scripts = {}, w = 0, h = 0, points = {}, text = "", value = 0, min = 0, max = 0, checked = false,
        scale = 1, enabled = 1, lines = 0, facing = 0 }
    o.shown = true
    setmetatable(o, Widget)
    if name then _G[name] = o end
    frames[#frames + 1] = o
    return o
end

-- Unknown keys read as nil (custom fields); a call on one then fails like in the game.
UNKNOWN_KEYS = {}
Widget.__index = function(self, k)
    if ALLOWED[k] then return Widget[k] or function() end end
    UNKNOWN_KEYS[k] = true
    return nil
end

function Widget:SetWidth(w) rawset(self, "w", w) end
function Widget:SetHeight(h) rawset(self, "h", h) end
function Widget:SetSize(w, h) rawset(self, "w", w); rawset(self, "h", h) end
local function anchoredSize(self, field)
    local v = rawget(self, field)
    if v and v > 0 then return v end
    local p = rawget(self, "parent")
    if p and p ~= self then return anchoredSize(p, field) end
    return field == "w" and 860 or 560
end
function Widget:GetWidth() return anchoredSize(self, "w") end
function Widget:GetHeight() return anchoredSize(self, "h") end
function Widget:Show()
    local was = rawget(self, "shown")
    rawset(self, "shown", true)
    if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Widget:Hide()
    local was = rawget(self, "shown")
    rawset(self, "shown", false)
    if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Widget:IsShown() return rawget(self, "shown") and 1 or nil end
function Widget:IsVisible()
    local o = self
    while o do
        if not rawget(o, "shown") then return nil end
        o = rawget(o, "parent")
    end
    return 1
end
function Widget:SetScript(k, f) self.scripts[k] = f end
function Widget:GetScript(k) return self.scripts[k] end
function Widget:HookScript(k, f)
    local old = self.scripts[k]
    self.scripts[k] = function(...) if old then old(...) end f(...) end
end
function Widget:GetName() return rawget(self, "name") end
function Widget:GetParent() return rawget(self, "parent") end
function Widget:SetParent(p) rawset(self, "parent", p) end
function Widget:GetScale() return rawget(self, "scale") end
function Widget:SetScale(s) rawset(self, "scale", s) end
function Widget:GetEffectiveScale() return 1 end
function Widget:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function Widget:GetLeft() return 100 end
function Widget:GetTop() return 700 end
function Widget:GetCenter() return 500, 400 end
function Widget:GetFrameLevel() return 1 end
function Widget:CreateTexture(name, layer) return new("Texture", name, self) end
function Widget:CreateFontString(name) return new("FontString", name, self) end
function Widget:SetText(t) rawset(self, "text", t) end
function Widget:GetText() return rawget(self, "text") end
function Widget:GetStringWidth() return #(rawget(self, "text") or "") * 6 end
function Widget:GetFont() return "Fonts\\FRIZQT__.TTF", 12, "" end
function Widget:SetTexture(t)
    rawset(self, "texture", t)
    if type(t) == "string" and string.find(t, "MISSING") then return nil end
    return 1
end
function Widget:SetMinMaxValues(a, b) rawset(self, "min", a); rawset(self, "max", b) end
function Widget:GetMinMaxValues() return rawget(self, "min"), rawget(self, "max") end
function Widget:SetValue(v)
    rawset(self, "value", v)
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
end
function Widget:GetValue() return rawget(self, "value") end
function Widget:SetThumbTexture(t) rawset(self, "thumb", new("Texture", nil, self)) end
function Widget:GetThumbTexture() return rawget(self, "thumb") end
function Widget:SetChecked(c) rawset(self, "checked", c) end
function Widget:GetChecked() return rawget(self, "checked") and 1 or nil end
function Widget:IsEnabled() return rawget(self, "enabled") end
function Widget:Enable() rawset(self, "enabled", 1) end
function Widget:Disable() rawset(self, "enabled", nil) end
function Widget:GetModel() return rawget(self, "model") or self end
function Widget:SetCreature(id) rawset(self, "model", "Creature\\" .. id .. ".m2") end
function Widget:SetDisplayInfo(id) rawset(self, "model", "Display\\" .. id .. ".m2") end
function Widget:ClearModel() rawset(self, "model", nil) end
function Widget:GetFacing() return rawget(self, "facing") end
function Widget:SetFacing(f) rawset(self, "facing", f) end
function Widget:NumLines() return rawget(self, "lines") end
function Widget:AddLine() rawset(self, "lines", rawget(self, "lines") + 1) end
function Widget:SetOwner(o) rawset(self, "owner", o); rawset(self, "lines", 1) end
function Widget:IsOwned(o) return rawget(self, "owner") == o end
function Widget:GetItem() return rawget(self, "itemName"), rawget(self, "itemLink") end
function Widget:SetHyperlink(link)
    rawset(self, "itemLink", link)
    rawset(self, "lines", 3)
    if self.scripts.OnTooltipSetItem then self.scripts.OnTooltipSetItem(self) end
end
function Widget:AddMessage(msg) print("[chat] " .. msg) end

function CreateFrame(kind, name, parent, template)
    local f = new(kind, name, parent)
    if kind == "EditBox" then rawset(f, "text", "") end
    if template == "OptionsSliderTemplate" and name then
        new("FontString", name .. "Text", f); new("FontString", name .. "Low", f); new("FontString", name .. "High", f)
    end
    if template == "GameTooltipTemplate" and name then
        for i = 1, 30 do new("FontString", name .. "TextLeft" .. i, f) end
    end
    return f
end

UIParent = new("Frame", "UIParent")
Minimap = new("Frame", "Minimap")
GameTooltip = CreateFrame("GameTooltip", "GameTooltip", UIParent)
ItemRefTooltip = CreateFrame("GameTooltip", "ItemRefTooltip", UIParent)
ShoppingTooltip1 = CreateFrame("GameTooltip", "ShoppingTooltip1", UIParent)
ShoppingTooltip2 = CreateFrame("GameTooltip", "ShoppingTooltip2", UIParent)
InterfaceOptionsFrame = new("Frame", "InterfaceOptionsFrame")
DEFAULT_CHAT_FRAME = new("MessageFrame", "ChatFrame1")
UISpecialFrames = {}
SlashCmdList = {}
ITEM_QUALITY_COLORS = {}
for i = 0, 7 do ITEM_QUALITY_COLORS[i] = { r = 1, g = 1, b = 1, hex = "|cffffffff" } end
ITEM_CLASSES_ALLOWED = "Classes: %s"
INVTYPE_HEAD, INVTYPE_CLOAK, INVTYPE_WEAPON = "Head", "Back", "One-Hand"

local now = 0
function GetTime() return now end
function AdvanceTime(dt)
    now = now + dt
    for _, f in ipairs(frames) do
        if rawget(f, "shown") and f.scripts.OnUpdate then f.scripts.OnUpdate(f, dt) end
    end
end
function time() return 1700000000 end

-- Items: odd IDs are "cached", even IDs are not until requested once.
local requested = {}
function GetItemInfo(id)
    if type(id) == "string" then id = tonumber(string.match(id, "item:(%d+)")) end
    if not id then return nil end
    if id % 2 == 1 or requested[id] then
        return "Item " .. id, "|cff0070dd|Hitem:" .. id .. ":0:0:0:0:0:0:0:80|h[Item " .. id .. "]|h|r", 3, 200, 80,
            "Armor", "Plate", 1, "INVTYPE_HEAD", "Interface\\Icons\\INV_Misc_QuestionMark", 100
    end
    return nil
end
local origSetHyperlink = Widget.SetHyperlink
function Widget:SetHyperlink(link)
    local id = tonumber(string.match(link, "item:(%d+)"))
    if id then requested[id] = true end
    return origSetHyperlink(self, link)
end
function GetItemIcon(id) return "Interface\\Icons\\INV_Misc_QuestionMark" end
function GetItemCount() return 0 end
function GetAuctionItemSubClasses(i)
    if i == 1 then return "One-Handed Axes", "Two-Handed Axes", "Bows", "Guns", "One-Handed Maces", "Two-Handed Maces",
        "Polearms", "One-Handed Swords", "Two-Handed Swords", "Staves", "Fist Weapons", "Miscellaneous", "Daggers", "Thrown",
        "Crossbows", "Wands", "Fishing Poles" end
    return "Miscellaneous", "Cloth", "Leather", "Mail", "Plate", "Shields", "Librams", "Idols", "Totems", "Sigils"
end
function GetAuctionItemClasses()
    return "Weapon", "Armor", "Container", "Consumable", "Glyph", "Trade Goods", "Projectile", "Quiver", "Recipe", "Gem",
        "Miscellaneous", "Quest"
end
PLAYER_CLASS = "PRIEST"
function UnitClass() return "Priest", PLAYER_CLASS end
function UnitFactionGroup() return "Horde" end
INSTANCE = nil
function IsInInstance() if INSTANCE then return 1, INSTANCE[2] end return nil, "none" end
function GetInstanceInfo() if INSTANCE then return INSTANCE[1], INSTANCE[2], INSTANCE[3] end return "Orgrimmar", "none", 0 end
function GetRealZoneText() return INSTANCE and INSTANCE[1] or "Orgrimmar" end
function GetSubZoneText() return INSTANCE and INSTANCE[4] or "" end
local LFG = { [18] = { "Utgarde Keep", "UTGARDEKEEP" }, [4] = { "Ragefire Chasm", "RAGEFIRECHASM" },
    [26] = { "Scarlet Monastery - Graveyard", "SCARLETMONASTERY" }, [280] = { "Icecrown Citadel", "MISSINGICC" } }
function GetLFGDungeonInfo(id)
    local d = LFG[id]
    if not d then return nil end
    return d[1], 1, 15, 21, 18, 16, 21, 0, 0, d[2], 0, 5, "", false
end
function PlaySound() end
function GetCursorPosition() return 500, 400 end
function IsShiftKeyDown() return nil end
function IsModifiedClick() return nil end
function HandleModifiedItemClick(link) LAST_MODIFIED_LINK = link end
function InterfaceOptions_AddCategory(p) OPTIONS_PANEL = p end
function InterfaceOptionsFrame_OpenToCategory(p) OPTIONS_OPENED = p end
function GameTooltip_Hide() GameTooltip:Hide() end
function GameTooltip_ShowCompareItem() end
function strtrim(s) return (string.gsub(s or "", "^%s*(.-)%s*$", "%1")) end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
math.atan2 = math.atan2 or math.atan

function FireEvent(event, ...)
    for _, f in ipairs(frames) do
        if f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
end

function Click(f, button)
    assert(f.scripts.OnClick, "no OnClick on " .. tostring(rawget(f, "kind")))
    f.scripts.OnClick(f, button or "LeftButton")
end

function AllFrames() return frames end
