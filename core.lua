local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

f:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

-- nameplateShowEnemyGuardians = "0",
-- nameplateShowEnemyMinions   = "0",
-- nameplateShowEnemyMinus     = "0",
-- nameplateShowEnemyPets      = "1",
-- nameplateShowEnemyTotems    = "1",

local function GetUnitNPCID(unit)
    local guid = UnitGUID(unit)
    local _, _, _, _, _, npcID = strsplit("-", guid);
    return tonumber(npcID)
end

local totemNpcIDs = {
    -- [npcID] = { spellID, duration }
    [2630] = { 2484, 20 }, -- Earthbind
    [3527] = { 5394, 15 }, -- Healing Stream
    [6112] = { 8512, 120 }, -- Windfury
    [97369] = { 192222, 15 }, -- Liquid Magma
    [5913] = { 8143, 10 }, -- Tremor
    [5925] = { 204336, 3 }, -- Grounding
    [78001] = { 157153, 15 }, -- Cloudburst
    [53006] = { 98008, 6 }, -- Spirit Link
    [59764] = { 108280, 12 }, -- Healing Tide
    [61245] = { 192058, 2 }, -- Static Charge
    [100943] = { 198838, 15 }, -- Earthen Wall
    [97285] = { 192077, 15 }, -- Wind Rush
    [105451] = { 204331, 15 }, -- Counterstrike
    [104818] = { 207399, 30 }, -- Ancestral
    [105427] = { 204330, 15 }, -- Skyfury

    -- Warrior
    [119052] = { 236320, 15 }, -- War Banner
}

local function CreateIcon(nameplate)
    local frame = CreateFrame("Frame", nil, nameplate)
    frame:SetSize(63, 63)
    frame:SetPoint("BOTTOM", nameplate, "TOP", 0, 5)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetAllPoints()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.5)
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)

    frame.icon = icon
    frame.bg = bg

    return frame
end

function f.NAME_PLATE_UNIT_ADDED(self, event, unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    local npcID = GetUnitNPCID(unit)

    if npcID and totemNpcIDs[npcID] then
        if not np.NugTotemIcon then
            np.NugTotemIcon = CreateIcon(np)
        end

        local iconFrame = np.NugTotemIcon
        iconFrame:Show()

        local totemData = totemNpcIDs[npcID]
        local spellID, duration = unpack(totemData)

        local tex = GetSpellTexture(spellID)

        iconFrame.icon:SetTexture(tex)
    end
end

function f.NAME_PLATE_UNIT_REMOVED(self, event, unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if np.NugTotemIcon then
        np.NugTotemIcon:Hide()
    end
end
