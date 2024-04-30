local addonName, ns = ...

local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)


local activeTotems = {}
local totemStartTimes = setmetatable({ __mode = "v" }, {})

local defaults = {
    showDuration = true,
    showCooldownCount = false,
    showFriendlyTotems = true,
    size = 63,
    nameplateOffsetY = 0,
}

local db

-- /script SetCVar("nameplateShowFriendlyTotems", 1)

-- nameplateShowEnemyGuardians = "0",
-- nameplateShowEnemyMinions   = "0",
-- nameplateShowEnemyMinus     = "0",
-- nameplateShowEnemyTotems    = "1",
-- nameplateShowEnemyPets      = "1",
local APILevel = math.floor(select(4,GetBuildInfo())/10000)

function f.PLAYER_LOGIN(self)
    _G.NugTotemIconDB = _G.NugTotemIconDB or {}
    -- self:DoMigrations(NugTotemIconDB)
    -- self.db = LibStub("AceDB-3.0"):New("NugTotemIconDB", defaults, "Default")
    db = _G.NugTotemIconDB
    ns.SetupDefaults(_G.NugTotemIconDB, defaults)

    SLASH_NUGTOTEMICON1= "/nugtotemicon"
    SLASH_NUGTOTEMICON2= "/nti"
    SlashCmdList["NUGTOTEMICON"] = self.SlashCmd
end


local function GetNPCIDByGUID(guid)
    local _, _, _, _, _, npcID = strsplit("-", guid);
    return tonumber(npcID)
end

local totemNpcIDs
if APILevel >= 8 then
    totemNpcIDs = {
        -- [npcID] = { spellID, duration }
        [2630] = { 2484, 20 }, -- Earthbind
        [60561] = { 51485, 20 }, -- Earthgrab
        [3527] = { 5394, 15 }, -- Healing Stream
        [6112] = { 8512, 120 }, -- Windfury
        [97369] = { 192222, 6 }, -- Liquid Magma
        [5913] = { 8143, 10 }, -- Tremor
        [5925] = { 204336, 3 }, -- Grounding
        [78001] = { 157153, 15 }, -- Cloudburst
        [53006] = { 98008, 6 }, -- Spirit Link
        [59764] = { 108280, 12 }, -- Healing Tide
        [61245] = { 192058, 2 }, -- Static Charge/Capacitor Totem
        [100943] = { 198838, 15 }, -- Earthen Wall
        [97285] = { 192077, 15 }, -- Wind Rush
        [105451] = { 204331, 15 }, -- Counterstrike
        [104818] = { 207399, 30 }, -- Ancestral
        [105427] = { 204330, 15 }, -- Skyfury
        [179867] = { 355580, 6 }, -- Static Field
        [166523] = { 324386, 30 }, -- Vesper Totem (Kyrian)

        -- 10.0
        [194117] = { 383017, 15 }, -- Stoneskin Totem
        [194118] = { 383019, 60 }, -- Tranquil Air Totem
        [5923] = { 383013, 6 }, -- Poison Cleansing Totem
        [193620] = { 381930, 120 }, -- Mana Spring Totem

        -- Warrior
        [119052] = { 236320, 15 }, -- War Banner

        -- Priest
        [101398] = { 211522, 12 }, -- Psyfiend

        -- Warlock
        [179193] = { 353601, 15 }, -- Fel Obelisk
        [107100] = { 201996, 20 }, -- Call Observer
    }
