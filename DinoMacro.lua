-- DinoMacro 1.4.17 - Exakte Makronamen, In-Place Bearbeitung ohne Duplikate & Saubere Neugenerierung
-- Created by X4rinia
-- Created by X4rinia
-- Basiert auf DinoMacroManager 1.1.5 von x4rinia.
-- Author: X4rinia

local addonName, addonTable = ...;
local DM = addonTable or _G.DinoMacro or {};
_G.DinoMacro = DM;

DM.VERSION = 1417;
DM.VERSION_STRING = "1.4.17";
DM.AUTHOR_SIGNATURE = "by X4rinia";
DM.sessionAnnounced = false;
DM.SLOT_COUNT = 14;
DM.MIN_SPELLS = 0;
DM.MAX_SPELLS = 4;
DM.DEFAULT_RESET = 10;
DM.MACRO_MAX_CHARS = 255;
DM.QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark";
DM.PET_ATTACK_ICON_ID = 132164;
DM.PET_ATTACK_TEXTURE = "Interface\\Icons\\Ability_Hunter_Pet_Attack";
DM.TRINKET_ICON_ID = 133405;
DM.TRINKET_TEXTURE = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01";

-- UI-Instanzen
DM.mainFrame = nil;
DM.slotButtons = {};
DM.editorFields = {};

-- Aktiver Status
DM.selectedSlot = 1;
DM.editorSpells = {};
DM.activeTab = "editor"; -- "editor", "preview"
DM.previewMode = "current"; -- "current", "all"
DM.pendingSlots = {};
DM.updateElapsed = 0;

-- Backdrops benoetigen im modernen Client das BackdropTemplate.
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil;

---------------------------------------------------------------------------
-- Zentrale API-Kompatibilitaets-Helper & Makro-Engine (1.4.10)
---------------------------------------------------------------------------
function DM.IsDebug()
    return (DinoMacroDB and DinoMacroDB.debug == true);
end

function DM.DebugLog(msg, ...)
    if not DM.IsDebug() then return; end
    local text = msg;
    if ... ~= nil then
        local ok, formatted = pcall(string.format, msg, ...);
        if ok and formatted then text = formatted; end
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[DinoMacro Debug]|r " .. tostring(text));
    end
end

local function GetInventoryItemCompat(slotId)
    if not slotId then return nil, nil, nil; end
    local texture = (GetInventoryItemTexture and GetInventoryItemTexture("player", slotId)) or nil;
    local link = (GetInventoryItemLink and GetInventoryItemLink("player", slotId)) or nil;
    local name = nil;
    if link then
        name = string.match(link, "%[(.+)%]");
    end
    return texture, name, link;
end

local function GetItemInfoCompat(item)
    if not item then return nil; end
    if C_Item and C_Item.GetItemInfo then
        local ok, name, link, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture = pcall(C_Item.GetItemInfo, item);
        if ok and name then
            return name, link, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture;
        end
    end
    if GetItemInfo then
        local ok, name, link, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture = pcall(GetItemInfo, item);
        if ok and name then
            return name, link, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture;
        end
    end
    return nil;
end

local function GetItemIconCompat(item)
    if not item then return nil; end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, item);
        if ok and icon then return icon; end
    end
    if GetItemIcon then
        local ok, icon = pcall(GetItemIcon, item);
        if ok and icon then return icon; end
    end
    return nil;
end

-- Robust fuer Mehrfach-Rueckgabewerte UND Tabellen in modernen/Forever-Clients
local function GetSpellCooldownCompat(spell)
    if not spell then return 0, 0, 0; end
    if C_Spell and C_Spell.GetSpellCooldown then
        local sID = (type(spell) == "number") and spell or (C_Spell.GetSpellIDForSpellIdentifier and C_Spell.GetSpellIDForSpellIdentifier(spell));
        if sID then
            local ok, info = pcall(C_Spell.GetSpellCooldown, sID);
            if ok and type(info) == "table" and info.startTime then
                local en = (info.isEnabled == nil or info.isEnabled == true or info.isEnabled == 1) and 1 or 0;
                return info.startTime or 0, info.duration or 0, en;
            end
        end
    end
    if GetSpellCooldown then
        local ok, a, b, c = pcall(GetSpellCooldown, spell);
        if ok then
            if type(a) == "table" and a.startTime then
                local en = (a.isEnabled == nil or a.isEnabled == true or a.isEnabled == 1) and 1 or 0;
                return a.startTime or 0, a.duration or 0, en;
            elseif type(a) == "number" then
                return a or 0, b or 0, c or 1;
            end
        end
    end
    return 0, 0, 0;
end

local function GetInventoryItemCooldownCompat(slotId)
    if not slotId then return 0, 0, 0; end
    if GetInventoryItemCooldown then
        local ok, a, b, c = pcall(GetInventoryItemCooldown, "player", slotId);
        if ok then
            if type(a) == "table" and a.startTime then
                local en = (a.isEnabled == nil or a.isEnabled == true or a.isEnabled == 1) and 1 or 0;
                return a.startTime or 0, a.duration or 0, en;
            elseif type(a) == "number" then
                return a or 0, b or 0, c or 1;
            end
        end
    end
    return 0, 0, 0;
end

local function GetItemCooldownCompat(itemId)
    if not itemId then return 0, 0, 0; end
    if C_Container and C_Container.GetItemCooldown then
        local ok, a, b, c = pcall(C_Container.GetItemCooldown, itemId);
        if ok then
            if type(a) == "table" and a.startTime then
                local en = (a.isEnabled == nil or a.isEnabled == true or a.isEnabled == 1) and 1 or 0;
                return a.startTime or 0, a.duration or 0, en;
            elseif type(a) == "number" then
                return a or 0, b or 0, c or 1;
            end
        end
    end
    if GetItemCooldown then
        local ok, a, b, c = pcall(GetItemCooldown, itemId);
        if ok then
            if type(a) == "table" and a.startTime then
                local en = (a.isEnabled == nil or a.isEnabled == true or a.isEnabled == 1) and 1 or 0;
                return a.startTime or 0, a.duration or 0, en;
            elseif type(a) == "number" then
                return a or 0, b or 0, c or 1;
            end
        end
    end
    return 0, 0, 0;
end

-- 1.4.12: Sichere Berechnung verbleibender Cooldown-Zeit ohne Secret-Value-Absturz
local function SafeGetCooldownRemain(start, duration, enable)
    if not start or not duration or enable == false or enable == 0 then
        return nil;
    end
    -- pcall dient als Standard-Fehlerbehandlung fuer geschuetzte Rueckgabewerte (Secret Values).
    -- Falls duration ein Secret Value ist, bricht die Lua-Arithmetik/Vergleich im pcall sauber ab,
    -- ohne den OnUpdate-Zyklus zu zerstoeren. Eigene Zahlenanzeige bleibt dann deaktiviert.
    local ok, remain = pcall(function()
        if duration > 1.5 then
            local rem = (start + duration) - GetTime();
            if rem > 0 then
                return rem;
            end
        end
        return nil;
    end);
    if ok and remain then
        return remain;
    end
    return nil;
end

-- 1.4.12: Sicherer Cooldown-Setter fuer CooldownFrame-Widgets (nimmt Secret Values nativ entgegen)
local function SetCooldownCompat(cooldown, spellID)
    if not cooldown then return; end
    if not spellID then
        pcall(cooldown.SetCooldown, cooldown, 0, 0);
        return;
    end
    local start, duration, enable = GetSpellCooldownCompat(spellID);
    if enable == false or enable == 0 or not start or not duration then
        pcall(cooldown.SetCooldown, cooldown, 0, 0);
    else
        pcall(cooldown.SetCooldown, cooldown, start, duration);
    end
end

---------------------------------------------------------------------------
-- Formatierung fuer numerische Cooldown-Anzeige (<10s: 8.4, <60s: 24, <3600s: 1:25, sonst 1h)
---------------------------------------------------------------------------
function DM.FormatCooldownTime(remain)
    if not remain or remain <= 0 then return ""; end
    if remain < 10 then
        return string.format("%.1f", remain);
    elseif remain < 60 then
        return string.format("%d", math.floor(remain + 0.5));
    elseif remain < 3600 then
        local m = math.floor(remain / 60);
        local s = math.floor(remain % 60);
        return string.format("%d:%02d", m, s);
    else
        local h = math.floor(remain / 3600);
        return string.format("%dh", h);
    end
end

---------------------------------------------------------------------------
-- Sichere Makro-Icon-Konvertierung & Failsafe fuer CreateMacro / EditMacro
---------------------------------------------------------------------------
function DM.CleanMacroIcon(icon)
    if not icon then return "INV_MISC_QUESTIONMARK"; end
    if type(icon) == "number" and icon > 0 then
        return icon;
    end
    local s = tostring(icon);
    local n = tonumber(s);
    if n and n > 0 then return n; end

    -- Entferne Dateipfade (z.B. Interface\\Icons\\) und Dateiendungen (.blp)
    local clean = s:gsub("^[iI][nN][tT][eE][rR][fF][aA][cC][eE][/\][iI][cC][oO][nN][sS][/\]", "");
    clean = clean:gsub("^.*[/\]", "");
    clean = clean:gsub("%.[bB][lL][pP]$", "");
    if clean ~= "" then
        return clean;
    end
    return "INV_MISC_QUESTIONMARK";
end

function DM.SafeSetSlotTexture(iconWidget, icon)
    if not iconWidget then return; end
    if not icon then
        iconWidget:SetTexture(DM.QUESTION_ICON);
        return;
    end
    pcall(iconWidget.SetTexture, iconWidget, icon);
    -- Falls die Textur im Client nicht sofort geladen werden konnte, Fallback pruefen
    if not iconWidget:GetTexture() then
        if icon == DM.PET_ATTACK_ICON_ID or icon == "132164" or icon == "Ability_Hunter_Pet_Attack" then
            pcall(iconWidget.SetTexture, iconWidget, DM.PET_ATTACK_TEXTURE);
        elseif icon == DM.TRINKET_ICON_ID or icon == "133405" or icon == "INV_Jewelry_TrinketPVP_01" then
            pcall(iconWidget.SetTexture, iconWidget, DM.TRINKET_TEXTURE);
        else
            pcall(iconWidget.SetTexture, iconWidget, DM.QUESTION_ICON);
        end
    end
end

---------------------------------------------------------------------------
-- Makro-Verwaltung & Exakte Namensbindung (1.4.17)
---------------------------------------------------------------------------
function DM.GetSlotMacroName(slotIndex)
    local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[slotIndex];
    local rawName = (slot and slot.name and strtrim(slot.name) ~= "") and strtrim(slot.name) or ("DM_" .. slotIndex);
    -- Blizzard erlaubt maximal 16 Zeichen fuer Makronamen
    if string.len(rawName) > 16 then
        rawName = string.sub(rawName, 1, 16);
    end
    return rawName;
end

function DM.FindSlotMacro(slotIndex)
    local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[slotIndex];
    local targetName = DM.GetSlotMacroName(slotIndex);
    local savedName = slot and slot.savedMacroName;
    local defaultName = "DM_" .. slotIndex;

    local namesToTry = { targetName };
    if savedName and savedName ~= targetName then
        table.insert(namesToTry, savedName);
    end
    if defaultName ~= targetName and defaultName ~= savedName then
        table.insert(namesToTry, defaultName);
    end

    -- 1. GetMacroIndexByName Schnellsuche
    if GetMacroIndexByName then
        for _, n in ipairs(namesToTry) do
            local idx = GetMacroIndexByName(n);
            if idx and idx > 0 then return idx, n; end
        end
    end

    -- 2. Vollstaendige Pruefung aller Makros (Global 1-120 + Char 121-138)
    local maxSearch = 138;
    if MAX_ACCOUNT_MACROS and MAX_CHARACTER_MACROS then
        maxSearch = MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS;
    end
    for i = 1, maxSearch do
        local mName = GetMacroInfo(i);
        if mName then
            for _, n in ipairs(namesToTry) do
                if mName == n then
                    return i, mName;
                end
            end
        end
    end

    return 0, nil;
end

function DM.CleanupDuplicateMacros(slotIndex, keepIndex)
    local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[slotIndex];
    local targetName = DM.GetSlotMacroName(slotIndex);
    local savedName = slot and slot.savedMacroName;
    local defaultName = "DM_" .. slotIndex;

    local names = { targetName };
    if savedName and savedName ~= targetName then table.insert(names, savedName); end
    if defaultName ~= targetName and defaultName ~= savedName then table.insert(names, defaultName); end

    local maxSearch = 138;
    if MAX_ACCOUNT_MACROS and MAX_CHARACTER_MACROS then
        maxSearch = MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS;
    end

    -- Rueckwaerts durchsuchen und Duplikate entfernen
    for i = maxSearch, 1, -1 do
        if i ~= keepIndex then
            local mName = GetMacroInfo(i);
            if mName then
                for _, n in ipairs(names) do
                    if mName == n then
                        if not InCombatLockdown() then
                            pcall(DeleteMacro, i);
                            DM.DebugLog("Duplicate macro deleted: %s at index %d", mName, i);
                        end
                        break;
                    end
                end
            end
        end
    end
end

function DM.SafeCreateOrEditMacro(slotIndex, preferredIcon, body)
    if InCombatLockdown and InCombatLockdown() then
        return false, DM.L("ERR_COMBAT_LOCKDOWN");
    end

    local slot = DinoMacroDB.slots[slotIndex];
    local targetName = DM.GetSlotMacroName(slotIndex);

    local cleanIcon = DM.CleanMacroIcon(preferredIcon);
    local candidates = { cleanIcon };

    if cleanIcon == DM.PET_ATTACK_ICON_ID or cleanIcon == "Ability_Hunter_Pet_Attack" then
        table.insert(candidates, DM.PET_ATTACK_ICON_ID);
        table.insert(candidates, "Ability_Hunter_Pet_Attack");
    elseif cleanIcon == DM.TRINKET_ICON_ID or cleanIcon == "INV_Jewelry_TrinketPVP_01" then
        table.insert(candidates, DM.TRINKET_ICON_ID);
        table.insert(candidates, "INV_Jewelry_TrinketPVP_01");
    end
    table.insert(candidates, "INV_MISC_QUESTIONMARK");
    table.insert(candidates, 134400);
    table.insert(candidates, 1);

    local macroIndex, foundName = DM.FindSlotMacro(slotIndex);
    local lastErr = nil;

    -- 1. BEREITS EXISTIERENDES MAKRO IN-PLACE BEARBEITEN (KEIN DUPLIKAT!)
    if macroIndex and macroIndex > 0 then
        for _, cand in ipairs(candidates) do
            local ok, err = pcall(EditMacro, macroIndex, targetName, cand, body);
            if ok then
                slot.savedMacroName = targetName;
                DM.CleanupDuplicateMacros(slotIndex, macroIndex);
                DM.DebugLog("EditMacro OK: %s (idx: %d, reqIcon: %s)", targetName, macroIndex, tostring(cand));
                return true, macroIndex;
            else
                lastErr = err;
            end
        end
        DM.DebugLog("EditMacro FAILED: %s (err: %s)", targetName, tostring(lastErr));
        return false, lastErr or "EditMacro fehlgeschlagen";
    else
        -- 2. NUR WENN NOCH KEIN MAKRO FUER DIESEN SLOT EXISTIERT: NEU ANLEGEN
        local numGlobal, numChar = GetNumMacros();
        local canChar = (numChar < 18);
        local canGlobal = (numGlobal < 120);

        if not canChar and not canGlobal then
            return false, DM.L("STATUS_NO_MACRO_SLOT");
        end

        -- 1. Versuch als Charaktermakro
        if canChar then
            for _, cand in ipairs(candidates) do
                local ok, resOrErr = pcall(CreateMacro, targetName, cand, body, 1);
                local newIdx = (ok and resOrErr and resOrErr > 0) and resOrErr or DM.FindSlotMacro(slotIndex);
                if newIdx and newIdx > 0 then
                    slot.savedMacroName = targetName;
                    DM.CleanupDuplicateMacros(slotIndex, newIdx);
                    DM.DebugLog("CreateMacro [char] OK: %s (idx: %d, reqIcon: %s)", targetName, newIdx, tostring(cand));
                    return true, newIdx;
                else
                    lastErr = resOrErr;
                end
            end
        end

        -- 2. Fallback als globales Makro
        if canGlobal then
            for _, cand in ipairs(candidates) do
                local ok, resOrErr = pcall(CreateMacro, targetName, cand, body, nil);
                local newIdx = (ok and resOrErr and resOrErr > 0) and resOrErr or DM.FindSlotMacro(slotIndex);
                if newIdx and newIdx > 0 then
                    slot.savedMacroName = targetName;
                    DM.CleanupDuplicateMacros(slotIndex, newIdx);
                    DM.DebugLog("CreateMacro [global] OK: %s (idx: %d, reqIcon: %s)", targetName, newIdx, tostring(cand));
                    return true, newIdx;
                else
                    lastErr = resOrErr;
                end
            end
        end

        DM.DebugLog("CreateMacro FAILED: %s (err: %s)", targetName, tostring(lastErr));
        return false, lastErr or DM.L("STATUS_NO_MACRO_SLOT");
    end
end
---------------------------------------------------------------------------
-- Universelle WoW-Ausruestungsslots (Inventarslot-IDs)
---------------------------------------------------------------------------
DM.EQUIPMENT_SLOTS = {
    { id = 10, key = "EQUIP_SLOT_HANDS",    labelDE = "Handschuhe (10)", labelEN = "Hands (10)" },
    { id = 6,  key = "EQUIP_SLOT_WAIST",    labelDE = "Guertel (6)",      labelEN = "Waist (6)" },
    { id = 15, key = "EQUIP_SLOT_BACK",     labelDE = "Umhang (15)",     labelEN = "Cloak (15)" },
    { id = 2,  key = "EQUIP_SLOT_NECK",     labelDE = "Halskette (2)",   labelEN = "Neck (2)" },
    { id = 1,  key = "EQUIP_SLOT_HEAD",     labelDE = "Kopf (1)",        labelEN = "Head (1)" },
    { id = 3,  key = "EQUIP_SLOT_SHOULDER", labelDE = "Schultern (3)",   labelEN = "Shoulders (3)" },
    { id = 5,  key = "EQUIP_SLOT_CHEST",    labelDE = "Brust (5)",       labelEN = "Chest (5)" },
    { id = 9,  key = "EQUIP_SLOT_WRIST",    labelDE = "Handgelenke (9)", labelEN = "Wrists (9)" },
    { id = 7,  key = "EQUIP_SLOT_LEGS",     labelDE = "Beine (7)",       labelEN = "Legs (7)" },
    { id = 8,  key = "EQUIP_SLOT_FEET",     labelDE = "Stiefel (8)",     labelEN = "Boots (8)" },
    { id = 11, key = "EQUIP_SLOT_FINGER1",  labelDE = "Ring 1 (11)",     labelEN = "Ring 1 (11)" },
    { id = 12, key = "EQUIP_SLOT_FINGER2",  labelDE = "Ring 2 (12)",     labelEN = "Ring 2 (12)" },
    { id = 16, key = "EQUIP_SLOT_MAINHAND", labelDE = "Waffenhand (16)", labelEN = "Main Hand (16)" },
    { id = 17, key = "EQUIP_SLOT_OFFHAND",  labelDE = "Schildhand (17)", labelEN = "Off Hand (17)" },
    { id = 18, key = "EQUIP_SLOT_RANGED",   labelDE = "Distanz (18)",    labelEN = "Ranged (18)" },
};

DM.EQUIP_LOC_TO_SLOT = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_NECK"] = 2,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_BODY"] = 4,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HANDS"] = 10,
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_THROWN"] = 18,
    ["INVTYPE_RELIC"] = 18,
    ["INVTYPE_TABARD"] = 19,
};

---------------------------------------------------------------------------
-- Begleiter-Befehle & passende Blizzard-Icons (Kein Zahnrad!)
---------------------------------------------------------------------------
DM.PET_COMMANDS = {
    { cmd = "",              labelDE = "Keine Begleiteraktion", labelEN = "No Pet Action", icon = "Interface\\PaperDoll\\UI-Backpack-EmptySlot" },
    { cmd = "/petattack",    labelDE = "Angreifen (/petattack)", labelEN = "Attack (/petattack)", icon = "Interface\\Icons\\Ability_Hunter_Pet_Attack" },
    { cmd = "/petfollow",    labelDE = "Folgen (/petfollow)",   labelEN = "Follow (/petfollow)",   icon = "Interface\\Icons\\Ability_Hunter_Pet_Follow" },
    { cmd = "/petpassive",   labelDE = "Passiv (/petpassive)",  labelEN = "Passive (/petpassive)", icon = "Interface\\Icons\\Ability_Hunter_Pet_Passive" },
    { cmd = "/petdefensive", labelDE = "Defensiv (/petdefensive)", labelEN = "Defensive (/petdefensive)", icon = "Interface\\Icons\\Ability_Hunter_Pet_Defensive" },
};

function DM.GetPetCommandInfo(cmd)
    for _, item in ipairs(DM.PET_COMMANDS) do
        if item.cmd == cmd then
            return item;
        end
    end
    return DM.PET_COMMANDS[1];
end

function DM.GetPetAttackTexture()
    if UnitExists and UnitExists("pet") and GetPetActionInfo then
        for i = 1, 10 do
            local name, subtext, texture = GetPetActionInfo(i);
            if name and (name == "PET_ACTION_ATTACK" or name == "Angreifen" or name == "Attack" or (texture and string.find(string.lower(tostring(texture)), "pet_attack"))) then
                if texture and texture ~= "" then
                    return texture;
                end
            end
        end
    end
    -- Verifiziertes Client-Asset fuer Ability_Hunter_Pet_Attack
    return DM.PET_ATTACK_ICON_ID;
end

function DM.GetTrinketTexture(slotID)
    local tex = GetInventoryItemCompat(slotID);
    if tex and tex ~= "" then
        return tex;
    end
    return "Interface\\Icons\\INV_Jewelry_TrinketPVP_01";
end

function DM.GetEquipmentSlotLabel(slotId)
    local isDE = (DinoMacroDB and DinoMacroDB.locale == "deDE");
    for _, eq in ipairs(DM.EQUIPMENT_SLOTS) do
        if eq.id == slotId then
            return isDE and eq.labelDE or eq.labelEN;
        end
    end
    return "Slot " .. tostring(slotId);
end

---------------------------------------------------------------------------
-- Lokalisierung & Umschaltung
---------------------------------------------------------------------------
function DM.InitLocale()
    if not DinoMacroDB then DinoMacroDB = {}; end
    local clientLocale = (GetLocale and GetLocale()) or "enUS";
    -- Wenn der WoW-Client selbst auf Englisch laeuft, MUSS das Makrosystem englische Zaubernamen verwenden!
    if clientLocale ~= "deDE" then
        if not DinoMacroDB.locale or DinoMacroDB.locale == "deDE" then
            DinoMacroDB.locale = "enUS";
        end
    elseif not DinoMacroDB.locale then
        DinoMacroDB.locale = "deDE";
    end
    DM.currentLocale = DinoMacroDB.locale;
end

function DM.ToggleLocale()
    if DinoMacroDB.locale == "deDE" then
        DinoMacroDB.locale = "enUS";
    else
        DinoMacroDB.locale = "deDE";
    end
    DM.currentLocale = DinoMacroDB.locale;

    -- Aktualisiere alle Zaubernamen und Makros gemaess der neuen Sprache
    if DinoMacroDB and DinoMacroDB.slots then
        for i = 1, DM.SLOT_COUNT do
            local slot = DinoMacroDB.slots[i];
            if slot and slot.spells then
                for _, sp in ipairs(slot.spells) do
                    DM.ResolveSpell(sp);
                end
            end
            DM.UpdateSlotMacro(i);
        end
    end

    DM.ApplyLocale();
end

function DM.DeepCopy(orig)
    if type(orig) ~= "table" then return orig; end
    local copy = {};
    for k, v in pairs(orig) do
        copy[k] = DM.DeepCopy(v);
    end
    return copy;
end

---------------------------------------------------------------------------
-- API-Kompatibilitaetsschicht
---------------------------------------------------------------------------
local function SpellInfo(spell)
    if not spell then return nil; end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spell);
        if ok and type(info) == "table" and info.name then
            return info.name, info.iconID, info.spellID;
        end
    end
    if GetSpellInfo then
        local ok, name, _, icon, _, _, _, spellID = pcall(GetSpellInfo, spell);
        if ok and name then
            return name, icon, spellID;
        end
    end
    return nil;
end

local function SpellSubtext(spellID)
    if not spellID then return ""; end
    local fn = (C_Spell and C_Spell.GetSpellSubtext) or GetSpellSubtext;
    if fn then
        local ok, text = pcall(fn, spellID);
        if ok and type(text) == "string" then return text; end
    end
    return "";
end

local function IsSpellPassiveCompat(spellID)
    local fn = (C_Spell and C_Spell.IsSpellPassive) or IsPassiveSpell;
    if fn and spellID then
        local ok, result = pcall(fn, spellID);
        if ok then return result and true or false; end
    end
    return false;
end

local function IsSpellKnownCompat(spellID)
    if not spellID then return false; end
    local checked = false;
    local checks = { IsPlayerSpell, IsSpellKnown, C_SpellBook and C_SpellBook.IsSpellKnown };
    for i = 1, 3 do
        local fn = checks[i];
        if fn then
            checked = true;
            local ok, known = pcall(fn, spellID);
            if ok and known then return true; end
        end
    end
    return not checked;
end

-- [1.4.12: Duplicate SetCooldownCompat removed - unified at top]

-- (Compat-Helper an Dateianfang verlegt)

---------------------------------------------------------------------------
-- Gestalt- & Haltungsunterstuetzung (Verbessert & dynamisch fuer alle Klassen)
---------------------------------------------------------------------------
function DM.GetAvailableForms()
    local forms = {};
    local numForms = (GetNumShapeshiftForms and GetNumShapeshiftForms()) or 0;
    for i = 1, numForms do
        local ok, icon, name, isActive, isCastable, spellID = pcall(GetShapeshiftFormInfo, i);
        if ok and (name or icon) then
            table.insert(forms, {
                index = i,
                name = name or ("Form " .. i),
                icon = icon or DM.QUESTION_ICON,
                spellID = spellID
            });
        end
    end
    return forms;
end

function DM.GetFormCondDisplay(formCond)
    if not formCond or formCond == "" then
        return DM.L("FORM_NONE");
    end
    local isNoForm, indexStr = string.match(formCond, "^(noform):(%d+)$");
    if not isNoForm then
        indexStr = string.match(formCond, "^form:(%d+)$");
    end
    local idx = tonumber(indexStr);
    if idx == 0 then
        return DM.L("FORM_HUMANOID");
    end
    local forms = DM.GetAvailableForms();
    if idx and forms[idx] then
        local prefix = isNoForm and DM.L("FORM_PREFIX_NOT") or DM.L("FORM_PREFIX_ONLY");
        return prefix .. " " .. forms[idx].name;
    end
    return formCond;
end