elseif APILevel == 4 then
    -- Added Spirit Link
    -- Removed Ranks
    -- Removed Sentry Totem, Totem of Wrath, Fire/Frost/Nature Resistance Totem
    -- Wrath of Air now 5m
    -- Magma now 1m
    totemNpcIDs = {
        -- [npcID] = { spellID, duration }
        [2630] = { 2484, 45 }, -- Earthbind
        [5925] = { 8177, 45 }, -- Grounding
        [15430] = { 2062, 120 }, -- Earth Elemental Totem
        [15439] = { 2894, 120 }, -- Fire Elemental Totem
        [15447] = { 3738, 300 }, -- Wrath of Air Totem
        [5913] = { 8143, 300 }, -- Tremor
        [53006] = { 98008, 6 }, -- Spirit Link
        [10467] = { 16190, 12 }, -- Mana Tide Totem
        [5924] = { 54968, 300 }, -- Cleansing Totem

        [3573] = { 5675, 300 }, -- Mana Spring Totem
        [5929] = { 8187, 60 }, -- Magma Totem
        [2523] = { 3599, 60 }, -- Searing Totem
        [3579] = { 5730, 15 }, -- Stoneclaw Totem
        [5950] = { 8227, 300 }, -- Flametongue Totem
        [5873] = { 8071, 300 }, -- Stoneskin Totem
        [5874] = { 31634, 300 }, -- Strength of Earth
        [6112] = { 8512, 300 }, -- Windfury Totem
        [3527] = { 5394, 300 }, -- Healing Stream Totem
    }
elseif APILevel == 3 then
    totemNpcIDs = {
        -- [npcID] = { spellID, duration }
        [2630] = { 2484, 45 }, -- Earthbind
        [5925] = { 8177, 45 }, -- Grounding
        [3968] = { 6495, 300 }, -- Sentry
        [15430] = { 2062, 120 }, -- Earth Elemental Totem
        [15439] = { 2894, 120 }, -- Fire Elemental Totem
        [15447] = { 3738, 120 }, -- Wrath of Air Totem
        [5913] = { 8143, 300 }, -- Tremor
        [10467] = { 16190, 12 }, -- Mana Tide Totem
        [5924] = { 54968, 300 } -- Cleansing Totem
    }
    local function addTotem(data, ...)
        local numArgs = select("#",...)
        for i=1, numArgs do
            local npcID = select(i, ...)
            totemNpcIDs[npcID] = data
        end
    end

    addTotem({ 30706, 300 }, 17539, 30652, 30653, 30654) -- Totem of Wrath
    addTotem({ 5675, 300 }, 3573, 7414, 7415, 7416, 15489, 31186, 31189, 31190) -- Mana Spring Totem
    addTotem({ 8187, 20 }, 5929, 7464, 7465, 7466, 15484, 31166, 31167) -- Magma Totem
    addTotem({ 3599, 60 }, 2523, 3902, 3903, 3904, 7400, 7402, 15480, 31162, 31164, 31165) -- Searing Totem
    addTotem({ 5730, 15 }, 3579, 3911, 3912, 3913, 7398, 7399, 15478, 31120, 31121, 31122) -- Stoneclaw Totem
    addTotem({ 8184, 300 }, 5927, 7424, 7425, 15487, 31169, 31170) -- Fire Resistance Totem
    addTotem({ 8227, 300 }, 5950, 6012, 7423, 10557, 15485, 31132, 31133, 31158) -- Flametongue Totem
    addTotem({ 8181, 300 }, 5926, 7412, 7413, 15486, 31171, 31172) -- Frost Resistance Totem
    addTotem({ 10595, 300 }, 7467, 7468, 7469, 15490, 31173, 31174) -- Nature Resistance Totem
    addTotem({ 8071, 300 }, 5873, 5919, 5920, 7366, 7367, 7368, 15470, 15474, 31175, 31176) -- Stoneskin Totem
    addTotem({ 31634, 300 }, 5874, 5921, 5922, 7403, 15464, 15479, 30647, 31129) -- Strength of Earth
    addTotem({ 8512, 300 }, 6112) -- Windfury Totem
    addTotem({ 5394, 300 }, 3527, 3906, 3907, 3908, 3909, 15488, 31181, 31181, 31185) -- Healing Stream Totem