local function CycleNextFormCond(currentCond)
    local forms = DM.GetAvailableForms();
    if #forms == 0 then
        return "";
    end
    local seq = { "" };
    for _, f in ipairs(forms) do
        table.insert(seq, "form:" .. f.index);
        table.insert(seq, "noform:" .. f.index);
    end
    table.insert(seq, "form:0");

    for idx, c in ipairs(seq) do
        if c == currentCond then
            local nextIdx = (idx % #seq) + 1;
            return seq[nextIdx];
        end
    end
    return seq[1];
end

---------------------------------------------------------------------------
-- Statusausgaben
---------------------------------------------------------------------------
function DM.Chat(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDinoMacro:|r " .. text);
    end
end

function DM.SetStatus(text, isError, isSuccess)
    if not DM.mainFrame or not DM.mainFrame.statusText then return; end
    DM.mainFrame.statusText:SetText(text or "");
    if isError then
        DM.mainFrame.statusText:SetTextColor(1, 0.3, 0.3);
    elseif isSuccess then
        DM.mainFrame.statusText:SetTextColor(0.2, 1, 0.2);
    else
        DM.mainFrame.statusText:SetTextColor(0.55, 0.85, 1);
    end
end

---------------------------------------------------------------------------
-- Datenbank & Initialisierung (DinoMacroDB)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Status-Pruefung fuer Zauber (Ressource = Blau, Ausser Reichweite = Rot)
---------------------------------------------------------------------------
function DM.GetSpellStatus(spellOrID, targetUnit)
    if not spellOrID then return false, false; end
    local spellID = (type(spellOrID) == "table" and spellOrID.spellID) or (type(spellOrID) == "number" and spellOrID) or nil;
    local spellName = (type(spellOrID) == "table" and spellOrID.name) or (type(spellOrID) == "string" and spellOrID) or nil;

    if (not spellID or not spellName) and (spellID or spellName) then
        local name, _, sID = DM.SpellInfo(spellID or spellName);
        spellName = spellName or name;
        spellID = spellID or sID;
    end

    local isOutOfRange = false;
    local isResourceShortage = false;

    -- 1. Ressourcen-Pruefung (Blau nur bei bestaetigtem Mana/Wut/Energie/Fokus-Mangel)
    if spellID or spellName then
        local isUsable, notEnoughMana = nil, nil;
        if C_Spell and C_Spell.IsSpellUsable and spellID then
            local ok, u, m = pcall(C_Spell.IsSpellUsable, spellID);
            if ok then isUsable = u; notEnoughMana = m; end
        end
        if notEnoughMana == nil and IsUsableSpell then
            local checkTarget = spellID or spellName;
            local ok, u, m = pcall(IsUsableSpell, checkTarget);
            if ok then isUsable = u; notEnoughMana = m; end
        end
        if notEnoughMana == true or notEnoughMana == 1 then
            isResourceShortage = true;
        end
    end

    -- 2. Reichweiten-Pruefung (Rot nur bei gueltigem Ziel ausserhalb der Reichweite)
    local unit = targetUnit or (UnitExists("mouseover") and "mouseover" or "target");
    if unit and UnitExists(unit) and (spellID or spellName) then
        local inRange = nil;
        if C_Spell and C_Spell.IsSpellInRange and spellID then
            local ok, res = pcall(C_Spell.IsSpellInRange, spellID, unit);
            if ok and res ~= nil then
                inRange = (res == true and 1 or (res == false and 0 or nil));
            end
        end
        if inRange == nil and IsSpellInRange then
            local checkTarget = spellName or spellID;
            local ok, res = pcall(IsSpellInRange, checkTarget, unit);
            if ok and res ~= nil then
                inRange = res;
            end
        end
        -- inRange == 0 bedeutet: Zauber hat Reichweite, Ziel existiert, ist aber AUSSER REICHWEITE
        if inRange == 0 then
            isOutOfRange = true;
        end
    end

    return isOutOfRange, isResourceShortage;
end

function DM.NewSlot()
    return {
        name = "",
        current = 1,
        spells = {},
        resetSeconds = DM.DEFAULT_RESET,
        resetOnTargetChange = nil,
        useMouseover = false,
        mouseoverTargetType = "harm",

        -- Zusatzaktionen
        trinket1 = { enabled = false, condition = "combat", position = "before" },
        trinket2 = { enabled = false, condition = "combat", position = "before" },
        itemSlot1 = { enabled = false, kind = "item", target = "", itemID = nil, slotID = nil, name = "", icon = nil, condition = "always", position = "before" },
        itemSlot2 = { enabled = false, kind = "item", target = "", itemID = nil, slotID = nil, name = "", icon = nil, condition = "always", position = "before" },
        petAction = { enabled = false, command = "/petattack", condition = "always", position = "before" },
    };
end

function DM.CopySpell(spell)
    if not spell then return nil; end
    return {
        name = spell.name,
        rank = spell.rank,
        spellID = spell.spellID,
        icon = spell.icon,
        combatCond = spell.combatCond or "always",
        formCond = spell.formCond or ""
    };
end

function DM.InitializeDB()
    if type(DinoMacroDB) ~= "table" then
        DinoMacroDB = {};
    end
    if type(DinoMacroDB.slots) ~= "table" then
        DinoMacroDB.slots = {};
    end
    if type(DinoMacroDB.position) ~= "table" then
        DinoMacroDB.position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 };
    end
    DinoMacroDB.version = DM.VERSION;
    DM.InitLocale();

    if type(DinoMacroDB.settings) ~= "table" then
        DinoMacroDB.settings = {
            showCooldownNumbers = true,
            showResourceColor = true,
            showRangeColor = true,
        };
    else
        if DinoMacroDB.settings.showCooldownNumbers == nil then DinoMacroDB.settings.showCooldownNumbers = true; end
        if DinoMacroDB.settings.showResourceColor == nil then DinoMacroDB.settings.showResourceColor = true; end
        if DinoMacroDB.settings.showRangeColor == nil then DinoMacroDB.settings.showRangeColor = true; end
    end

    local migratedPetSlots = {};
    local legacyCustomCmdCount = 0;

    for i = 1, DM.SLOT_COUNT do
        local slot = DinoMacroDB.slots[i];
        if type(slot) ~= "table" then
            slot = DM.NewSlot();
            DinoMacroDB.slots[i] = slot;
        end
        if type(slot.spells) ~= "table" then slot.spells = {}; end
        if type(slot.name) ~= "string" then slot.name = ""; end

        local slotResetSeconds = tonumber(slot.resetSeconds);
        if not slotResetSeconds or slotResetSeconds < 0 or slotResetSeconds > 3600 then
            slotResetSeconds = DM.DEFAULT_RESET;
        end
        slot.resetSeconds = slotResetSeconds;
        slot.resetOnTargetChange = slot.resetOnTargetChange and 1 or nil;
        slot.current = 1;

        if slot.useMouseover == nil then slot.useMouseover = false; end
        if not slot.mouseoverTargetType then slot.mouseoverTargetType = "harm"; end
        if not slot.trinket1 then slot.trinket1 = { enabled = false, condition = "combat", position = "before" }; end
        if not slot.trinket2 then slot.trinket2 = { enabled = false, condition = "combat", position = "before" }; end

        -- Gegenstand 1 Migration / Absicherung
        if not slot.itemSlot1 then
            slot.itemSlot1 = { enabled = false, kind = "item", target = "", itemID = nil, slotID = nil, name = "", icon = nil, condition = "always", position = "before" };
        else
            if slot.itemSlot1.condition == nil then slot.itemSlot1.condition = "always"; end
            if slot.itemSlot1.position == nil then slot.itemSlot1.position = "before"; end
            if slot.itemSlot1.kind == nil then slot.itemSlot1.kind = "item"; end
            if slot.itemSlot1.target == nil then slot.itemSlot1.target = ""; end
        end

        -- Gegenstand 2 Migration / Absicherung
        if not slot.itemSlot2 then
            slot.itemSlot2 = { enabled = false, kind = "item", target = "", itemID = nil, slotID = nil, name = "", icon = nil, condition = "always", position = "before" };
        else
            if slot.itemSlot2.condition == nil then slot.itemSlot2.condition = "always"; end
            if slot.itemSlot2.position == nil then slot.itemSlot2.position = "before"; end
            if slot.itemSlot2.kind == nil then slot.itemSlot2.kind = "item"; end
            if slot.itemSlot2.target == nil then slot.itemSlot2.target = ""; end
        end

        -- Begleiterbefehl Absicherung & Migration auf reines Petattack (1.4.8)
        if not slot.petAction then
            slot.petAction = { enabled = false, command = "/petattack", condition = "always", position = "before" };
        else
            if slot.petAction.command and slot.petAction.command ~= "/petattack" and slot.petAction.command ~= "" then
                if not slot.petAction.legacyCommand then
                    slot.petAction.legacyCommand = slot.petAction.command;
                end
                slot.petAction.enabled = false;
            end
            slot.petAction.command = "/petattack";
            if slot.petAction.enabled == nil then
                slot.petAction.enabled = false;
            end
            if slot.petAction.condition == nil then slot.petAction.condition = "always"; end
            if slot.petAction.position == nil then slot.petAction.position = "before"; end
        end

        -- Historische eigene Makrobefehle verlustfrei sichern
        if slot.customCommand and slot.customCommand.text and slot.customCommand.text ~= "" then
            legacyCustomCmdCount = legacyCustomCmdCount + 1;
        end

        -- Legacy Migration: Begleiterbefehle aus den 4 Zauberfeldern in die Pet-Zusatzaktion ueberfuehren
        local cleanedSpells = {};
        local foundPet = false;
        local petCond = "always";
        for _, sp in ipairs(slot.spells) do
            if sp.kind == "petattack" or sp.name == "Begleiter: Angreifen" or sp.name == "Pet: Attack" or (sp.command and string.find(sp.command, "petattack")) then
                foundPet = true;
                petCond = sp.combatCond or "always";
            else
                table.insert(cleanedSpells, sp);
            end
        end
        if foundPet then
            slot.spells = cleanedSpells;
            if not slot.petAction.enabled then
                slot.petAction.enabled = true;
                slot.petAction.command = "/petattack";
                slot.petAction.condition = petCond;
                slot.petAction.position = "before";
            end
            table.insert(migratedPetSlots, i);
        end
    end

    if #migratedPetSlots > 0 then
        DM.Chat("Legacy Pet-Befehle aus Zauberfeldern in die Pet-Zusatzaktion uebernommen (Slot " .. table.concat(migratedPetSlots, ", ") .. ").");
    end
end

---------------------------------------------------------------------------
-- Zauber-Helfer
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Mehrsprachige Zauberdatenbank fuer automatischen DE <-> EN Abgleich
---------------------------------------------------------------------------
DM.SPELL_NAME_TO_ID = {
    -- Jaeger / Hunter
    ["erschütternder schuss"] = 5116,
    ["erschuetternder schuss"] = 5116,
    ["concussive shot"] = 5116,
    ["schlangenbiss"] = 1978,
    ["serpent sting"] = 1978,
    ["gezielter schuss"] = 19434,
    ["aimed shot"] = 19434,
    ["mehrfachschuss"] = 2643,
    ["multi-shot"] = 2643,
    ["arkaner schuss"] = 3044,
    ["arcane shot"] = 3044,
    ["zuverlässiger schuss"] = 56641,
    ["zuverlaessiger schuss"] = 56641,
    ["steady shot"] = 56641,
    ["automatischer schuss"] = 75,
    ["auto shot"] = 75,
    ["tödlicher schuss"] = 53351,
    ["toedlicher schuss"] = 53351,
    ["kill shot"] = 53351,
    ["mal des jägers"] = 1130,
    ["mal des jaegers"] = 1130,
    ["hunter's mark"] = 1130,
    ["schnellfeuer"] = 3045,
    ["rapid fire"] = 3045,
    ["rückzug"] = 781,
    ["rueckzug"] = 781,
    ["disengage"] = 781,
    ["totstellen"] = 5384,
    ["feign death"] = 5384,
    ["leuchtfeuer"] = 1543,
    ["flare"] = 1543,
    ["eiskältefalle"] = 1499,
    ["eiskaeltefalle"] = 1499,
    ["freezing trap"] = 1499,
    ["frostfalle"] = 13809,
    ["frost trap"] = 13809,
    ["feuerbrandfalle"] = 13813,
    ["immolation trap"] = 13813,
    ["sprengfalle"] = 13795,
    ["explosive trap"] = 13795,
    ["schlangenfalle"] = 34600,
    ["snake trap"] = 34600,
    ["zurechtstutzen"] = 2974,
    ["wing clip"] = 2974,
    ["raptorstoß"] = 2973,
    ["raptorstoss"] = 2973,
    ["raptor strike"] = 2973,
    ["mungobiss"] = 1495,
    ["mongoose bite"] = 1495,
    ["zorn des wildtiers"] = 19574,
    ["bestial wrath"] = 19574,
    ["einschüchterung"] = 19577,
    ["einschuechterung"] = 19577,
    ["intimidation"] = 19577,
    ["abschreckung"] = 19263,
    ["deterrence"] = 19263,
    ["streuschuss"] = 19503,
    ["scatter shot"] = 19503,
    ["unterdrückender schuss"] = 34490,
    ["unterdrueckender schuss"] = 34490,
    ["silencing shot"] = 34490,
    ["schimärenschuss"] = 53209,
    ["schimaerenschuss"] = 53209,
    ["chimera shot"] = 53209,
    ["explosivschuss"] = 53301,
    ["explosive shot"] = 53301,
    ["schwarzer pfeil"] = 3674,
    ["black arrow"] = 3674,
    ["fass!"] = 34026,
    ["kill command"] = 34026,
    ["tier heilen"] = 136,
    ["mend pet"] = 136,
    ["tier wiederbeleben"] = 982,
    ["revive pet"] = 982,
    ["tier rufen"] = 883,
    ["call pet"] = 883,
    ["tier freigeben"] = 2641,
    ["dismiss pet"] = 2641,
    ["tier füttern"] = 6991,
    ["tier fuettern"] = 6991,
    ["feed pet"] = 6991,
    ["aspekt des falken"] = 13165,
    ["aspect of the hawk"] = 13165,
    ["aspekt des affen"] = 13163,
    ["aspect of the monkey"] = 13163,
    ["aspekt der viper"] = 34074,
    ["aspect of the viper"] = 34074,
    ["aspekt des geparden"] = 5118,
    ["aspect of the cheetah"] = 5118,
    ["aspekt des rudels"] = 13159,
    ["aspect of the pack"] = 13159,
    ["aspekt der wildnis"] = 20043,
    ["aspect of the wild"] = 20043,
    ["aspekt des drachenfalken"] = 61846,
    ["aspect of the dragonhawk"] = 61846,
    ["aspekt des wildtiers"] = 13161,
    ["aspect of the beast"] = 13161,
    ["skorpidstich"] = 3043,
    ["scorpid sting"] = 3043,
    ["vipernbiss"] = 3034,
    ["viper sting"] = 3034,
    ["stich des flügeldrachen"] = 19386,
    ["stich des fluegeldrachen"] = 19386,
    ["wyvern sting"] = 19386,
    ["einlullender schuss"] = 19801,
    ["tranquilizing shot"] = 19801,
    ["salve"] = 1510,
    ["volley"] = 1510,
    ["irreführung"] = 34477,
    ["irrefuehrung"] = 34477,
    ["misdirection"] = 34477,
    ["ablenkender schuss"] = 20736,
    ["distracting shot"] = 20736,
    ["falkenauge"] = 19498,
    ["eagle eye"] = 19498,

    -- Krieger / Warrior
    ["sturmangriff"] = 100,
    ["charge"] = 100,
    ["blutrausch"] = 2687,
    ["bloodrage"] = 2687,
    ["heldenhafter stoß"] = 78,
    ["heldenhafter stoss"] = 78,
    ["heroic strike"] = 78,
    ["verwunden"] = 772,
    ["rend"] = 772,
    ["donnerknall"] = 6343,
    ["thunder clap"] = 6343,
    ["rüstung zerreißen"] = 7386,
    ["ruestung zerreissen"] = 7386,
    ["sunder armor"] = 7386,
    ["überwältigen"] = 7384,
    ["ueberwaeltigen"] = 7384,
    ["overpower"] = 7384,
    ["hinrichten"] = 5308,
    ["execute"] = 5308,
    ["tödlicher stoß"] = 12294,
    ["toedlicher stoss"] = 12294,
    ["mortal strike"] = 12294,
    ["wirbelwind"] = 1680,
    ["whirlwind"] = 1680,
    ["schildschlag"] = 23922,
    ["shield slam"] = 23922,
    ["schildblock"] = 2565,
    ["shield block"] = 2565,

    -- Magier / Mage
    ["frostblitz"] = 116,
    ["frostbolt"] = 116,
    ["feuerball"] = 133,
    ["fireball"] = 133,
    ["arkane geschosse"] = 5143,
    ["arcane missiles"] = 5143,
    ["feuerschlag"] = 2136,
    ["fire blast"] = 2136,
    ["arkane explosion"] = 1449,
    ["arcane explosion"] = 1449,
    ["frostnova"] = 122,
    ["frost nova"] = 122,
    ["blinzeln"] = 1953,
    ["blink"] = 1953,
    ["hervorrufung"] = 12051,
    ["evocation"] = 12051,

    -- Schurke / Rogue
    ["finsterer stoß"] = 1752,
    ["finsterer stoss"] = 1752,
    ["sinister strike"] = 1752,
    ["ausweiden"] = 2098,
    ["eviscerate"] = 2098,
    ["verstohlenheit"] = 1784,
    ["stealth"] = 1784,
    ["hinterhalt"] = 8676,
    ["ambush"] = 8676,
    ["meucheln"] = 53,
    ["backstab"] = 53,
    ["entrinnen"] = 5277,
    ["evasion"] = 5277,
    ["sprinten"] = 2983,
    ["sprint"] = 2983,
    ["vanish"] = 1856,
    ["verschwinden"] = 1856,

    -- Priester / Priest
    ["pein"] = 585,
    ["smite"] = 585,
    ["blitzheilung"] = 2061,
    ["flash heal"] = 2061,
    ["große heilung"] = 2060,
    ["grosse heilung"] = 2060,
    ["greater heal"] = 2060,
    ["erneuerung"] = 139,
    ["renew"] = 139,
    ["machtwort: schild"] = 17,
    ["power word: shield"] = 17,
    ["schattenwort: schmerz"] = 589,
    ["shadow word: pain"] = 589,

    -- Hexenmeister / Warlock
    ["schattenblitz"] = 686,
    ["shadow bolt"] = 686,
    ["verderbnis"] = 172,
    ["corruption"] = 172,
    ["feuerbrand"] = 348,
    ["immolate"] = 348,
    ["fluch der pein"] = 980,
    ["curse of agony"] = 980,
    ["lebensentzug"] = 1454,
    ["life tap"] = 1454,
    ["aderlass"] = 1454,

    -- Druide / Druid
    ["zorn"] = 5176,
    ["wrath"] = 5176,
    ["mondfeuer"] = 8921,
    ["moonfire"] = 8921,
    ["verjüngung"] = 774,
    ["verjuengung"] = 774,
    ["rejuvenation"] = 774,
    ["nachwachsen"] = 8936,
    ["regrowth"] = 8936,
    ["heilende berührung"] = 5185,
    ["heilende beruehrung"] = 5185,
    ["healing touch"] = 5185,

    -- Schamane / Shaman
    ["blitzschlag"] = 403,
    ["lightning bolt"] = 403,
    ["kettenblitz"] = 421,
    ["chain lightning"] = 421,
    ["erdschock"] = 8042,
    ["earth shock"] = 8042,
    ["flammenschock"] = 8050,
    ["flame shock"] = 8050,
    ["frostschock"] = 8056,
    ["frost shock"] = 8056,
    ["welle der heilung"] = 331,
    ["healing wave"] = 331,

    -- Paladin
    ["heiliges licht"] = 635,
    ["holy light"] = 635,
    ["lichtblitz"] = 19750,
    ["flash of light"] = 19750,
    ["richturteil"] = 20271,
    ["judgement"] = 20271,
    ["segen der macht"] = 19740,
    ["blessing of might"] = 19740,
};

function DM.ResolveSpell(spell)
    if not spell then return nil; end
    local spellID = spell.spellID;

    -- 1. Direkte Abfrage ueber numerische spellID
    -- In WoW liefert SpellInfo(spellID) IMMER den lokalisierten Namen des AKTIVEN Clients!
    -- Auf einem englischen Client wird z.B. 5116 zu "Concussive Shot" und 1978 zu "Serpent Sting".
    if spellID and type(spellID) == "number" and spellID > 0 then
        local name, icon = SpellInfo(spellID);
        if name and name ~= "" then
            spell.name = name;
            if icon then spell.icon = icon; end
            local sub = SpellSubtext(spellID);
            if sub and sub ~= "" then spell.rank = sub; end
            return spell;
        end
    end

    -- 2. Fallback: Lookup ueber WoWs SpellInfo mit vorhandenem Namen
    if spell.name and spell.name ~= "" then
        local name, icon, sID = SpellInfo(spell.name);
        if name and name ~= "" then
            spell.name = name;
            if icon then spell.icon = icon; end
            if sID and type(sID) == "number" and sID > 0 then
                spell.spellID = sID;
                local sub = SpellSubtext(sID);
                if sub and sub ~= "" then spell.rank = sub; end
            end
            return spell;
        end

        -- 3. Mehrsprachiger Fallback-Abgleich: Falls ein deutscher Zaubername auf einem
        -- englischen Client vorliegt (oder umgekehrt), finde die base spellID ueber die Tabelle
        local lowerName = string.lower(strtrim(spell.name));
        local mappedID = DM.SPELL_NAME_TO_ID and DM.SPELL_NAME_TO_ID[lowerName];
        if mappedID and type(mappedID) == "number" and mappedID > 0 then
            spell.spellID = mappedID;
            local mName, mIcon = SpellInfo(mappedID);
            if mName and mName ~= "" then
                spell.name = mName;
                if mIcon then spell.icon = mIcon; end
                local sub = SpellSubtext(mappedID);
                if sub and sub ~= "" then spell.rank = sub; end
                return spell;
            end
        end
    end

    return spell;
end

function DM.GetCurrentStep(slotIndex)
    local slot = DinoMacroDB.slots[slotIndex];
    if not slot or not slot.spells or #slot.spells == 0 then return 1; end
    local cur = slot.current or 1;
    if cur < 1 or cur > #slot.spells then cur = 1; end
    return cur;
end

---------------------------------------------------------------------------
-- Makro-Generierung mit automatischer Kampfgruppierung & dynamischem #showtooltip (1.4.11)
---------------------------------------------------------------------------
function DM.BuildSlotMacro(slot)
    if not slot then return "", nil, {}, 0, false; end

    local spells = slot.spells or {};
    local lines = {};
    local sequenceSteps = {};

    -- 1. Tooltip-Zeile
    local tooltipLine = "#showtooltip";
    if #spells == 0 then
        if slot.petAction and slot.petAction.enabled then
            tooltipLine = "#showtooltip Ability_Hunter_Pet_Attack";
        elseif slot.trinket1 and slot.trinket1.enabled then
            tooltipLine = "#showtooltip 13";
        elseif slot.trinket2 and slot.trinket2.enabled then
            tooltipLine = "#showtooltip 14";
        elseif slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.target and slot.itemSlot1.target ~= "" then
            tooltipLine = "#showtooltip " .. slot.itemSlot1.target;
        elseif slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.target and slot.itemSlot2.target ~= "" then
            tooltipLine = "#showtooltip " .. slot.itemSlot2.target;
        end
    else
        tooltipLine = "#showtooltip";
    end
    table.insert(lines, tooltipLine);

    -- Helper fuer Gegenstands-Namen
    local function GetItemTarget(action)
        if not action or not action.enabled then return ""; end
        if action.itemID and GetItemInfo then
            local ok, iName = pcall(GetItemInfo, action.itemID);
            if ok and iName and iName ~= "" then
                action.name = iName;
                action.target = iName;
                return iName;
            end
        end
        return action.target or action.name or "";
    end

    local function AppendAction(action, isBefore)
        if not action or not action.enabled then return; end
        local pos = action.position or "before";
        if (isBefore and pos ~= "before") or (not isBefore and pos ~= "after") then return; end

        local cond = action.condition or "always";
        local condStr = (cond == "combat" and "[combat] " or (cond == "nocombat" and "[nocombat] " or ""));

        local mouseCond = "";
        if slot.useMouseover then
            local mType = slot.mouseoverTargetType or "harm";
            if mType == "help" then
                mouseCond = "@mouseover,help,nodead";
            else
                mouseCond = "@mouseover,harm,nodead";
            end
        end

        if action == slot.trinket1 then
            if slot.useMouseover and mouseCond ~= "" then
                if cond == "combat" then
                    table.insert(lines, "/use [combat," .. mouseCond .. "][combat] 13");
                elseif cond == "nocombat" then
                    table.insert(lines, "/use [nocombat," .. mouseCond .. "][nocombat] 13");
                else
                    table.insert(lines, "/use [" .. mouseCond .. "][] 13");
                end
            else
                table.insert(lines, "/use " .. condStr .. "13");
            end
        elseif action == slot.trinket2 then
            if slot.useMouseover and mouseCond ~= "" then
                if cond == "combat" then
                    table.insert(lines, "/use [combat," .. mouseCond .. "][combat] 14");
                elseif cond == "nocombat" then
                    table.insert(lines, "/use [nocombat," .. mouseCond .. "][nocombat] 14");
                else
                    table.insert(lines, "/use [" .. mouseCond .. "][] 14");
                end
            else
                table.insert(lines, "/use " .. condStr .. "14");
            end
        elseif action == slot.petAction then
            if slot.useMouseover and mouseCond ~= "" then
                if cond == "combat" then
                    table.insert(lines, "/petattack [combat," .. mouseCond .. "][combat,harm,nodead]");
                elseif cond == "nocombat" then
                    table.insert(lines, "/petattack [nocombat," .. mouseCond .. "][nocombat,harm,nodead]");
                else
                    table.insert(lines, "/petattack [" .. mouseCond .. "][harm,nodead]");
                end
            else
                local pCond = "";
                if cond == "combat" then
                    pCond = " [combat,harm,nodead]";
                elseif cond == "nocombat" then
                    pCond = " [nocombat,harm,nodead]";
                else
                    pCond = " [harm,nodead]";
                end
                table.insert(lines, "/petattack" .. pCond);
            end
        elseif (action.target and action.target ~= "") or (action.itemID and action.itemID > 0) then
            local actTarget = GetItemTarget(action);
            if actTarget ~= "" then
                if slot.useMouseover and mouseCond ~= "" then
                    if cond == "combat" then
                        table.insert(lines, "/use [combat," .. mouseCond .. "][combat] " .. actTarget);
                    elseif cond == "nocombat" then
                        table.insert(lines, "/use [nocombat," .. mouseCond .. "][nocombat] " .. actTarget);
                    else
                        table.insert(lines, "/use [" .. mouseCond .. "][] " .. actTarget);
                    end
                else
                    table.insert(lines, "/use " .. condStr .. actTarget);
                end
            end
        end
    end

    -- 2. Zusatzaktionen VOR der Kette
    AppendAction(slot.trinket1, true);
    AppendAction(slot.trinket2, true);
    AppendAction(slot.itemSlot1, true);
    AppendAction(slot.itemSlot2, true);
    AppendAction(slot.petAction, true);

    -- 3. Zauber-Sequenz sauber & exakt aus den Editor-Schritten generieren
    local sequenceText = nil;
    if #spells > 0 then
        local names = {};
        for i, sp in ipairs(spells) do
            local resolved = DM.ResolveSpell(sp);
            local sName = (resolved and resolved.name) or sp.name or DM.L("UNKNOWN_SPELL");
            table.insert(names, sName);
            table.insert(sequenceSteps, i);
        end

        local resetParts = {};
        if slot.resetSeconds and slot.resetSeconds > 0 then
            table.insert(resetParts, tostring(slot.resetSeconds));
        end
        if slot.resetOnTargetChange then
            table.insert(resetParts, "target");
        end

        local resetStr = "";
        if #resetParts > 0 then
            resetStr = "reset=" .. table.concat(resetParts, "/") .. " ";
        end

        local conds = {};
        if slot.useMouseover then
            local mType = slot.mouseoverTargetType or "harm";
            if mType == "help" then
                table.insert(conds, "@mouseover,help,nodead");
            else
                table.insert(conds, "@mouseover,harm,nodead");
            end
        end
        if spells[1] and spells[1].formCond and spells[1].formCond ~= "" then
            table.insert(conds, spells[1].formCond);
        end
        if spells[1] and spells[1].combatCond and spells[1].combatCond ~= "always" then
            table.insert(conds, spells[1].combatCond);
        end

        local condStr = "";
        if #conds > 0 then
            if slot.useMouseover then
                local baseConds = {};
                if spells[1] and spells[1].combatCond and spells[1].combatCond ~= "always" then
                    table.insert(baseConds, spells[1].combatCond);
                end
                if spells[1] and spells[1].formCond and spells[1].formCond ~= "" then
                    table.insert(baseConds, spells[1].formCond);
                end
                local fallback = (#baseConds > 0) and ("[" .. table.concat(baseConds, ",") .. "] ") or "[] ";
                condStr = "[" .. table.concat(conds, ",") .. "] " .. fallback;
            else
                condStr = "[" .. table.concat(conds, ",") .. "] ";
            end
        end

        sequenceText = "/castsequence " .. condStr .. resetStr .. table.concat(names, ", ");
        table.insert(lines, sequenceText);
    end

    -- 4. Zusatzaktionen NACH der Kette
    AppendAction(slot.trinket1, false);
    AppendAction(slot.trinket2, false);
    AppendAction(slot.itemSlot1, false);
    AppendAction(slot.itemSlot2, false);
    AppendAction(slot.petAction, false);

    local hasAnyActionOrSpell = (#spells > 0) or
                                (slot.trinket1 and slot.trinket1.enabled) or
                                (slot.trinket2 and slot.trinket2.enabled) or
                                (slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.target and slot.itemSlot1.target ~= "") or
                                (slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.target and slot.itemSlot2.target ~= "") or
                                (slot.petAction and slot.petAction.enabled);

    if not hasAnyActionOrSpell or #lines <= 1 then
        return "", nil, {}, 0, false;
    end

    -- Duplizierte Zeilen bereinigen
    local finalLines = {};
    local seen = {};
    for _, l in ipairs(lines) do
        if not seen[l] then
            seen[l] = true;
            table.insert(finalLines, l);
        end
    end

    local body = table.concat(finalLines, "\n");
    local charCount = string.len(body);
    local isOverLimit = charCount > DM.MACRO_MAX_CHARS;

    DM.DebugLog("BuildSlotMacro [%s]: %s", tostring(slot.name), body:gsub("\n", " || "));
    return body, sequenceText, sequenceSteps, charCount, isOverLimit;
end
---------------------------------------------------------------------------
-- Sichere Ausfuehrung & Makro-Synchronisation
---------------------------------------------------------------------------
function DM.ApplyPendingSlots()
    if InCombatLockdown() then return; end
    local count = 0;
    for slotIndex, _ in pairs(DM.pendingSlots) do
        DM.ApplySecureSlot(slotIndex);
        DM.UpdateSlotMacro(slotIndex);
        DM.pendingSlots[slotIndex] = nil;
        count = count + 1;
    end
    if count > 0 then
        DM.SetStatus(DM.L("SAVED_COMBAT_APPLIED", count), nil, true);
    end
end

function DM.ApplySecureSlot(slotIndex)
    -- Die 14 Slot-Knoepfe im Hauptfenster dienen ausschliesslich der Slot-Auswahl im Editor.
    -- Sie loesen beim Bearbeiten niemals Makros im Spiel aus!
    -- Makro-Ausfuehrung erfolgt einzig ueber Blizzard-Aktionsleisten via UpdateSlotMacro.
    local btn = DM.slotButtons[slotIndex];
    if btn then
        btn:SetAttribute("type", nil);
        btn:SetAttribute("macrotext", nil);
    end
end

---------------------------------------------------------------------------
-- Dynamische Aktions- und Icon-Ermittlung (1.4.11)
---------------------------------------------------------------------------
function DM.GetCurrentActionForSlot(slotIndex)
    local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[slotIndex];
    if not slot then return "none", nil; end

    local inCombat = InCombatLockdown and InCombatLockdown();

    -- 1. Zauber: Aktuellen Schritt der Sequenz ermitteln!
    local spells = slot.spells or {};
    if #spells > 0 then
        local cur = DM.GetCurrentStep(slotIndex);
        local curSpell = spells[cur] or spells[1];

        -- Pruefe, ob der aktuelle Zauber aktiv ist
        local cond = curSpell.combatCond or "always";
        if cond == "always" or (inCombat and cond == "combat") or (not inCombat and cond == "nocombat") then
            return "spell", curSpell;
        end

        -- Falls der aktuelle Schritt wegen Kampfbedingung nicht passt, passenden Schritt suchen
        for i = 1, #spells do
            local sp = spells[i];
            local c = sp.combatCond or "always";
            if (inCombat and c == "combat") or (not inCombat and c == "nocombat") or c == "always" then
                return "spell", sp;
            end
        end
        return "spell", curSpell;
    end

    -- 2. Zusatzaktionen nach Kampfzustand
    local function MatchAction(act)
        if not act or not act.enabled then return false; end
        local c = act.condition or "always";
        if inCombat then return (c == "combat" or c == "always"); end
        return (c == "nocombat" or c == "always");
    end

    if MatchAction(slot.trinket1) then return "trinket", 13; end
    if MatchAction(slot.trinket2) then return "trinket", 14; end
    if MatchAction(slot.itemSlot1) then return "item", slot.itemSlot1; end
    if MatchAction(slot.itemSlot2) then return "item", slot.itemSlot2; end
    if MatchAction(slot.petAction) then return "pet", slot.petAction; end

    if slot.trinket1 and slot.trinket1.enabled then return "trinket", 13; end
    if slot.trinket2 and slot.trinket2.enabled then return "trinket", 14; end
    if slot.itemSlot1 and slot.itemSlot1.enabled then return "item", slot.itemSlot1; end
    if slot.itemSlot2 and slot.itemSlot2.enabled then return "item", slot.itemSlot2; end
    if slot.petAction and slot.petAction.enabled then return "pet", slot.petAction; end

end


function DM.GetSlotIcon(slotOrIndex)
    local slotIndex = nil;
    if type(slotOrIndex) == "number" then
        slotIndex = slotOrIndex;
    elseif type(slotOrIndex) == "table" and DinoMacroDB and DinoMacroDB.slots then
        for idx, s in pairs(DinoMacroDB.slots) do
            if s == slotOrIndex then slotIndex = idx; break; end
        end
    end
    slotIndex = slotIndex or (DM.selectedSlot or 1);

    local kind, data = DM.GetCurrentActionForSlot(slotIndex);
    if kind == "spell" and data and data.icon and data.icon ~= "" then
        return data.icon;
    elseif kind == "pet" then
        return DM.GetPetAttackTexture();
    elseif kind == "trinket" and data then
        return DM.GetTrinketTexture(data);
    elseif kind == "item" and data and data.icon and data.icon ~= "" then
        return data.icon;
    end
    return DM.QUESTION_ICON;
end

function DM.GetNativeMacroIcon(slot)
    if not slot then return "INV_MISC_QUESTIONMARK"; end

    -- 1.4.15: Wenn Zauber vorhanden sind, MUSS das native Makro-Icon IMMER das
    -- Fragezeichen ("INV_MISC_QUESTIONMARK") sein!
    -- Nur wenn ein Makro das Fragezeichen-Icon besitzt, schaltet Blizzard das Icon
    -- auf der Aktionsleiste dynamisch gemaess dem aktuellen /castsequence-Schritt um!
    if slot.spells and #slot.spells > 0 then
        return "INV_MISC_QUESTIONMARK";
    end

    if slot.petAction and slot.petAction.enabled then
        return DM.PET_ATTACK_ICON_ID;
    end

    if slot.trinket1 and slot.trinket1.enabled then
        local tex = GetInventoryItemCompat(13);
        if tex and tex ~= "" then return tex; end
        return DM.TRINKET_ICON_ID;
    end
    if slot.trinket2 and slot.trinket2.enabled then
        local tex = GetInventoryItemCompat(14);
        if tex and tex ~= "" then return tex; end
        return DM.TRINKET_ICON_ID;
    end
    if slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.icon and slot.itemSlot1.icon ~= "" then
        return slot.itemSlot1.icon;
    end
    if slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.icon and slot.itemSlot2.icon ~= "" then
        return slot.itemSlot2.icon;
    end

    return "INV_MISC_QUESTIONMARK";
end

function DM.UpdateSlotMacro(slotIndex)
    local slot = DinoMacroDB.slots[slotIndex];
    if not slot then return false, "Slot ungültig"; end

    local targetName = DM.GetSlotMacroName(slotIndex);
    local body = DM.BuildSlotMacro(slot);
    local hasContent = (slot.spells and #slot.spells > 0) or
                       (slot.trinket1 and slot.trinket1.enabled) or (slot.trinket2 and slot.trinket2.enabled) or
                       (slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.target and slot.itemSlot1.target ~= "") or
                       (slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.target and slot.itemSlot2.target ~= "") or
                       (slot.petAction and slot.petAction.enabled);

    local macroIndex, foundName = DM.FindSlotMacro(slotIndex);

    if not hasContent or body == "" or body == "#showtooltip" then
        if macroIndex > 0 and not InCombatLockdown() then
            pcall(DeleteMacro, macroIndex);
            slot.savedMacroName = nil;
        end
        return true, nil;
    end

    if InCombatLockdown() then
        DM.pendingSlots[slotIndex] = true;
        return false, DM.L("STATUS_COMBAT_SAVE_NOTICE");
    end

    local icon = DM.GetNativeMacroIcon(slot);
    local ok, res = DM.SafeCreateOrEditMacro(slotIndex, icon, body);
    return ok, res;
end

function DM.GetSlotStatus(slotIndex)
    local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[slotIndex];
    if not slot then return false, false; end

    local targetUnit = slot.useMouseover and (UnitExists("mouseover") and "mouseover" or "target") or "target";
    local kind, data = DM.GetCurrentActionForSlot(slotIndex);

    if kind == "spell" and data then
        return DM.GetSpellStatus(data, targetUnit);
    end

    return false, false;
end

---------------------------------------------------------------------------
-- UI-Aktualisierung der Slots (Linke Seite - Dynamische Icon-Prioritaet)
---------------------------------------------------------------------------
function DM.UpdateSlotButton(slotIndex)
    local btn = DM.slotButtons[slotIndex];
    if not btn then return; end

    local slot = DinoMacroDB.slots[slotIndex];
    if not slot then return; end

    local kind, data = DM.GetCurrentActionForSlot(slotIndex);
    local icon = DM.GetSlotIcon(slotIndex);

    local settings = DinoMacroDB and DinoMacroDB.settings or {};
    local showRange = settings.showRangeColor ~= false;
    local showRes = settings.showResourceColor ~= false;

    local isOutOfRange, isResourceShortage = DM.GetSlotStatus(slotIndex);

    btn.icon:Show();
    DM.SafeSetSlotTexture(btn.icon, icon);

    if kind == "spell" and data then
        if isOutOfRange and showRange then
            btn.icon:SetVertexColor(0.85, 0.15, 0.15, 1); -- Rot bei ausser Reichweite
        elseif isResourceShortage and showRes then
            btn.icon:SetVertexColor(0.25, 0.45, 1, 1);    -- Blau bei fehlender Ressource
        else
            btn.icon:SetVertexColor(1, 1, 1, 1);           -- Normal
        end
        local cur = DM.GetCurrentStep(slotIndex);
        btn.step:SetText(cur .. "/" .. #slot.spells);
        SetCooldownCompat(btn.cooldown, data.spellID);
    elseif kind ~= "none" then
        btn.icon:SetVertexColor(1, 1, 1, 1);
        btn.step:SetText("");
        btn.cooldown:SetCooldown(0, 0);
    else
        btn.icon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
        btn.step:SetText("");
        btn.cooldown:SetCooldown(0, 0);
    end

    if slot.name and slot.name ~= "" then
        btn.chainName:SetText(slot.name);
    else
        btn.chainName:SetText("");
    end

    if slotIndex == DM.selectedSlot then
        btn:SetBackdropBorderColor(0.2, 0.8, 1, 1);
        btn.selectHighlight:Show();
    else
        btn:SetBackdropBorderColor(0.2, 0.35, 0.5, 0.6);
        btn.selectHighlight:Hide();
    end
end

function DM.UpdateAllSlots()
    for i = 1, DM.SLOT_COUNT do
        DM.UpdateSlotButton(i);
    end
end

function DM.SelectSlot(slotIndex)
    if not slotIndex or slotIndex < 1 or slotIndex > DM.SLOT_COUNT then return; end
    DM.selectedSlot = slotIndex;
    DM.editorSpells = {};

    local slot = DinoMacroDB.slots[slotIndex];
    if slot and slot.spells then
        for i = 1, #slot.spells do
            DM.editorSpells[i] = DM.CopySpell(slot.spells[i]);
        end
    end

    DM.UpdateEditorFields();
    DM.UpdateAllSlots();

    if DM.activeTab == "preview" then
        DM.UpdatePreviewView();
    end
end

---------------------------------------------------------------------------
-- Drag & Drop fuer Gegenstandsplaetze
---------------------------------------------------------------------------
function DM.ReceiveItem(slotNum)
    if InCombatLockdown() then
        DM.SetStatus(DM.L("STATUS_COMBAT_SAVE_NOTICE"), 1);
        return;
    end

    local cType, id, link = GetCursorInfo();
    if cType == "spell" then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_ITEM_ONLY"), 1);
        return;
    end
    if cType ~= "item" then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_ITEM_ONLY"), 1);
        return;
    end

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfoCompat(id or link);
    if not itemName then
        itemName = (link and string.match(link, "%[(.+)%]")) or ("Item " .. tostring(id));
    end
    if not itemTexture then
        itemTexture = GetItemIconCompat(id) or "Interface\\Icons\\INV_Misc_Bag_08";
    end

    -- Pruefen, ob der Gegenstand aktuell am Charakter ausgeruestet ist
    local equippedSlot = nil;
    for s = 1, 19 do
        local sId = GetInventoryItemID("player", s);
        local sLink = GetInventoryItemLink("player", s);
        if (sId and id and sId == id) or (sLink and link and sLink == link) then
            equippedSlot = s;
            break;
        end
    end

    if not equippedSlot and itemEquipLoc and DM.EQUIP_LOC_TO_SLOT[itemEquipLoc] then
        if PaperDollFrame and PaperDollFrame:IsShown() then
            equippedSlot = DM.EQUIP_LOC_TO_SLOT[itemEquipLoc];
        end
    end

    local s = DinoMacroDB.slots[DM.selectedSlot];
    local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;
    if not itemData then return; end

    if equippedSlot then
        itemData.kind = "equip";
        itemData.slotID = equippedSlot;
        itemData.target = tostring(equippedSlot);
        itemData.name = itemName;
        itemData.itemID = id;
        itemData.icon = itemTexture;
        itemData.enabled = true;
    else
        itemData.kind = "item";
        itemData.slotID = nil;
        itemData.target = itemName;
        itemData.name = itemName;
        itemData.itemID = id;
        itemData.icon = itemTexture;
        itemData.enabled = true;
    end

    ClearCursor();
    DM.UpdateItemSlotUI(slotNum);
    DM.SetStatus(string.format(DM.L("STATUS_ITEM_RECEIVED"), itemName), nil, true);

    if DM.activeTab == "preview" then
        DM.UpdatePreviewView();
    end
end

function DM.ClearItemSlot(slotNum)
    local s = DinoMacroDB.slots[DM.selectedSlot];
    local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;
    if not itemData then return; end

    itemData.enabled = false;
    itemData.kind = "item";
    itemData.target = "";
    itemData.itemID = nil;
    itemData.slotID = nil;
    itemData.name = "";
    itemData.icon = nil;
    itemData.condition = "always";
    itemData.position = "before";

    DM.UpdateItemSlotUI(slotNum);
    DM.SetStatus(DM.L("STATUS_ITEM_CLEARED"), nil, true);

    if DM.activeTab == "preview" then
        DM.UpdatePreviewView();
    end
end

function DM.UpdateItemSlotUI(slotNum)
    local f = DM.mainFrame;
    if not f then return; end
    local box = (slotNum == 1) and f.item1Box or f.item2Box;
    if not box then return; end

    local s = DinoMacroDB.slots[DM.selectedSlot];
    local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;

    box.title:SetText(slotNum == 1 and DM.L("ITEM_SLOT_1_LABEL") or DM.L("ITEM_SLOT_2_LABEL"));

    if itemData and itemData.enabled and (itemData.target ~= "" or itemData.itemID or itemData.slotID) then
        if itemData.icon then
            box.icon:SetTexture(itemData.icon);
        else
            box.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08");
        end
        box.icon:SetVertexColor(1, 1, 1, 1);

        if itemData.kind == "equip" and itemData.slotID then
            local slotName = DM.GetEquipmentSlotLabel(itemData.slotID);
            local name = itemData.name or itemData.target or ("Slot " .. itemData.slotID);
            box.subtitle:SetText(string.format(DM.L("EQUIP_SLOT_LABEL"), itemData.slotID) .. " (" .. slotName .. "): " .. name);
            box.subtitle:SetTextColor(0.2, 1, 0.7);
        else
            local name = itemData.name or itemData.target or ("Item " .. tostring(itemData.itemID));
            box.subtitle:SetText(name);
            box.subtitle:SetTextColor(0.4, 0.85, 1);
        end
        box.clearBtn:Show();
    else
        box.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot");
        box.icon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
        box.subtitle:SetText(DM.L("ITEM_DROP_HINT"));
        box.subtitle:SetTextColor(0.55, 0.65, 0.75);
        box.clearBtn:Hide();
    end

    local cond = (itemData and itemData.condition) or "always";
    box.condBtn:SetText(cond == "always" and DM.L("COND_ALWAYS") or (cond == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));

    local pos = (itemData and itemData.position) or "before";
    box.posBtn:SetText(pos == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
end

---------------------------------------------------------------------------
-- Begleiter-Steuerung UI-Aktualisierung
---------------------------------------------------------------------------
function DM.UpdateTrinketUI()
    local f = DM.mainFrame;
    if not f or not f.t1Icon then return; end

    local slot = DinoMacroDB.slots[DM.selectedSlot];
    if not slot then return; end

    -- Trinket 1 (Slot 13)
    local t1Enabled = slot.trinket1 and slot.trinket1.enabled or false;
    f.t1Check:SetChecked(t1Enabled);
    local t1Tex, t1Name, t1Link = GetInventoryItemCompat(13);
    f.t1Icon:SetTexture(t1Tex or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01");
    if t1Enabled then
        f.t1Icon:SetVertexColor(1, 1, 1, 1);
    else
        f.t1Icon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
    end
    if t1Tex then
        f.t1Info:SetText(t1Link or t1Name or "(Slot 13)");
        f.t1Info:SetTextColor(0.8, 0.9, 1);
    else
        f.t1Info:SetText(DM.L("TRINKET_NONE_EQUIPPED"));
        f.t1Info:SetTextColor(0.5, 0.5, 0.5);
    end
    if f.t1Cooldown and GetInventoryItemCooldown then
        local start, duration, enable = GetInventoryItemCooldown("player", 13);
        if enable == false or enable == 0 or not start or not duration then
            pcall(f.t1Cooldown.SetCooldown, f.t1Cooldown, 0, 0);
        else
            pcall(f.t1Cooldown.SetCooldown, f.t1Cooldown, start, duration);
        end
    end
    local t1Cond = slot.trinket1 and slot.trinket1.condition or "combat";
    f.t1CondBtn:SetText(t1Cond == "always" and DM.L("COND_ALWAYS") or (t1Cond == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
    f.t1PosBtn:SetText((slot.trinket1 and slot.trinket1.position == "after") and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));

    -- Trinket 2 (Slot 14)
    local t2Enabled = slot.trinket2 and slot.trinket2.enabled or false;
    f.t2Check:SetChecked(t2Enabled);
    local t2Tex, t2Name, t2Link = GetInventoryItemCompat(14);
    f.t2Icon:SetTexture(t2Tex or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01");
    if t2Enabled then
        f.t2Icon:SetVertexColor(1, 1, 1, 1);
    else
        f.t2Icon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
    end
    if t2Tex then
        f.t2Info:SetText(t2Link or t2Name or "(Slot 14)");
        f.t2Info:SetTextColor(0.8, 0.9, 1);
    else
        f.t2Info:SetText(DM.L("TRINKET_NONE_EQUIPPED"));
        f.t2Info:SetTextColor(0.5, 0.5, 0.5);
    end
    if f.t2Cooldown and GetInventoryItemCooldown then
        local start, duration, enable = GetInventoryItemCooldown("player", 14);
        if enable == false or enable == 0 or not start or not duration then
            pcall(f.t2Cooldown.SetCooldown, f.t2Cooldown, 0, 0);
        else
            pcall(f.t2Cooldown.SetCooldown, f.t2Cooldown, start, duration);
        end
    end
    local t2Cond = slot.trinket2 and slot.trinket2.condition or "combat";
    f.t2CondBtn:SetText(t2Cond == "always" and DM.L("COND_ALWAYS") or (t2Cond == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
    f.t2PosBtn:SetText((slot.trinket2 and slot.trinket2.position == "after") and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
end

function DM.UpdatePetControlsUI()
    local f = DM.mainFrame;
    if not f or not f.petIcon then return; end

    local s = DinoMacroDB.slots[DM.selectedSlot];
    local pet = s and s.petAction;

    local isEnabled = pet and pet.enabled or false;

    if f.petCheck then
        f.petCheck:SetChecked(isEnabled);
    end

    local petTex = DM.GetPetAttackTexture();
    f.petIcon:Show();
    DM.SafeSetSlotTexture(f.petIcon, petTex);

    if isEnabled then
        f.petIcon:SetVertexColor(1, 1, 1, 1);
    else
        f.petIcon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
    end

    local cond = pet and pet.condition or "always";
    f.petCondBtn:SetText(cond == "always" and DM.L("COND_ALWAYS") or (cond == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));

    local pos = pet and pet.position or "before";
    f.petPosBtn:SetText(pos == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
end

function DM.UpdateEditorFields()
    local f = DM.mainFrame;
    if not f then return; end

    local slot = DinoMacroDB.slots[DM.selectedSlot];
    if not slot then return; end

    f.editorTitle:SetText(DM.L("EDITOR_TITLE", DM.selectedSlot));
    f.nameEdit:SetText(slot.name or "");
    f.resetEdit:SetText(tostring(slot.resetSeconds or DM.DEFAULT_RESET));
    f.targetResetCheck:SetChecked(slot.resetOnTargetChange and true or false);
    f.mouseoverCheck:SetChecked(slot.useMouseover and true or false);

    if slot.useMouseover then
        f.mouseoverTypeBtn:Show();
        f.mouseoverTypeBtn:SetText(slot.mouseoverTargetType == "help" and DM.L("MOUSEOVER_HELP") or DM.L("MOUSEOVER_HARM"));
    else
        f.mouseoverTypeBtn:Hide();
    end

    local hasCombatCond = false;
    local hasNoCombatCond = false;

    for i = 1, DM.MAX_SPELLS do
        local field = DM.editorFields[i];
        local sp = DM.editorSpells[i];
        if field then
            if sp then
                local resolved = DM.ResolveSpell(sp);
                local displayName = (resolved and resolved.name) or sp.name or DM.L("UNKNOWN_SPELL");
                field.text:SetText(displayName);
                field.text:SetTextColor(1, 1, 1);
                field.hint:SetText(SpellSubtext(sp.spellID));

                local settings = DinoMacroDB and DinoMacroDB.settings or {};
                local showRange = settings.showRangeColor ~= false;
                local showRes = settings.showResourceColor ~= false;
                local targetUnit = slot.useMouseover and (UnitExists("mouseover") and "mouseover" or "target") or "target";
                local isOutOfRange, isResourceShortage = DM.GetSpellStatus(sp, targetUnit);

                field.icon:SetTexture(sp.icon or DM.QUESTION_ICON);
                if isOutOfRange and showRange then
                    field.icon:SetVertexColor(0.85, 0.15, 0.15, 1);
                elseif isResourceShortage and showRes then
                    field.icon:SetVertexColor(0.25, 0.45, 1, 1);
                else
                    field.icon:SetVertexColor(1, 1, 1, 1);
                end
                SetCooldownCompat(field.cooldown, sp.spellID);

                local cond = sp.combatCond or "always";
                if cond == "combat" then hasCombatCond = true;
                elseif cond == "nocombat" then hasNoCombatCond = true; end

                field.condAlwaysBtn:UnlockHighlight();
                field.condCombatBtn:UnlockHighlight();
                field.condNoCombatBtn:UnlockHighlight();

                if cond == "combat" then field.condCombatBtn:LockHighlight();
                elseif cond == "nocombat" then field.condNoCombatBtn:LockHighlight();
                else field.condAlwaysBtn:LockHighlight(); end

                field.condAlwaysBtn:SetText(DM.L("COND_ALWAYS"));
                field.condCombatBtn:SetText(DM.L("COND_COMBAT"));
                field.condNoCombatBtn:SetText(DM.L("COND_NOCOMBAT"));
                field.formBtn:SetText(DM.GetFormCondDisplay(sp.formCond));

                field.condAlwaysBtn:Show();
                field.condCombatBtn:Show();
                field.condNoCombatBtn:Show();
                field.formBtn:Show();
            else
                field.text:SetText(DM.L("SPELL_EMPTY"));
                field.text:SetTextColor(0.5, 0.5, 0.5);
                field.hint:SetText(DM.L("SPELL_DROP_HINT"));
                field.icon:SetTexture(DM.QUESTION_ICON);
                field.icon:SetVertexColor(0.3, 0.3, 0.3, 0.5);

                field.condAlwaysBtn:Hide();
                field.condCombatBtn:Hide();
                field.condNoCombatBtn:Hide();
                field.formBtn:Hide();
            end
        end
    end

    if hasCombatCond or hasNoCombatCond then
        f.groupingBanner:SetText("|cff33ff99" .. DM.L("GROUPING_INFO") .. ": [combat] und [nocombat] werden getrennt sequenziert.|r");
        f.groupingBanner:Show();
    else
        f.groupingBanner:Hide();
    end

    DM.LoadAdditionalActionsToUI(slot);
end

---------------------------------------------------------------------------
-- Robuste Spell-Erkennung (Behebt Lua-Fehler bei GetSpellBookItemType)
---------------------------------------------------------------------------
function DM.ReceiveSpell(fieldIndex)
    if InCombatLockdown() then
        DM.SetStatus(DM.L("STATUS_COMBAT_SAVE_NOTICE"), 1);
        return;
    end

    local cursorType, arg1, arg2, arg3 = GetCursorInfo();
    if not cursorType then
        DM.SetStatus(DM.L("STATUS_CURSOR_NOT_AVAILABLE"), 1);
        return;
    end

    if cursorType == "item" then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_DROP_PLAYER_SPELL"), 1);
        return;
    end

    if cursorType ~= "spell" then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_DROP_PLAYER_SPELL"), 1);
        return;
    end

    -- Pet-Zauber pruefen und ablehnen
    local isPetSpell = false;
    if arg2 == "pet" or (BOOKTYPE_PET and arg2 == BOOKTYPE_PET) then
        isPetSpell = true;
    elseif C_SpellBook and C_SpellBook.GetSpellBookItemType and type(arg1) == "number" then
        pcall(function()
            local bank = (arg2 == "pet") and (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1) or (Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0);
            local sType = C_SpellBook.GetSpellBookItemType(arg1, bank);
            if sType == (Enum.SpellBookItemType and Enum.SpellBookItemType.Pet) then
                isPetSpell = true;
            end
        end);
    end

    if isPetSpell then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_PET_SPELLS_NOT_SUPPORTED"), 1);
        return;
    end

    local spellName, spellID, spellIcon;

    -- Prioritaet 1: arg3 ist im Forever-/Classic-Client die direkte numerische spellID
    if type(arg3) == "number" and arg3 > 0 then
        local name, icon, id = SpellInfo(arg3);
        if name then
            spellName = name;
            spellIcon = icon;
            spellID = id or arg3;
        end
    end

    -- Prioritaet 2: arg1 direkt als spellID pruefen
    if not spellName and type(arg1) == "number" and arg1 > 0 then
        local name, icon, id = SpellInfo(arg1);
        if name then
            spellName = name;
            spellIcon = icon;
            spellID = id or arg1;
        end
    end

    -- Prioritaet 3: Aus dem Zauberbuch nach Buch-Slot-Index auslesen
    if not spellName and type(arg1) == "number" then
        local bookType = (type(arg2) == "string" and arg2) or "spell";
        pcall(function()
            if GetSpellBookItemName then
                local name = GetSpellBookItemName(arg1, bookType);
                if name then
                    spellName = name;
                    if GetSpellBookItemTexture then
                        spellIcon = GetSpellBookItemTexture(arg1, bookType);
                    end
                    local _, _, id = SpellInfo(name);
                    spellID = id;
                end
            end
        end);
    end

    -- Prioritaet 4: C_SpellBook Fallback
    if not spellName and C_SpellBook and C_SpellBook.GetSpellBookItemName and type(arg1) == "number" then
        pcall(function()
            local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0;
            local name = C_SpellBook.GetSpellBookItemName(arg1, bank);
            if name then
                spellName = name;
                local n, icon, id = SpellInfo(name);
                spellIcon = icon;
                spellID = id;
            end
        end);
    end

    if not spellName then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_SPELL_NOT_READ"), 1);
        return;
    end

    if spellID and IsSpellPassiveCompat(spellID) then
        ClearCursor();
        DM.SetStatus(DM.L("STATUS_PASSIVE_SPELL_WARN"), 1);
        return;
    end

    ClearCursor();

    local sp = {
        name = spellName,
        rank = SpellSubtext(spellID),
        spellID = spellID,
        icon = spellIcon or DM.QUESTION_ICON,
        combatCond = "always",
        formCond = ""
    };

    DM.editorSpells[fieldIndex] = sp;
    DM.UpdateEditorFields();
    DM.SetStatus(string.format(DM.L("STATUS_SPELL_RECEIVED"), spellName), nil, true);

    if DM.activeTab == "preview" then
        DM.UpdatePreviewView();
    end
end

function DM.RemoveEditorSpell(fieldIndex)
    if InCombatLockdown() then
        DM.SetStatus(DM.L("STATUS_COMBAT_SAVE_NOTICE"), 1);
        return;
    end
    table.remove(DM.editorSpells, fieldIndex);
    DM.UpdateEditorFields();
    DM.SetStatus(DM.L("STATUS_STEP_REMOVED"), nil, true);
    if DM.activeTab == "preview" then
        DM.UpdatePreviewView();
    end
end

function DM.LoadAdditionalActionsToUI(slot)
    local f = DM.mainFrame;
    if not f then return; end

    -- Schmuckstuecke (Slots 13 & 14)
    DM.UpdateTrinketUI();

    -- Freie Gegenstandsplaetze
    DM.UpdateItemSlotUI(1);
    DM.UpdateItemSlotUI(2);

    -- Begleitersteuerung (Petattack)
    DM.UpdatePetControlsUI();
end

---------------------------------------------------------------------------
-- Rechte Seite: Erweiterte Makro-Vorschau (Tab 2)
---------------------------------------------------------------------------
function DM.GenerateAllMacrosOverview()
    local lines = {};
    local pName = (UnitName and UnitName("player")) or "Spieler";
    table.insert(lines, DM.L("PREVIEW_ALL_HEADER"));
    table.insert(lines, "Charakter: " .. pName .. " | Datum/Version: " .. DM.VERSION_STRING);
    table.insert(lines, DM.L("PREVIEW_ALL_NOTE"));
    table.insert(lines, string.rep("-", 50));
    table.insert(lines, "");

    for i = 1, DM.SLOT_COUNT do
        local slot = DinoMacroDB.slots[i];
        local nameStr = (slot.name ~= "") and (" - " .. slot.name) or "";
        table.insert(lines, "[Slot " .. i .. nameStr .. "]");
        local body = DM.BuildSlotMacro(slot);
        if body and body ~= "" and body ~= "#showtooltip" then
            table.insert(lines, body);
        else
            table.insert(lines, "(Leer)");
        end
        table.insert(lines, "");
    end

    return table.concat(lines, "\n");
end

function DM.UpdatePreviewView()
    local f = DM.mainFrame;
    if not f or not f.previewEditBox then return; end

    f.previewCurBtn:UnlockHighlight();
    f.previewAllBtn:UnlockHighlight();

    if DM.previewMode == "all" then
        f.previewAllBtn:LockHighlight();
        f.previewCurBtn:SetText(DM.L("PREVIEW_MODE_CURRENT", DM.selectedSlot));
        f.previewAllBtn:SetText(DM.L("PREVIEW_MODE_ALL"));
        f.previewTitle:SetText(DM.L("PREVIEW_MODE_ALL"));

        local fullOverview = DM.GenerateAllMacrosOverview();
        f.previewEditBox:SetText(fullOverview);
        f.previewCharsLabel:SetText("Gesamtlaenge: " .. string.len(fullOverview) .. " Zeichen (14 Slots)");
        f.previewCharsLabel:SetTextColor(0.4, 0.8, 1);
        f.previewWarnLabel:Hide();
        f.previewOrderInfo:SetText(DM.L("PREVIEW_COPY_HINT"));
    else
        f.previewCurBtn:LockHighlight();
        f.previewCurBtn:SetText(DM.L("PREVIEW_MODE_CURRENT", DM.selectedSlot));
        f.previewAllBtn:SetText(DM.L("PREVIEW_MODE_ALL"));
        f.previewTitle:SetText(DM.L("PREVIEW_MODE_CURRENT", DM.selectedSlot));

        local slot = DinoMacroDB.slots[DM.selectedSlot];
        local candidate = {
            spells = DM.editorSpells,
            useMouseover = f.mouseoverCheck:GetChecked() and true or false,
            mouseoverTargetType = slot.mouseoverTargetType or "harm",
            resetSeconds = tonumber(f.resetEdit:GetText()) or DM.DEFAULT_RESET,
            resetOnTargetChange = f.targetResetCheck:GetChecked() and 1 or nil,
            trinket1 = slot.trinket1,
            trinket2 = slot.trinket2,
            itemSlot1 = slot.itemSlot1,
            itemSlot2 = slot.itemSlot2,
            petAction = slot.petAction
        };
        local macroText, _, _, charCount, isOverLimit = DM.BuildSlotMacro(candidate);

        f.previewEditBox:SetText(macroText);
        f.previewCharsLabel:SetText(DM.L("PREVIEW_CHARS", charCount, DM.MACRO_MAX_CHARS));

        if isOverLimit then
            f.previewCharsLabel:SetTextColor(1, 0.2, 0.2);
            f.previewWarnLabel:SetText(DM.L("PREVIEW_WARN_LIMIT", DM.MACRO_MAX_CHARS));
            f.previewWarnLabel:Show();
        else
            f.previewCharsLabel:SetTextColor(0.2, 1, 0.2);
            f.previewWarnLabel:Hide();
        end
        f.previewOrderInfo:SetText(DM.L("PREVIEW_ORDER_INFO"));
    end
end

---------------------------------------------------------------------------
-- Tab-Umschaltung (Editor, Makro-Vorschau, Einstellungen)
---------------------------------------------------------------------------
function DM.SwitchTab(tabName)
    if tabName ~= "preview" then tabName = "editor"; end
    DM.activeTab = tabName;
    local f = DM.mainFrame;
    if not f then return; end

    f.tabEditorBtn:UnlockHighlight();
    f.tabPreviewBtn:UnlockHighlight();

    f.editorView:Hide();
    f.previewView:Hide();

    if tabName == "editor" then
        f.tabEditorBtn:LockHighlight();
        f.editorView:Show();
    elseif tabName == "preview" then
        f.tabPreviewBtn:LockHighlight();
        f.previewView:Show();
        DM.UpdatePreviewView();
    end
end

function DM.SaveCurrentSlot()
    if not DM.selectedSlot then return; end

    local macroName = strtrim(DM.mainFrame.nameEdit:GetText() or "");
    if macroName == "" then
        macroName = "DM_" .. DM.selectedSlot;
    end

    local slot = DinoMacroDB.slots[DM.selectedSlot];

    -- Aktualisiere alle UI-Eingaben direkt in den Slot
    if DM.mainFrame.petCheck then
        slot.petAction.enabled = DM.mainFrame.petCheck:GetChecked() and true or false;
    end
    if DM.mainFrame.t1Check then
        slot.trinket1.enabled = DM.mainFrame.t1Check:GetChecked() and true or false;
    end
    if DM.mainFrame.t2Check then
        slot.trinket2.enabled = DM.mainFrame.t2Check:GetChecked() and true or false;
    end
    if DM.mainFrame.mouseoverCheck then
        slot.useMouseover = DM.mainFrame.mouseoverCheck:GetChecked() and true or false;
    end
    if DM.mainFrame.targetResetCheck then
        slot.resetOnTargetChange = DM.mainFrame.targetResetCheck:GetChecked() and 1 or nil;
    end

    local resetSeconds = tonumber(DM.mainFrame.resetEdit:GetText());
    if not resetSeconds or resetSeconds < 0 or resetSeconds > 3600 then
        resetSeconds = DM.DEFAULT_RESET;
    end
    slot.resetSeconds = math.floor(resetSeconds);

    -- Kompakte Zauberliste frisch aus den Klicks im Editor uebernehmen und sprachlich aufloesen
    local compact = {};
    for i = 1, DM.MAX_SPELLS do
        if DM.editorSpells[i] then
            local sp = DM.CopySpell(DM.editorSpells[i]);
            DM.ResolveSpell(sp);
            table.insert(compact, sp);
        end
    end

    local hasActions = (slot.trinket1 and slot.trinket1.enabled) or (slot.trinket2 and slot.trinket2.enabled) or
                       (slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.target and slot.itemSlot1.target ~= "") or
                       (slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.target and slot.itemSlot2.target ~= "") or
                       (slot.petAction and slot.petAction.enabled);

    slot.name = macroName;
    slot.spells = compact;
    slot.current = 1;

    if #compact == 0 and not hasActions then
        DM.ApplySecureSlot(DM.selectedSlot);
        DM.UpdateSlotMacro(DM.selectedSlot);
        DM.UpdateSlotButton(DM.selectedSlot);
        DM.SetStatus(DM.L("STATUS_DRAFT_SAVED"), nil, true);
        return;
    end

    -- Frische Neugenerierung des Makrotextes
    local body, _, _, charCount, isOverLimit = DM.BuildSlotMacro(slot);
    if isOverLimit then
        DM.SetStatus(DM.L("STATUS_MACRO_TOO_LONG", charCount), 1);
        return;
    end

    DM.ApplySecureSlot(DM.selectedSlot);
    DM.UpdateSlotMacro(DM.selectedSlot);
    DM.UpdateSlotButton(DM.selectedSlot);

    if InCombatLockdown() then
        DM.SetStatus(DM.L("SAVED_COMBAT_CONFIRM"), nil, true);
    else
        DM.SetStatus(string.format(DM.L("STATUS_SAVED"), DM.selectedSlot), nil, true);
    end

    if C_Timer and C_Timer.After then
        pcall(C_Timer.After, 3, function()
            if DM.mainFrame and DM.mainFrame:IsShown() and DM.mainFrame.statusText:GetText() == string.format(DM.L("STATUS_SAVED"), DM.selectedSlot) then
                DM.SetStatus(DM.L("STATUS_DEFAULT"), nil);
            end
        end);
    end
end

---------------------------------------------------------------------------
-- Leeren mit Bestaetigung
---------------------------------------------------------------------------
function DM.PerformClearSlot(slotIndex)
    if not slotIndex or not DinoMacroDB.slots[slotIndex] then return; end
    DinoMacroDB.slots[slotIndex] = DM.NewSlot();
    DM.editorSpells = {};

    if DM.mainFrame then
        DM.mainFrame.nameEdit:SetText("");
        DM.mainFrame.resetEdit:SetText(tostring(DM.DEFAULT_RESET));
        DM.mainFrame.targetResetCheck:SetChecked(false);
        DM.mainFrame.mouseoverCheck:SetChecked(false);
        DM.mainFrame.mouseoverTypeBtn:Hide();

        DM.LoadAdditionalActionsToUI(DinoMacroDB.slots[slotIndex]);
    end

    DM.ApplySecureSlot(slotIndex);
    DM.UpdateSlotMacro(slotIndex);
    DM.UpdateEditorFields();
    DM.UpdateSlotButton(slotIndex);
    DM.SetStatus(string.format(DM.L("STATUS_CLEARED"), slotIndex), nil, true);
end

function DM.ClearCurrentSlot()
    if not DM.selectedSlot then return; end
    local slot = DinoMacroDB.slots[DM.selectedSlot];
    local hasContent = (#slot.spells > 0) or (slot.name ~= "") or
                       (slot.trinket1 and slot.trinket1.enabled) or
                       (slot.trinket2 and slot.trinket2.enabled) or
                       (slot.itemSlot1 and slot.itemSlot1.enabled) or
                       (slot.itemSlot2 and slot.itemSlot2.enabled) or
                       (slot.petAction and slot.petAction.enabled and slot.petAction.command and slot.petAction.command ~= "");

    if not hasContent then
        DM.PerformClearSlot(DM.selectedSlot);
        return;
    end

    StaticPopupDialogs["DINOMACRO_CONFIRM_CLEAR"] = {
        text = DM.L("CONFIRM_CLEAR_MSG", DM.selectedSlot),
        button1 = DM.L("BTN_YES"),
        button2 = DM.L("BTN_NO"),
        OnAccept = function()
            DM.PerformClearSlot(DM.selectedSlot);
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    };
    StaticPopup_Show("DINOMACRO_CONFIRM_CLEAR");
end

---------------------------------------------------------------------------
-- "In Leiste ziehen" (Drag to Action Bar) - Zuverlaessige Synchronisation
---------------------------------------------------------------------------
function DM.PickupCurrentSlotMacro()
    if InCombatLockdown and InCombatLockdown() then
        DM.SetStatus(DM.L("ERR_COMBAT_LOCKDOWN"), 1);
        return;
    end

    local slot = DinoMacroDB.slots[DM.selectedSlot];
    if not slot then return; end

    -- Aktuelle Werte aus Eingabefeldern uebernehmen
    if DM.mainFrame and DM.mainFrame.nameEdit then
        local edName = strtrim(DM.mainFrame.nameEdit:GetText() or "");
        if edName ~= "" then slot.name = edName; end
    end
    if DM.mainFrame and DM.mainFrame.petCheck then
        slot.petAction.enabled = DM.mainFrame.petCheck:GetChecked() and true or false;
    end
    if DM.mainFrame and DM.mainFrame.t1Check then
        slot.trinket1.enabled = DM.mainFrame.t1Check:GetChecked() and true or false;
    end
    if DM.mainFrame and DM.mainFrame.t2Check then
        slot.trinket2.enabled = DM.mainFrame.t2Check:GetChecked() and true or false;
    end
    if DM.mainFrame and DM.mainFrame.mouseoverCheck then
        slot.useMouseover = DM.mainFrame.mouseoverCheck:GetChecked() and true or false;
    end

    local hasSpells = (slot.spells and #slot.spells > 0);
    local hasActions = (slot.trinket1 and slot.trinket1.enabled) or (slot.trinket2 and slot.trinket2.enabled) or
                       (slot.itemSlot1 and slot.itemSlot1.enabled and slot.itemSlot1.target and slot.itemSlot1.target ~= "") or
                       (slot.itemSlot2 and slot.itemSlot2.enabled and slot.itemSlot2.target and slot.itemSlot2.target ~= "") or
                       (slot.petAction and slot.petAction.enabled);

    if not hasSpells and not hasActions then
        DM.SetStatus(DM.L("STATUS_ACTION_REQUIRED_TO_DRAG"), 1);
        return;
    end

    local targetName = DM.GetSlotMacroName(DM.selectedSlot);
    local ok, err = DM.UpdateSlotMacro(DM.selectedSlot);

    local macroIndex = DM.FindSlotMacro(DM.selectedSlot);
    if macroIndex and macroIndex > 0 then
        PickupMacro(macroIndex);
        DM.SetStatus(string.format(DM.L("STATUS_MACRO_ON_CURSOR"), targetName), nil, true);
    else
        DM.SetStatus(err or DM.L("STATUS_NO_MACRO_SLOT"), 1);
    end
end

---------------------------------------------------------------------------
function DM.SavePosition()
    if not DM.mainFrame then return; end
    local point, _, relPoint, x, y = DM.mainFrame:GetPoint();
    DinoMacroDB.position = { point = point, relativePoint = relPoint, x = x, y = y };
end

function DM.RestorePosition()
    if not DM.mainFrame or not DinoMacroDB.position then return; end
    local p = DinoMacroDB.position;
    DM.mainFrame:ClearAllPoints();
    DM.mainFrame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or 0);
end

function DM.ResetPosition()
    if not DM.mainFrame then return; end
    DM.mainFrame:ClearAllPoints();
    DM.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    DM.SavePosition();
end

---------------------------------------------------------------------------
-- Aufbau der modernen Ein-Fenster-Oberflaeche
---------------------------------------------------------------------------
function DM.CreateUnifiedWindow()
    if DM.mainFrame then return; end

    local frame = CreateFrame("Frame", "DinoMacroFrame", UIParent, BACKDROP_TEMPLATE);
    frame:SetWidth(870);
    frame:SetHeight(640);
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    frame:SetFrameStrata("DIALOG");
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 28,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    });
    frame:EnableMouse(true);
    frame:SetMovable(true);
    frame:RegisterForDrag("LeftButton");
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving(); end
    end);
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        DM.SavePosition();
    end);
    frame:Hide();
    DM.mainFrame = frame;

    -- Kopfzeile: Titel, Sprachschalter, Schliessen
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
    title:SetPoint("TOP", frame, "TOP", 0, -14);
    title:SetText("|cff66ccff" .. DM.L("ADDON_TITLE") .. "|r");
    frame.title = title;

    local langBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    langBtn:SetWidth(125);
    langBtn:SetHeight(20);
    langBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12);
    langBtn:SetText(DinoMacroDB.locale == "deDE" and "|cff00ff00Deutsch|r | English" or "Deutsch | |cff00ff00English|r");
    langBtn:SetScript("OnClick", DM.ToggleLocale);
    frame.langBtn = langBtn;

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4);
    closeBtn:SetScript("OnClick", function() frame:Hide(); end);

    -----------------------------------------------------------------------
    -- Linker Bereich: 14 Slots Panel
    -----------------------------------------------------------------------
    local slotsPanel = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE);
    slotsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -38);
    slotsPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 44);
    slotsPanel:SetWidth(236);
    slotsPanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    });
    slotsPanel:SetBackdropColor(0.02, 0.04, 0.07, 0.95);
    slotsPanel:SetBackdropBorderColor(0.2, 0.45, 0.65, 0.8);
    frame.slotsPanel = slotsPanel;

    local slotsHeader = slotsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    slotsHeader:SetPoint("TOP", slotsPanel, "TOP", 0, -8);
    slotsHeader:SetText(DM.L("HEADER_SLOTS"));
    frame.slotsHeader = slotsHeader;

    -- Die 14 Slot-Knoepfe (2 Spalten x 7 Zeilen)
    for i = 1, DM.SLOT_COUNT do
        local btnIndex = i;
        local template = BACKDROP_TEMPLATE or nil;
        local btn = CreateFrame("Button", "DinoMacroSlot" .. i, slotsPanel, template);
        btn:SetWidth(108);
        btn:SetHeight(60);
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        });
        btn:SetBackdropColor(0.03, 0.06, 0.1, 0.95);
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp");

        local col = (i > 7) and 1 or 0;
        local row = math.fmod(i - 1, 7);
        btn:SetPoint("TOPLEFT", slotsPanel, "TOPLEFT", 6 + col * 114, -26 - row * 66);

        btn.number = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        btn.number:SetPoint("TOPLEFT", btn, "TOPLEFT", 4, -3);
        btn.number:SetText(tostring(i));

        btn.icon = btn:CreateTexture(nil, "ARTWORK");
        btn.icon:SetWidth(28);
        btn.icon:SetHeight(28);
        btn.icon:SetPoint("TOP", btn, "TOP", 0, -11);
        btn.icon:SetTexture(DM.QUESTION_ICON);

        btn.cooldown = CreateFrame("Cooldown", "DinoMacroCooldown" .. i, btn, "CooldownFrameTemplate");
        btn.cooldown:SetWidth(28);
        btn.cooldown:SetHeight(28);
        btn.cooldown:SetPoint("TOP", btn, "TOP", 0, -11);

        btn.cooldownText = btn.cooldown:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
        btn.cooldownText:SetPoint("CENTER", btn.cooldown, "CENTER", 0, 0);

        btn.step = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
        btn.step:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -4, -3);

        btn.chainName = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
        btn.chainName:SetWidth(100);
        btn.chainName:SetHeight(12);
        btn.chainName:SetPoint("BOTTOM", btn, "BOTTOM", 0, 3);

        btn.selectHighlight = btn:CreateTexture(nil, "OVERLAY");
        btn.selectHighlight:SetAllPoints(btn);
        btn.selectHighlight:SetColorTexture(0.2, 0.8, 0.7, 0.15);
        btn.selectHighlight:Hide();

        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD");

        btn:SetScript("OnClick", function(self)
            DM.SelectSlot(btnIndex);
        end);

        btn:SetScript("OnEnter", function(self)
            local s = DinoMacroDB.slots[btnIndex];
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(DM.L("TOOLTIP_SLOT", btnIndex) .. (s.name ~= "" and (" - " .. s.name) or ""));
            local sp = s.spells and s.spells[DM.GetCurrentStep(btnIndex)];
            if sp then GameTooltip:AddLine(DM.L("TOOLTIP_NEXT_STEP", sp.name), 1, 1, 1); end
            GameTooltip:AddLine(DM.L("TOOLTIP_SELECT"), 0.5, 0.9, 1);
            GameTooltip:Show();
        end);
        btn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

        DM.slotButtons[i] = btn;
    end

    -- "In Leiste ziehen" direkt unter Slot 7 und Slot 14
    local actionbarBtn = CreateFrame("Button", nil, slotsPanel, "UIPanelButtonTemplate");
    actionbarBtn:SetPoint("TOPLEFT", slotsPanel, "TOPLEFT", 6, -492);
    actionbarBtn:SetPoint("TOPRIGHT", slotsPanel, "TOPRIGHT", -6, -492);
    actionbarBtn:SetHeight(24);
    actionbarBtn:SetText(DM.L("BTN_ACTIONBAR"));
    actionbarBtn:RegisterForDrag("LeftButton");
    actionbarBtn:SetScript("OnDragStart", DM.PickupCurrentSlotMacro);
    actionbarBtn:SetScript("OnClick", DM.PickupCurrentSlotMacro);
    frame.actionbarBtn = actionbarBtn;

    -----------------------------------------------------------------------
    -- Rechter Bereich: Arbeitsbereich mit 2 Tabs (Kette & Aktionen, Vorschau)
    -----------------------------------------------------------------------
    local workspacePanel = CreateFrame("Frame", nil, frame, BACKDROP_TEMPLATE);
    workspacePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 258, -38);
    workspacePanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 44);
    workspacePanel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    });
    workspacePanel:SetBackdropColor(0.02, 0.04, 0.07, 0.95);
    workspacePanel:SetBackdropBorderColor(0.2, 0.45, 0.65, 0.8);
    frame.workspacePanel = workspacePanel;

    local tabEditorBtn = CreateFrame("Button", nil, workspacePanel, "UIPanelButtonTemplate");
    tabEditorBtn:SetWidth(180);
    tabEditorBtn:SetHeight(24);
    tabEditorBtn:SetPoint("TOPLEFT", workspacePanel, "TOPLEFT", 12, -8);
    tabEditorBtn:SetText(DM.L("TAB_EDITOR"));
    tabEditorBtn:SetScript("OnClick", function() DM.SwitchTab("editor"); end);
    frame.tabEditorBtn = tabEditorBtn;

    local tabPreviewBtn = CreateFrame("Button", nil, workspacePanel, "UIPanelButtonTemplate");
    tabPreviewBtn:SetWidth(180);
    tabPreviewBtn:SetHeight(24);
    tabPreviewBtn:SetPoint("LEFT", tabEditorBtn, "RIGHT", 8, 0);
    tabPreviewBtn:SetText(DM.L("TAB_PREVIEW"));
    tabPreviewBtn:SetScript("OnClick", function() DM.SwitchTab("preview"); end);
    frame.tabPreviewBtn = tabPreviewBtn;

    -----------------------------------------------------------------------
    -- Ansicht 1: Editor View
    -----------------------------------------------------------------------
    local editorView = CreateFrame("Frame", nil, workspacePanel);
    editorView:SetPoint("TOPLEFT", workspacePanel, "TOPLEFT", 0, -36);
    editorView:SetPoint("BOTTOMRIGHT", workspacePanel, "BOTTOMRIGHT", 0, 0);
    frame.editorView = editorView;

    local editorTitle = editorView:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    editorTitle:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -4);
    frame.editorTitle = editorTitle;

    -- Zeile 1: Makroname, Zeitreset, Targetreset
    local nameLabel = editorView:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    nameLabel:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -22);
    nameLabel:SetText(DM.L("LABEL_NAME"));
    frame.nameLabel = nameLabel;

    local nameEdit = CreateFrame("EditBox", "DinoMacroNameEdit", editorView, "InputBoxTemplate");
    nameEdit:SetWidth(130);
    nameEdit:SetHeight(20);
    nameEdit:SetPoint("LEFT", nameLabel, "RIGHT", 6, 0);
    nameEdit:SetAutoFocus(false);
    nameEdit:SetMaxLetters(24);
    frame.nameEdit = nameEdit;

    local resetLabel = editorView:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    resetLabel:SetPoint("LEFT", nameEdit, "RIGHT", 14, 0);
    resetLabel:SetText(DM.L("RESET_TIME_LABEL"));
    frame.resetLabel = resetLabel;

    local resetEdit = CreateFrame("EditBox", "DinoMacroResetEdit", editorView, "InputBoxTemplate");
    resetEdit:SetWidth(34);
    resetEdit:SetHeight(20);
    resetEdit:SetPoint("LEFT", resetLabel, "RIGHT", 6, 0);
    resetEdit:SetAutoFocus(false);
    resetEdit:SetMaxLetters(4);
    frame.resetEdit = resetEdit;

    local targetResetCheck = CreateFrame("CheckButton", nil, editorView, "UICheckButtonTemplate");
    targetResetCheck:SetWidth(20);
    targetResetCheck:SetHeight(20);
    targetResetCheck:SetPoint("LEFT", resetEdit, "RIGHT", 12, 0);
    frame.targetResetCheck = targetResetCheck;

    local targetResetLabel = editorView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    targetResetLabel:SetPoint("LEFT", targetResetCheck, "RIGHT", 2, 0);
    targetResetLabel:SetText(DM.L("RESET_TARGET_CHECK"));
    frame.targetResetLabel = targetResetLabel;

    local mouseoverCheck = CreateFrame("CheckButton", nil, editorView, "UICheckButtonTemplate");
    mouseoverCheck:SetWidth(20);
    mouseoverCheck:SetHeight(20);
    mouseoverCheck:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -44);
    mouseoverCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked();
        local s = DinoMacroDB.slots[DM.selectedSlot];
        s.useMouseover = isChecked and true or false;
        if isChecked then
            frame.mouseoverTypeBtn:Show();
        else
            frame.mouseoverTypeBtn:Hide();
        end
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.mouseoverCheck = mouseoverCheck;

    local mouseoverLabel = editorView:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    mouseoverLabel:SetPoint("LEFT", mouseoverCheck, "RIGHT", 4, 0);
    mouseoverLabel:SetText(DM.L("MOUSEOVER_CHECK"));
    frame.mouseoverLabel = mouseoverLabel;

    local mouseoverTypeBtn = CreateFrame("Button", nil, editorView, "UIPanelButtonTemplate");
    mouseoverTypeBtn:SetWidth(85);
    mouseoverTypeBtn:SetHeight(18);
    mouseoverTypeBtn:SetPoint("LEFT", mouseoverLabel, "RIGHT", 8, 0);
    mouseoverTypeBtn:SetText(DM.L("MOUSEOVER_HARM"));
    mouseoverTypeBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        if s.mouseoverTargetType == "help" then
            s.mouseoverTargetType = "harm";
            self:SetText(DM.L("MOUSEOVER_HARM"));
        else
            s.mouseoverTargetType = "help";
            self:SetText(DM.L("MOUSEOVER_HELP"));
        end
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    mouseoverTypeBtn:SetScript("OnEnter", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(DM.L("TOOLTIP_MOUSEOVER_TITLE"), 1, 1, 1);
        if s.mouseoverTargetType == "help" then
            GameTooltip:AddLine(DM.L("TOOLTIP_MOUSEOVER_HELP_DESC"), 0.2, 1, 0.5, true);
        else
            GameTooltip:AddLine(DM.L("TOOLTIP_MOUSEOVER_HARM_DESC"), 1, 0.4, 0.4, true);
        end
        GameTooltip:AddLine(DM.L("TOOLTIP_MOUSEOVER_CLICK_HINT"), 0.7, 0.7, 0.7);
        GameTooltip:Show();
    end);
    mouseoverTypeBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    mouseoverTypeBtn:Hide();
    frame.mouseoverTypeBtn = mouseoverTypeBtn;

    mouseoverCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked();
        local s = DinoMacroDB.slots[DM.selectedSlot];
        s.useMouseover = isChecked and true or false;
        if isChecked then
            mouseoverTypeBtn:Show();
        else
            mouseoverTypeBtn:Hide();
        end
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);

    -- Die 4 Zauberschritte (ab Y = -66, rein Zauber!)
    for i = 1, DM.MAX_SPELLS do
        local fieldIndex = i;
        local field = CreateFrame("Button", "DinoMacroField" .. i, editorView, BACKDROP_TEMPLATE);
        field:SetWidth(568);
        field:SetHeight(36);
        field:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -66 - (i - 1) * 40);
        field:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        });
        field:SetBackdropColor(0.04, 0.07, 0.11, 0.95);
        field:RegisterForDrag("LeftButton");
        field:RegisterForClicks("LeftButtonUp", "RightButtonUp");

        field.icon = field:CreateTexture(nil, "ARTWORK");
        field.icon:SetWidth(28);
        field.icon:SetHeight(28);
        field.icon:SetPoint("LEFT", field, "LEFT", 5, 0);

        local fCooldown = CreateFrame("Cooldown", nil, field, "CooldownFrameTemplate");
        fCooldown:SetWidth(28);
        fCooldown:SetHeight(28);
        fCooldown:SetPoint("LEFT", field, "LEFT", 5, 0);
        local fCooldownText = fCooldown:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge");
        fCooldownText:SetPoint("CENTER", fCooldown, "CENTER", 0, 0);
        field.cooldown = fCooldown;
        field.cooldownText = fCooldownText;

        field.text = field:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        field.text:SetPoint("TOPLEFT", field, "TOPLEFT", 38, -4);
        field.text:SetWidth(170);
        field.text:SetJustifyH("LEFT");

        field.hint = field:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
        field.hint:SetPoint("BOTTOMLEFT", field, "BOTTOMLEFT", 38, 4);
        field.hint:SetTextColor(0.55, 0.65, 0.75);

        -- Gestalt-/Haltungsbedingung Knopf (Rechtsbuendig mit festem Rand verankert)
        local formBtn = CreateFrame("Button", nil, field, "UIPanelButtonTemplate");
        formBtn:SetWidth(105);
        formBtn:SetHeight(18);
        formBtn:SetPoint("RIGHT", field, "RIGHT", -6, 0);
        formBtn:SetText(DM.L("FORM_NONE"));

        -- Nicht-Kampfbedingung Knopf
        local cNoCombatBtn = CreateFrame("Button", nil, field, "UIPanelButtonTemplate");
        cNoCombatBtn:SetWidth(88);
        cNoCombatBtn:SetHeight(18);
        cNoCombatBtn:SetPoint("RIGHT", formBtn, "LEFT", -5, 0);
        cNoCombatBtn:SetText(DM.L("COND_NOCOMBAT"));
        cNoCombatBtn:SetScript("OnClick", function()
            if DM.editorSpells[fieldIndex] then
                DM.editorSpells[fieldIndex].combatCond = "nocombat";
                DM.UpdateEditorFields();
                if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
            end
        end);
        field.condNoCombatBtn = cNoCombatBtn;

        -- Kampfbedingung Knopf
        local cCombatBtn = CreateFrame("Button", nil, field, "UIPanelButtonTemplate");
        cCombatBtn:SetWidth(76);
        cCombatBtn:SetHeight(18);
        cCombatBtn:SetPoint("RIGHT", cNoCombatBtn, "LEFT", -5, 0);
        cCombatBtn:SetText(DM.L("COND_COMBAT"));
        cCombatBtn:SetScript("OnClick", function()
            if DM.editorSpells[fieldIndex] then
                DM.editorSpells[fieldIndex].combatCond = "combat";
                DM.UpdateEditorFields();
                if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
            end
        end);
        field.condCombatBtn = cCombatBtn;

        -- Immer Knopf
        local cAlwaysBtn = CreateFrame("Button", nil, field, "UIPanelButtonTemplate");
        cAlwaysBtn:SetWidth(60);
        cAlwaysBtn:SetHeight(18);
        cAlwaysBtn:SetPoint("RIGHT", cCombatBtn, "LEFT", -5, 0);
        cAlwaysBtn:SetText(DM.L("COND_ALWAYS"));
        cAlwaysBtn:SetScript("OnClick", function()
            if DM.editorSpells[fieldIndex] then
                DM.editorSpells[fieldIndex].combatCond = "always";
                DM.UpdateEditorFields();
                if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
            end
        end);
        field.condAlwaysBtn = cAlwaysBtn;
        formBtn:SetText(DM.L("FORM_NONE"));
        formBtn:SetScript("OnClick", function(self)
            if not DM.editorSpells[fieldIndex] then return; end
            local sp = DM.editorSpells[fieldIndex];
            local forms = DM.GetAvailableForms();
            if #forms == 0 then
                DM.SetStatus(DM.L("STATUS_NO_FORMS_AVAILABLE"), 1);
                sp.formCond = "";
            else
                sp.formCond = CycleNextFormCond(sp.formCond or "");
            end
            DM.UpdateEditorFields();
            if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
        end);

        formBtn:SetScript("OnEnter", function(self)
            local sp = DM.editorSpells[fieldIndex];
            if not sp then return; end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(DM.L("TOOLTIP_FORM_TITLE"), 1, 1, 1);
            GameTooltip:AddLine(DM.L("TOOLTIP_FORM_DESC"), 0.7, 0.7, 0.7, true);
            GameTooltip:AddLine("Aktuelle Bedingung: " .. DM.GetFormCondDisplay(sp.formCond), 0.2, 0.8, 1);
            local forms = DM.GetAvailableForms();
            if #forms > 0 then
                GameTooltip:AddLine("Verfügbare Gestalten:", 1, 0.8, 0.2);
                for _, f in ipairs(forms) do
                    GameTooltip:AddLine(" - " .. f.name .. " (Form " .. f.index .. ")", 0.8, 0.8, 0.8);
                end
            else
                GameTooltip:AddLine(DM.L("STATUS_NO_FORMS_AVAILABLE"), 0.6, 0.6, 0.6);
            end
            GameTooltip:AddLine("Klicken zum Umschalten (Jede -> Nur Form -> Nicht Form -> Normalform)", 0.5, 0.9, 0.5);
            GameTooltip:Show();
        end);
        formBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);

        field.formBtn = formBtn;

        field:SetScript("OnReceiveDrag", function() DM.ReceiveSpell(fieldIndex); end);
        field:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                DM.RemoveEditorSpell(fieldIndex);
            elseif mouseButton == "LeftButton" then
                if GetCursorInfo and GetCursorInfo() then
                    DM.ReceiveSpell(fieldIndex);
                end
            end
        end);

        DM.editorFields[i] = field;
    end

    -- Gruppierungs-Anzeigebanner
    local groupingBanner = editorView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    groupingBanner:SetPoint("TOPLEFT", editorView, "TOPLEFT", 14, -228);
    groupingBanner:SetWidth(564);
    groupingBanner:SetJustifyH("LEFT");
    frame.groupingBanner = groupingBanner;

    -----------------------------------------------------------------------
    -- Zusatzaktionsbereich (Sauber strukturiert ohne ueberladene Elemente)
    -----------------------------------------------------------------------
    local actionsHeader = editorView:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    actionsHeader:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -244);
    actionsHeader:SetText(DM.L("SEC_ACTIONS_TITLE"));
    frame.actionsHeader = actionsHeader;

    local actionsBox = CreateFrame("Frame", nil, editorView, BACKDROP_TEMPLATE);
    actionsBox:SetPoint("TOPLEFT", editorView, "TOPLEFT", 12, -260);
    actionsBox:SetPoint("BOTTOMRIGHT", editorView, "BOTTOMRIGHT", -12, 8);
    actionsBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    });
    actionsBox:SetBackdropColor(0.03, 0.05, 0.08, 0.95);
    actionsBox:SetBackdropBorderColor(0.2, 0.45, 0.65, 0.7);

    -- 1. Schmuckstueck 1 (Slot 13) - Dynamisches Icon & Cooldown
    local t1Check = CreateFrame("CheckButton", nil, actionsBox, "UICheckButtonTemplate");
    t1Check:SetWidth(20);
    t1Check:SetHeight(20);
    t1Check:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 6, -6);
    t1Check:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        s.trinket1.enabled = self:GetChecked() and true or false;
        DM.UpdateTrinketUI();
        DM.UpdateSlotButton(DM.selectedSlot);
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t1Check = t1Check;

    local t1IconFrame = CreateFrame("Button", nil, actionsBox);
    t1IconFrame:SetWidth(20);
    t1IconFrame:SetHeight(20);
    t1IconFrame:SetPoint("LEFT", t1Check, "RIGHT", 4, 0);
    local t1Icon = t1IconFrame:CreateTexture(nil, "ARTWORK");
    t1Icon:SetAllPoints();
    frame.t1Icon = t1Icon;
    local t1Cooldown = CreateFrame("Cooldown", nil, t1IconFrame, "CooldownFrameTemplate");
    t1Cooldown:SetAllPoints();
    frame.t1Cooldown = t1Cooldown;
    t1IconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        local hasItem = GetInventoryItemID("player", 13);
        if hasItem then
            GameTooltip:SetInventoryItem("player", 13);
        else
            GameTooltip:SetText(DM.L("TRINKET_1_LABEL"), 1, 1, 1);
            GameTooltip:AddLine(DM.L("TRINKET_NONE_EQUIPPED"), 0.7, 0.7, 0.7);
            GameTooltip:AddLine(DM.L("TRINKET_SLOT_13_DESC"), 0.5, 0.8, 1, true);
        end
        GameTooltip:Show();
    end);
    t1IconFrame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    frame.t1IconFrame = t1IconFrame;

    local t1Label = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    t1Label:SetPoint("LEFT", t1IconFrame, "RIGHT", 6, 0);
    t1Label:SetText(DM.L("TRINKET_1_LABEL"));
    frame.t1Label = t1Label;

    local t1Info = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    t1Info:SetPoint("LEFT", t1Label, "RIGHT", 6, 0);
    t1Info:SetWidth(150);
    t1Info:SetJustifyH("LEFT");
    frame.t1Info = t1Info;

    local t1PosBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    t1PosBtn:SetWidth(75);
    t1PosBtn:SetHeight(18);
    t1PosBtn:SetPoint("TOPRIGHT", actionsBox, "TOPRIGHT", -8, -6);
    t1PosBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local p = s.trinket1.position or "before";
        s.trinket1.position = (p == "before" and "after" or "before");
        self:SetText(s.trinket1.position == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t1PosBtn = t1PosBtn;

    local t1CondBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    t1CondBtn:SetWidth(78);
    t1CondBtn:SetHeight(18);
    t1CondBtn:SetPoint("RIGHT", t1PosBtn, "LEFT", -4, 0);
    t1CondBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local c = s.trinket1.condition or "combat";
        c = (c == "combat" and "always" or (c == "always" and "nocombat" or "combat"));
        s.trinket1.condition = c;
        self:SetText(c == "always" and DM.L("COND_ALWAYS") or (c == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t1CondBtn = t1CondBtn;

    -- 2. Schmuckstueck 2 (Slot 14) - Dynamisches Icon & Cooldown
    local t2Check = CreateFrame("CheckButton", nil, actionsBox, "UICheckButtonTemplate");
    t2Check:SetWidth(20);
    t2Check:SetHeight(20);
    t2Check:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 6, -28);
    t2Check:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        s.trinket2.enabled = self:GetChecked() and true or false;
        DM.UpdateTrinketUI();
        DM.UpdateSlotButton(DM.selectedSlot);
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t2Check = t2Check;

    local t2IconFrame = CreateFrame("Button", nil, actionsBox);
    t2IconFrame:SetWidth(20);
    t2IconFrame:SetHeight(20);
    t2IconFrame:SetPoint("LEFT", t2Check, "RIGHT", 4, 0);
    local t2Icon = t2IconFrame:CreateTexture(nil, "ARTWORK");
    t2Icon:SetAllPoints();
    frame.t2Icon = t2Icon;
    local t2Cooldown = CreateFrame("Cooldown", nil, t2IconFrame, "CooldownFrameTemplate");
    t2Cooldown:SetAllPoints();
    frame.t2Cooldown = t2Cooldown;
    t2IconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        local hasItem = GetInventoryItemID("player", 14);
        if hasItem then
            GameTooltip:SetInventoryItem("player", 14);
        else
            GameTooltip:SetText(DM.L("TRINKET_2_LABEL"), 1, 1, 1);
            GameTooltip:AddLine(DM.L("TRINKET_NONE_EQUIPPED"), 0.7, 0.7, 0.7);
            GameTooltip:AddLine(DM.L("TRINKET_SLOT_14_DESC"), 0.5, 0.8, 1, true);
        end
        GameTooltip:Show();
    end);
    t2IconFrame:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    frame.t2IconFrame = t2IconFrame;

    local t2Label = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    t2Label:SetPoint("LEFT", t2IconFrame, "RIGHT", 6, 0);
    t2Label:SetText(DM.L("TRINKET_2_LABEL"));
    frame.t2Label = t2Label;

    local t2Info = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    t2Info:SetPoint("LEFT", t2Label, "RIGHT", 6, 0);
    t2Info:SetWidth(150);
    t2Info:SetJustifyH("LEFT");
    frame.t2Info = t2Info;

    local t2PosBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    t2PosBtn:SetWidth(75);
    t2PosBtn:SetHeight(18);
    t2PosBtn:SetPoint("TOPRIGHT", actionsBox, "TOPRIGHT", -8, -28);
    t2PosBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local p = s.trinket2.position or "before";
        s.trinket2.position = (p == "before" and "after" or "before");
        self:SetText(s.trinket2.position == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t2PosBtn = t2PosBtn;

    local t2CondBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    t2CondBtn:SetWidth(78);
    t2CondBtn:SetHeight(18);
    t2CondBtn:SetPoint("RIGHT", t2PosBtn, "LEFT", -4, 0);
    t2CondBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local c = s.trinket2.condition or "combat";
        c = (c == "combat" and "always" or (c == "always" and "nocombat" or "combat"));
        s.trinket2.condition = c;
        self:SetText(c == "always" and DM.L("COND_ALWAYS") or (c == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.t2CondBtn = t2CondBtn;

    -- Ueberschrift: Freie Gegenstandsplaetze
    local itemHeader = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    itemHeader:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 8, -48);
    itemHeader:SetText(DM.L("ITEM_HEADER_TITLE"));
    frame.itemHeader = itemHeader;

    -- Helper fuer Drag & Drop Gegenstandsplaetze (im Stil der oberen Zauberfelder)
    local function CreateItemSlotBox(slotNum, yOffset)
        local box = CreateFrame("Button", "DinoMacroItemBox" .. slotNum, actionsBox, BACKDROP_TEMPLATE);
        box:SetWidth(552);
        box:SetHeight(36);
        box:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 6, yOffset);
        box:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        });
        box:SetBackdropColor(0.04, 0.07, 0.11, 0.95);
        box:SetBackdropBorderColor(0.2, 0.45, 0.65, 0.8);
        box:RegisterForDrag("LeftButton");
        box:RegisterForClicks("LeftButtonUp", "RightButtonUp");

        box.icon = box:CreateTexture(nil, "ARTWORK");
        box.icon:SetWidth(28);
        box.icon:SetHeight(28);
        box.icon:SetPoint("LEFT", box, "LEFT", 5, 0);

        box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
        box.title:SetPoint("TOPLEFT", box, "TOPLEFT", 38, -4);
        box.title:SetJustifyH("LEFT");

        box.subtitle = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
        box.subtitle:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 38, 4);
        box.subtitle:SetWidth(280);
        box.subtitle:SetJustifyH("LEFT");

        local clearBtn = CreateFrame("Button", nil, box, "UIPanelButtonTemplate");
        clearBtn:SetWidth(20);
        clearBtn:SetHeight(18);
        clearBtn:SetPoint("RIGHT", box, "RIGHT", -6, 0);
        clearBtn:SetText("X");
        clearBtn:SetScript("OnClick", function() DM.ClearItemSlot(slotNum); end);
        box.clearBtn = clearBtn;

        local posBtn = CreateFrame("Button", nil, box, "UIPanelButtonTemplate");
        posBtn:SetWidth(75);
        posBtn:SetHeight(18);
        posBtn:SetPoint("RIGHT", clearBtn, "LEFT", -4, 0);
        posBtn:SetScript("OnClick", function(self)
            local s = DinoMacroDB.slots[DM.selectedSlot];
            local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;
            local p = itemData.position or "before";
            itemData.position = (p == "before" and "after" or "before");
            self:SetText(itemData.position == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
            if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
        end);
        box.posBtn = posBtn;

        local condBtn = CreateFrame("Button", nil, box, "UIPanelButtonTemplate");
        condBtn:SetWidth(78);
        condBtn:SetHeight(18);
        condBtn:SetPoint("RIGHT", posBtn, "LEFT", -4, 0);
        condBtn:SetScript("OnClick", function(self)
            local s = DinoMacroDB.slots[DM.selectedSlot];
            local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;
            local c = itemData.condition or "always";
            c = (c == "always" and "combat" or (c == "combat" and "nocombat" or "always"));
            itemData.condition = c;
            self:SetText(c == "always" and DM.L("COND_ALWAYS") or (c == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
            if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
        end);
        box.condBtn = condBtn;

        box:SetScript("OnReceiveDrag", function() DM.ReceiveItem(slotNum); end);
        box:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                DM.ClearItemSlot(slotNum);
            elseif mouseButton == "LeftButton" then
                if GetCursorInfo and GetCursorInfo() then
                    DM.ReceiveItem(slotNum);
                end
            end
        end);

        box:SetScript("OnEnter", function(self)
            local s = DinoMacroDB.slots[DM.selectedSlot];
            local itemData = (slotNum == 1) and s.itemSlot1 or s.itemSlot2;
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(slotNum == 1 and DM.L("ITEM_SLOT_1_LABEL") or DM.L("ITEM_SLOT_2_LABEL"));
            if itemData and itemData.enabled and (itemData.target ~= "" or itemData.itemID) then
                if itemData.kind == "equip" and itemData.slotID then
                    GameTooltip:AddLine(string.format(DM.L("EQUIP_SLOT_LABEL"), itemData.slotID) .. " (" .. DM.GetEquipmentSlotLabel(itemData.slotID) .. ")", 1, 1, 1);
                    if itemData.name then GameTooltip:AddLine(itemData.name, 0.2, 1, 0.7); end
                    GameTooltip:AddLine("Makrobefehl: /use " .. itemData.slotID, 0.7, 0.7, 0.7);
                else
                    if itemData.name then GameTooltip:AddLine(itemData.name, 1, 1, 1); end
                    GameTooltip:AddLine("Makrobefehl: /use " .. itemData.target, 0.7, 0.7, 0.7);
                end
                GameTooltip:AddLine(DM.L("TOOLTIP_ITEM_RIGHT_CLICK"), 1, 0.4, 0.4);
            else
                GameTooltip:AddLine(DM.L("ITEM_DROP_HINT"), 0.7, 0.7, 0.7);
                GameTooltip:AddLine(DM.L("ITEM_DESIGN_HINT"), 0.5, 0.8, 1, true);
            end
            GameTooltip:Show();
        end);
        box:SetScript("OnLeave", function() GameTooltip:Hide(); end);

        return box;
    end

    frame.item1Box = CreateItemSlotBox(1, -64);
    frame.item2Box = CreateItemSlotBox(2, -104);

    local itemDesignHint = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    itemDesignHint:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 8, -144);
    itemDesignHint:SetPoint("RIGHT", actionsBox, "RIGHT", -8, 0);
    itemDesignHint:SetJustifyH("LEFT");
    itemDesignHint:SetTextColor(0.5, 0.6, 0.7);
    itemDesignHint:SetText(DM.L("ITEM_DESIGN_HINT"));
    frame.itemDesignHint = itemDesignHint;

    -- 3. Begleiter-Steuerung (Kompakte Petattack-Zeile, kein Modus-Umschalter, Y = -162)
    local petCheck = CreateFrame("CheckButton", nil, actionsBox, "UICheckButtonTemplate");
    petCheck:SetWidth(20);
    petCheck:SetHeight(20);
    petCheck:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", 6, -164);
    petCheck:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        if not s.petAction then
            s.petAction = { enabled = false, command = "/petattack", condition = "always", position = "before" };
        end
        s.petAction.enabled = self:GetChecked() and true or false;
        s.petAction.command = "/petattack";
        DM.UpdatePetControlsUI();
        DM.UpdateSlotButton(DM.selectedSlot);
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.petCheck = petCheck;

    local petIcon = actionsBox:CreateTexture(nil, "ARTWORK");
    petIcon:SetWidth(20);
    petIcon:SetHeight(20);
    petIcon:SetPoint("LEFT", petCheck, "RIGHT", 4, 0);
    frame.petIcon = petIcon;

    local petLabel = actionsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    petLabel:SetPoint("LEFT", petIcon, "RIGHT", 6, 0);
    petLabel:SetText(DM.L("PET_ATTACK_LABEL"));
    frame.petLabel = petLabel;

    local petPosBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    petPosBtn:SetWidth(75);
    petPosBtn:SetHeight(20);
    petPosBtn:SetPoint("TOPRIGHT", actionsBox, "TOPRIGHT", -8, -164);
    petPosBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local p = s.petAction.position or "before";
        s.petAction.position = (p == "before" and "after" or "before");
        self:SetText(s.petAction.position == "after" and DM.L("ACTION_POS_AFTER") or DM.L("ACTION_POS_BEFORE"));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.petPosBtn = petPosBtn;

    local petCondBtn = CreateFrame("Button", nil, actionsBox, "UIPanelButtonTemplate");
    petCondBtn:SetWidth(78);
    petCondBtn:SetHeight(20);
    petCondBtn:SetPoint("RIGHT", petPosBtn, "LEFT", -4, 0);
    petCondBtn:SetScript("OnClick", function(self)
        local s = DinoMacroDB.slots[DM.selectedSlot];
        local c = s.petAction.condition or "always";
        c = (c == "always" and "combat" or (c == "combat" and "nocombat" or "always"));
        s.petAction.condition = c;
        self:SetText(c == "always" and DM.L("COND_ALWAYS") or (c == "nocombat" and DM.L("COND_NOCOMBAT") or DM.L("COND_COMBAT")));
        if DM.activeTab == "preview" then DM.UpdatePreviewView(); end
    end);
    frame.petCondBtn = petCondBtn;

    -----------------------------------------------------------------------
    -- Ansicht 2: Preview View (Erweitert: Aktuelles Makro / Alle 14 Makros)
    -----------------------------------------------------------------------
    local previewView = CreateFrame("Frame", nil, workspacePanel);
    previewView:SetPoint("TOPLEFT", workspacePanel, "TOPLEFT", 12, -36);
    previewView:SetPoint("BOTTOMRIGHT", workspacePanel, "BOTTOMRIGHT", -12, 0);
    previewView:Hide();
    frame.previewView = previewView;

    local previewTitle = previewView:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    previewTitle:SetPoint("TOPLEFT", previewView, "TOPLEFT", 0, -4);
    frame.previewTitle = previewTitle;

    local previewCurBtn = CreateFrame("Button", nil, previewView, "UIPanelButtonTemplate");
    previewCurBtn:SetWidth(160);
    previewCurBtn:SetHeight(20);
    previewCurBtn:SetPoint("TOPLEFT", previewView, "TOPLEFT", 0, -22);
    previewCurBtn:SetText(DM.L("PREVIEW_MODE_CURRENT", DM.selectedSlot));
    previewCurBtn:SetScript("OnClick", function()
        DM.previewMode = "current";
        DM.UpdatePreviewView();
    end);
    frame.previewCurBtn = previewCurBtn;

    local previewAllBtn = CreateFrame("Button", nil, previewView, "UIPanelButtonTemplate");
    previewAllBtn:SetWidth(140);
    previewAllBtn:SetHeight(20);
    previewAllBtn:SetPoint("LEFT", previewCurBtn, "RIGHT", 6, 0);
    previewAllBtn:SetText(DM.L("PREVIEW_MODE_ALL"));
    previewAllBtn:SetScript("OnClick", function()
        DM.previewMode = "all";
        DM.UpdatePreviewView();
    end);
    frame.previewAllBtn = previewAllBtn;

    -- Button "Text kopieren"
    local copyTextBtn = CreateFrame("Button", nil, previewView, "UIPanelButtonTemplate");
    copyTextBtn:SetWidth(120);
    copyTextBtn:SetHeight(20);
    copyTextBtn:SetPoint("TOPRIGHT", previewView, "TOPRIGHT", -22, -22);
    copyTextBtn:SetText(DM.L("BTN_COPY_TEXT"));
    frame.copyTextBtn = copyTextBtn;

    local previewScroll = CreateFrame("ScrollFrame", "DinoMacroPreviewScroll", previewView, "UIPanelScrollFrameTemplate");
    previewScroll:SetPoint("TOPLEFT", previewView, "TOPLEFT", 0, -46);
    previewScroll:SetPoint("BOTTOMRIGHT", previewView, "BOTTOMRIGHT", -22, 60);

    local previewEditBox = CreateFrame("EditBox", "DinoMacroPreviewBox", previewScroll);
    previewEditBox:SetWidth(530);
    previewEditBox:SetMultiLine(true);
    previewEditBox:SetAutoFocus(false);
    previewEditBox:SetFontObject("GameFontHighlightSmall");
    previewEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    previewScroll:SetScrollChild(previewEditBox);
    frame.previewEditBox = previewEditBox;

    copyTextBtn:SetScript("OnClick", function()
        previewEditBox:SetFocus();
        previewEditBox:HighlightText();
        DM.SetStatus(DM.L("STATUS_TEXT_COPIED"), nil, true);
    end);

    local previewCharsLabel = previewView:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    previewCharsLabel:SetPoint("BOTTOMLEFT", previewView, "BOTTOMLEFT", 0, 36);
    frame.previewCharsLabel = previewCharsLabel;

    local previewWarnLabel = previewView:CreateFontString(nil, "OVERLAY", "GameFontRedSmall");
    previewWarnLabel:SetPoint("BOTTOMLEFT", previewView, "BOTTOMLEFT", 0, 20);
    frame.previewWarnLabel = previewWarnLabel;

    local previewOrderInfo = previewView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    previewOrderInfo:SetPoint("BOTTOMLEFT", previewView, "BOTTOMLEFT", 0, 4);
    previewOrderInfo:SetText(DM.L("PREVIEW_ORDER_INFO"));
    frame.previewOrderInfo = previewOrderInfo;

    -----------------------------------------------------------------------
    -- Untere Leiste: Entwickler-Signatur "by X4rinia", Statusmeldung & 2 Knoepfe
    -----------------------------------------------------------------------
    local authorSign = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    authorSign:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 12);
    authorSign:SetText("|cffffd100by X4rinia|r");
    frame.authorSign = authorSign;

    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    statusText:SetPoint("LEFT", authorSign, "RIGHT", 14, 0);
    statusText:SetWidth(420);
    statusText:SetJustifyH("LEFT");
    statusText:SetText(DM.L("STATUS_DEFAULT"));
    frame.statusText = statusText;

    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    saveBtn:SetWidth(100);
    saveBtn:SetHeight(22);
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 10);
    saveBtn:SetText(DM.L("BTN_SAVE"));
    saveBtn:SetScript("OnClick", DM.SaveCurrentSlot);
    frame.saveBtn = saveBtn;

    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
    clearBtn:SetWidth(100);
    clearBtn:SetHeight(22);
    clearBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0);
    clearBtn:SetText(DM.L("BTN_CLEAR"));
    clearBtn:SetScript("OnClick", DM.ClearCurrentSlot);
    frame.clearBtn = clearBtn;

    -- OnUpdate-Schleife fuer Cooldown-Sweeps und Icons
    frame:SetScript("OnUpdate", function(self, elapsed)

        DM.updateElapsed = (DM.updateElapsed or 0) + elapsed;
        DM.rangeElapsed = (DM.rangeElapsed or 0) + elapsed;

        -- A. Native Cooldown-Frames aktualisieren (alle 0.15s, direkt via SetCooldown)
        if DM.updateElapsed >= 0.15 then
            DM.updateElapsed = 0;

            for i = 1, DM.SLOT_COUNT do
                local btn = DM.slotButtons[i];
                if btn and btn.cooldown then
                    local kind, data = DM.GetCurrentActionForSlot(i);
                    local start, duration, enable = nil, nil, nil;

                    if kind == "spell" and data and (data.spellID or data.name) then
                        start, duration, enable = GetSpellCooldownCompat(data.spellID or data.name);
                    elseif kind == "trinket" and data then
                        start, duration, enable = GetInventoryItemCooldownCompat(data);
                    elseif kind == "item" and data then
                        if data.kind == "equip" and data.slotID then
                            start, duration, enable = GetInventoryItemCooldownCompat(data.slotID);
                        elseif data.itemID then
                            start, duration, enable = GetItemCooldownCompat(data.itemID);
                        end
                    end

                    if enable == false or enable == 0 or not start or not duration then
                        pcall(btn.cooldown.SetCooldown, btn.cooldown, 0, 0);
                    else
                        pcall(btn.cooldown.SetCooldown, btn.cooldown, start, duration);
                    end
                end
            end

            for i = 1, DM.MAX_SPELLS do
                local field = DM.editorFields[i];
                if field and field.cooldown then
                    local sp = DM.editorSpells[i];
                    local start, duration, enable = nil, nil, nil;
                    if sp and (sp.spellID or sp.name) then
                        start, duration, enable = GetSpellCooldownCompat(sp.spellID or sp.name);
                    end

                    if enable == false or enable == 0 or not start or not duration then
                        pcall(field.cooldown.SetCooldown, field.cooldown, 0, 0);
                    else
                        pcall(field.cooldown.SetCooldown, field.cooldown, start, duration);
                    end
                end
            end
        end

        -- B. Zeit-Reset & dynamische Icons (alle 0.20s)
        if DM.rangeElapsed >= 0.20 then
            DM.rangeElapsed = 0;

            -- Zeit-Reset fuer Kettenschritte pruefen (resetSeconds)
            local now = GetTime();
            for rIdx = 1, DM.SLOT_COUNT do
                local rSlot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[rIdx];
                if rSlot and rSlot.spells and #rSlot.spells > 1 and (rSlot.current or 1) ~= 1 then
                    if rSlot.resetSeconds and rSlot.resetSeconds > 0 and rSlot.lastCastTime then
                        if (now - rSlot.lastCastTime) >= rSlot.resetSeconds then
                            rSlot.current = 1;
                            rSlot.lastCastTime = nil;
                            DM.UpdateSlotButton(rIdx);
                        end
                    end
                end
            end

            -- Slot-Icons aktualisieren
            for i = 1, DM.SLOT_COUNT do
                local btn = DM.slotButtons[i];
                local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[i];
                if btn and slot then
                    local kind, data = DM.GetCurrentActionForSlot(i);
                    local currentIcon = DM.GetSlotIcon(i);
                    DM.SafeSetSlotTexture(btn.icon, currentIcon);

                    if kind ~= "none" then
                        btn.icon:SetVertexColor(1, 1, 1, 1);
                    else
                        btn.icon:SetVertexColor(0.5, 0.5, 0.5, 0.6);
                    end
                end
            end

            -- Editor-Felder Icons aktualisieren
            if DM.activeTab == "editor" and DM.selectedSlot then
                for i = 1, DM.MAX_SPELLS do
                    local field = DM.editorFields[i];
                    local sp = DM.editorSpells[i];
                    if field and sp and sp.icon then
                        field.icon:SetVertexColor(1, 1, 1, 1);
                    end
                end
            end
        end
    end);

    DM.RestorePosition();
    for i = 1, DM.SLOT_COUNT do
        DM.ApplySecureSlot(i);
    end

    DM.SelectSlot(1);
    DM.SwitchTab("editor");
end

---------------------------------------------------------------------------
-- Lokalisierung auf dem Hauptfenster anwenden
---------------------------------------------------------------------------
function DM.ApplyLocale()
    local f = DM.mainFrame;
    if not f then return; end

    f.title:SetText("|cff66ccff" .. DM.L("ADDON_TITLE") .. "|r");
    f.langBtn:SetText(DinoMacroDB.locale == "deDE" and "|cff00ff00Deutsch|r | English" or "Deutsch | |cff00ff00English|r");
    f.slotsHeader:SetText(DM.L("HEADER_SLOTS"));
    f.actionbarBtn:SetText(DM.L("BTN_ACTIONBAR"));
    f.tabEditorBtn:SetText(DM.L("TAB_EDITOR"));
    f.tabPreviewBtn:SetText(DM.L("TAB_PREVIEW"));
-- [1.4.14: Settings tab labels removed]

    f.editorTitle:SetText(DM.L("EDITOR_TITLE", DM.selectedSlot));
    f.nameLabel:SetText(DM.L("LABEL_NAME"));
    f.resetLabel:SetText(DM.L("RESET_TIME_LABEL"));
    f.targetResetLabel:SetText(DM.L("RESET_TARGET_CHECK"));
    f.mouseoverLabel:SetText(DM.L("MOUSEOVER_CHECK"));
    local s = DinoMacroDB.slots[DM.selectedSlot];
    f.mouseoverTypeBtn:SetText(s.mouseoverTargetType == "help" and DM.L("MOUSEOVER_HELP") or DM.L("MOUSEOVER_HARM"));
    f.petLabel:SetText(DM.L("PET_ATTACK_LABEL"));
    f.actionsHeader:SetText(DM.L("SEC_ACTIONS_TITLE"));
    f.itemHeader:SetText(DM.L("ITEM_HEADER_TITLE"));
    f.itemDesignHint:SetText(DM.L("ITEM_DESIGN_HINT"));
    f.t1Label:SetText(DM.L("TRINKET_1_LABEL"));
    f.t2Label:SetText(DM.L("TRINKET_2_LABEL"));

    f.previewCurBtn:SetText(DM.L("PREVIEW_MODE_CURRENT", DM.selectedSlot));
    f.previewAllBtn:SetText(DM.L("PREVIEW_MODE_ALL"));
    f.copyTextBtn:SetText(DM.L("BTN_COPY_TEXT"));

    f.saveBtn:SetText(DM.L("BTN_SAVE"));
    f.clearBtn:SetText(DM.L("BTN_CLEAR"));
    f.statusText:SetText(DM.L("STATUS_DEFAULT"));

    DM.UpdateEditorFields();
    DM.UpdateAllSlots();