elseif APILevel <= 2 then
    totemNpcIDs = {
        -- [npcID] = { spellID, duration }
        [2630] = { 2484, 20 }, -- Earthbind
        [5925] = { 8177, 45 }, -- Grounding
        [3968] = { 6495, 300 }, -- Sentry
        [15430] = { 2062, 120 }, -- Earth Elemental Totem
        [15439] = { 2894, 120 }, -- Fire Elemental Totem
        [15447] = { 3738, 120 }, -- Wrath of Air Totem
        [17539] = { 30706, 120 }, -- Totem of Wrath
        [5924] = { 8170, 120 }, -- Disease Cleansing Totem
        [5923] = { 8166, 120 }, -- Poison Cleansing Totem
        [15803] = { 25908, 120 }, -- Tranquil Air Totem
        [5913] = { 8143, 120 }, -- Tremor
        [10467] = { 16190, 12 }, -- Mana Tide Totem
    }
    local function addTotem(data, ...)
        local numArgs = select("#",...)
        for i=1, numArgs do
            local npcID = select(i, ...)
            totemNpcIDs[npcID] = data
        end
    end

    addTotem({ 5675, 120 }, 3573, 7414, 7415, 7416, 15489) -- Mana Spring Totem
    addTotem({ 1535, 5 }, 5879,  6110, 6111, 7844, 7845, 15482, 15483) -- Fire Nova Totem
    addTotem({ 8187, 20 }, 5929, 7464, 7465, 7466, 15484) -- Magma Totem
    addTotem({ 3599, 60 }, 2523, 3902, 3903, 3904, 7400, 7402, 15480) -- Searing Totem
    addTotem({ 5730, 15 }, 3579, 3911, 3912, 3913, 7398, 7399, 15478) -- Stoneclaw Totem
    addTotem({ 8184, 120 }, 5927, 7424, 7425, 15487) -- Fire Resistance Totem
    addTotem({ 8227, 120 }, 5950, 6012, 7423, 10557, 15485) -- Flametongue Totem
    addTotem({ 8181, 120 }, 5926, 7412, 7413, 15486) -- Frost Resistance Totem
    addTotem({ 8835, 120 }, 7486, 7487, 15463) -- Grace of Air Totem
    addTotem({ 10595, 120 }, 7467, 7468, 7469, 15490) -- Nature Resistance Totem
    addTotem({ 8071, 120 }, 5873, 5919, 5920, 7366, 7367, 7368, 15470, 15474) -- Stoneskin Totem
    addTotem({ 31634, 300 }, 5874, 5921, 5922, 7403, 15464, 15479) -- Strength of Earth
    addTotem({ 8512, 120 }, 6112, 7483, 7484, 15496, 15497) -- Windfury Totem
    addTotem({ 15107, 120 }, 9687, 9688, 9689, 15492) -- Windwall Totem
    addTotem({ 5394, 120 }, 3527, 3906, 3907, 3908, 3909, 15488) -- Healing Stream Totem
end

local function CreateIcon(nameplate)
    local frame = CreateFrame("Frame", nil, nameplate)
    frame:SetSize(db.size, db.size)
    frame:SetPoint("BOTTOM", nameplate, "TOP", 0, 5+db.nameplateOffsetY)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetAllPoints()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    bg:SetVertexColor(0, 0, 0, 0.5)
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)

    local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    if not db.showCooldownCount then
        cd.noCooldownCount = true -- disable OmniCC for this cooldown
        cd:SetHideCountdownNumbers(true)
    end
    cd:SetReverse(true)
    cd:SetDrawEdge(false)
    cd:SetAllPoints(frame)

    frame.cooldown = cd
    frame.icon = icon
    frame.bg = bg

    return frame
end