end

---------------------------------------------------------------------------
-- Events & Initialisierung
---------------------------------------------------------------------------
function DM.OnEvent(eventName, ...)
    local firstArg = ...;
    if eventName == "ADDON_LOADED" then
        if firstArg == "DinoMacro" then
            DM.InitializeDB();
            if not DM.mainFrame then
                DM.CreateUnifiedWindow();
            end
        end
        return;
    end
    if eventName == "PLAYER_LOGIN" then
        for i = 1, DM.SLOT_COUNT do
            DM.ApplySecureSlot(i);
            DM.UpdateSlotMacro(i);
        end
        DM.UpdateAllSlots();
        if not DM.sessionAnnounced then
            DM.sessionAnnounced = true;
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDinoMacro 1.4.15|r |cffffd100by X4rinia|r – /dm");
            end
        end
        return;
    end
    if eventName == "PLAYER_EQUIPMENT_CHANGED" or eventName == "BAG_UPDATE_COOLDOWN" or eventName == "ACTIONBAR_UPDATE_COOLDOWN" then
        if DM.mainFrame and DM.mainFrame:IsShown() then
            DM.UpdateTrinketUI();
            DM.UpdateAllSlots();
        end
        return;
    end
    if eventName == "UNIT_PET" or eventName == "PET_BAR_UPDATE" or eventName == "PET_UI_UPDATE" then
        if DM.mainFrame and DM.mainFrame:IsShown() then
            DM.UpdatePetControlsUI();
            DM.UpdateAllSlots();
        end
        return;
    end
    -- 1.4.15: Zauber erfolgreich gewirkt -> Kettenschritt dynamisch weiterschalten
    if eventName == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, a2, a3, a4, a5 = ...;
        if unit == "player" then
            local now = GetTime();
            local spellID = nil;
            local spellName = nil;

            if type(a2) == "string" then
                spellName = a2;
            end
            if type(a3) == "number" then
                spellID = a3;
            elseif type(a5) == "number" then
                spellID = a5;
            elseif type(a2) == "number" then
                spellID = a2;
            end

            if not spellName and spellID then
                if C_Spell and C_Spell.GetSpellName then
                    pcall(function() spellName = C_Spell.GetSpellName(spellID); end);
                end
                if not spellName and GetSpellInfo then
                    pcall(function() spellName = GetSpellInfo(spellID); end);
                end
            end

            local function Normalize(str)
                if not str then return ""; end
                local s = string.lower(str);
                s = s:gsub("%s*%(.*%)", "");
                s = s:gsub("%s+", "");
                return s;
            end

            local normCast = Normalize(spellName);

            for sIdx = 1, DM.SLOT_COUNT do
                local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[sIdx];
                if slot and slot.spells and #slot.spells > 1 then
                    local cur = DM.GetCurrentStep(sIdx);
                    local curSpell = slot.spells[cur];
                    if curSpell then
                        local match = false;
                        if spellID and curSpell.spellID and (curSpell.spellID == spellID) then
                            match = true;
                        elseif normCast ~= "" and Normalize(curSpell.name) == normCast then
                            match = true;
                        end
                        if match then
                            slot.current = cur + 1;
                            if slot.current > #slot.spells then
                                slot.current = 1;
                            end
                            slot.lastCastTime = now;
                            DM.UpdateSlotButton(sIdx);
                            DM.DebugLog("Slot %d: Sequenz weitergeschaltet auf Schritt %d (%s)", sIdx, slot.current, tostring(slot.spells[slot.current] and slot.spells[slot.current].name));
                        end
                    end
                end
            end
        end
        return;
    end

    if eventName == "PLAYER_TARGET_CHANGED" then
        -- Reset bei Zielwechsel
        for sIdx = 1, DM.SLOT_COUNT do
            local slot = DinoMacroDB and DinoMacroDB.slots and DinoMacroDB.slots[sIdx];
            if slot and slot.resetOnTargetChange and (slot.current or 1) ~= 1 then
                slot.current = 1;
                DM.UpdateSlotButton(sIdx);
            end
        end
        if DM.mainFrame and DM.mainFrame:IsShown() then
            DM.UpdateAllSlots();
            DM.UpdateEditorFields();
        end
        return;
    end

    if eventName == "UPDATE_MOUSEOVER_UNIT" or eventName == "UNIT_POWER_UPDATE" or eventName == "SPELL_UPDATE_USABLE" then
        if DM.mainFrame and DM.mainFrame:IsShown() then
            DM.UpdateAllSlots();
            DM.UpdateEditorFields();
        end
        return;
    end
    if eventName == "PLAYER_LOGOUT" then
        DM.SavePosition();
        return;
    end
    if eventName == "PLAYER_REGEN_ENABLED" then
        DM.ApplyPendingSlots();
        return;
    end
    if eventName == "PLAYER_REGEN_DISABLED" then
        DM.SetStatus(DM.L("STATUS_COMBAT_SAVE_NOTICE"), nil);
        return;
    end
    if DM.mainFrame and DM.mainFrame:IsShown() then
        DM.UpdateAllSlots();
    end