function f.NAME_PLATE_UNIT_ADDED(self, event, unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    local guid = UnitGUID(unit)
    local npcID = GetNPCIDByGUID(guid)

    if npcID and totemNpcIDs[npcID] then
        if not db.showFriendlyTotems then
            -- local isAttackable = UnitCanAttack("player", unit)
            local isFriendly = UnitReaction(unit, "player") >= 4
            if isFriendly then return end
        end

        if not np.NugTotemIcon then
            np.NugTotemIcon = CreateIcon(np)
        end

        local iconFrame = np.NugTotemIcon
        iconFrame:Show()
        iconFrame:SetSize(db.size, db.size)
        iconFrame:SetPoint("BOTTOM", np, "TOP", 0, 5+db.nameplateOffsetY)

        local totemData = totemNpcIDs[npcID]
        local spellID, duration = unpack(totemData)

        local tex = GetSpellTexture(spellID)

        iconFrame.icon:SetTexture(tex)
        local startTime = totemStartTimes[guid]
        if startTime and db.showDuration then
            iconFrame.cooldown:SetCooldown(startTime, duration)
            iconFrame.cooldown:Show()
        end

        activeTotems[guid] = np
    end
end

function f.NAME_PLATE_UNIT_REMOVED(self, event, unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if np.NugTotemIcon then
        np.NugTotemIcon:Hide()

        local guid = UnitGUID(unit)
        activeTotems[guid] = nil
    end
end

function f:COMBAT_LOG_EVENT_UNFILTERED(event, unit)
    local timestamp, eventType, hideCaster,
    srcGUID, srcName, srcFlags, srcFlags2,
    dstGUID, dstName, dstFlags, dstFlags2 = CombatLogGetCurrentEventInfo()

    if eventType == "SPELL_SUMMON" then
        local npcID = GetNPCIDByGUID(dstGUID)
        if npcID and totemNpcIDs[npcID] then
            totemStartTimes[dstGUID] = GetTime()
        end
    end
end


local ParseOpts = function(str)
    local t = {}
    local capture = function(k,v)
        t[k:lower()] = tonumber(v) or v
        return ""
    end
    str:gsub("(%w+)%s*=%s*%[%[(.-)%]%]", capture):gsub("(%w+)%s*=%s*(%S+)", capture)
    return t
end

f.Commands = {
    ["duration"] = function(v)
        db.showDuration = not db.showDuration
    end,
    ["cooldowncount"] = function(v)
        db.showCooldownCount = not db.showCooldownCount
    end,
    ["friendly"] = function(v)
        db.showFriendlyTotems = not db.showFriendlyTotems
    end,
    ["cvarShowEnemyTotems"] = function(v)
        if GetCVar("nameplateShowEnemyTotems") == "1" then
            SetCVar("nameplateShowEnemyTotems", "0")
        else
            SetCVar("nameplateShowEnemyTotems", "1")
        end
    end,
    ["cvarShowFriendlyTotems"] = function(v)
        if GetCVar("nameplateShowFriendlyTotems") == "1" then
            SetCVar("nameplateShowFriendlyTotems", "0")
        else
            SetCVar("nameplateShowFriendlyTotems", "1")
        end
    end,
    ["size"] = function(v)
        local newSize = tonumber(v)
        if newSize then
            db.size = newSize
        end
    end,
    ["yoffset"] = function(v)
        local yOffset = tonumber(v)
        if yOffset then
            db.nameplateOffsetY = yOffset
        end
    end,
}

function f.SlashCmd(msg)
    local helpMessage = {
        "|cff00ffbb/nti duration|r",
        "|cff00ffbb/nti cooldowncount|r",
        "|cff00ffbb/nti friendly|r",
        "|cff00ffbb/nti size 63|r",
        "|cff00ffbb/nti yoffset 5|r",
        "|cff00ffbb/nti cvarShowEnemyTotems|r",
        "|cff00ffbb/nti cvarShowFriendlyTotems|r",
    }

    local k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then
        print("Usage:")
        for k,v in ipairs(helpMessage) do
            print(" - ",v)
        end
    end
    if f.Commands[k] then
        f.Commands[k](v)
    end
end



function ns.SetupDefaults(t, defaults)
    if not defaults then return end
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            elseif t[k] == false then
                t[k] = false --pass
            else
                ns.SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end

function ns.RemoveDefaults(t, defaults)
    if not defaults then return end
    for k, v in pairs(defaults) do
        if type(t[k]) == 'table' and type(v) == 'table' then
            ns.RemoveDefaults(t[k], v)
            if next(t[k]) == nil then
                t[k] = nil
            end
        elseif t[k] == v then
            t[k] = nil
        end
    end
    return t
end