end


function DinoMacro_Toggle()
    if not DM.mainFrame then
        DM.CreateUnifiedWindow();
    end
    if DM.mainFrame:IsShown() then
        DM.mainFrame:Hide();
    else
        DM.mainFrame:Show();
        DM.UpdateAllSlots();
        DM.SelectSlot(DM.selectedSlot or 1);
    end
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------
SLASH_DINOMACRO1 = "/dinomacro";
SLASH_DINOMACRO2 = "/dm";
SlashCmdList["DINOMACRO"] = function(msg)
    msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"));
    if msg == "debug" then
        DinoMacroDB.debug = not DinoMacroDB.debug;
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDinoMacro:|r " .. (DinoMacroDB.debug and DM.L("DEBUG_ENABLED") or DM.L("DEBUG_DISABLED")));
        end
    elseif msg == "settings" or msg == "config" then
        if not DM.mainFrame then DM.CreateUnifiedWindow(); end
        DM.mainFrame:Show();
        DM.SwitchTab("editor");
    elseif msg == "reset" then
        DM.ResetPosition();
    elseif msg == "preview" then
        if not DM.mainFrame then DM.CreateUnifiedWindow(); end
        DM.mainFrame:Show();
        DM.SwitchTab("preview");
    else
        DinoMacro_Toggle();
    end
end

---------------------------------------------------------------------------
-- Event-Registrierung
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame", "DinoMacroEventFrame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:RegisterEvent("PLAYER_LOGIN");
eventFrame:RegisterEvent("PLAYER_LOGOUT");
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
eventFrame:RegisterEvent("SPELLS_CHANGED");
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
eventFrame:RegisterEvent("UNIT_PET");
eventFrame:RegisterEvent("PET_BAR_UPDATE");
eventFrame:RegisterEvent("PET_UI_UPDATE");
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
eventFrame:RegisterEvent("UNIT_POWER_UPDATE");
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
eventFrame:RegisterEvent("SPELL_UPDATE_USABLE");
eventFrame:SetScript("OnEvent", function(self, event, ...)
    DM.OnEvent(event, ...);
end);
