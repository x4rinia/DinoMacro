-- DinoMacro 1.4.17 - Lokalisierungsdatei (Deutsch & English)
-- Created by X4rinia
-- Created by X4rinia
-- Author: x4rinia

local addonName, addonTable = ...;
local DM = addonTable or _G.DinoMacro or {};
_G.DinoMacro = DM;

DM.Locales = {
    deDE = {
        -- Allgemein & Titel
        ADDON_NAME = "DinoMacro",
        ADDON_TITLE = "DinoMacro 1.4.17",
        SLASH_HINT = "DinoMacro geöffnet. Befehl: /dinomacro oder /dm",
        LANG_SWITCH = "Sprache: DE | EN",
        LANG_NAME = "Deutsch",

        -- Hauptfenster & Slots
        HEADER_SLOTS = "14 Makro-Slots",
        TOOLTIP_SLOT = "Slot %d",
        TOOLTIP_EMPTY = "Leer",
        TOOLTIP_SELECT = "Klicken zum Auswählen",
        TOOLTIP_NEXT_STEP = "Nächster Schritt: %s",
        TOOLTIP_ACTIONBAR = "Auf Aktionsleiste ziehen",
        BTN_ACTIONBAR = "In Leiste ziehen",
        BTN_SAVE = "Speichern",
        BTN_CLEAR = "Leeren",
        BTN_CLOSE = "Schließen",
        BTN_SETTINGS = "Einstellungen",
        SETTINGS_TITLE = "DinoMacro - Einstellungen",
        SETTING_COOLDOWN_NUMBERS = "Cooldown als Zahl anzeigen",
        SETTING_COOLDOWN_DESC = "Zeigt die verbleibende Abklingzeit als numerischen Countdown auf den DinoMacro-Icons an. (Aktionsleisten nutzen native Blizzard-Anzeige).",
        SETTING_RESOURCE_COLOR = "Fehlende Ressource blau anzeigen",
        SETTING_RESOURCE_DESC = "Färbt DinoMacro-Icons blau ein, wenn nicht genügend Mana, Wut, Energie oder Fokus vorhanden ist. (Aktionsleisten nutzen native Manadimmung).",
        SETTING_RANGE_COLOR = "Außer Reichweite rot anzeigen",
        SETTING_RANGE_DESC = "Färbt DinoMacro-Icons rot ein, wenn das Ziel außer Reichweite ist. (Aktionsleisten nutzen nativen Reichweitenpunkt via #showtooltip).",
        SETTING_ACTIONBAR_NOTE = "Hinweis: Blizzard-Aktionsleisten sind geschützt und nutzen für Reichweite und Cooldowns die native #showtooltip-Steuerung.",
        STATUS_DEFAULT = "Bereit. Slot auswählen und Aktionen konfigurieren.",
        STATUS_SAVED = "Slot %d erfolgreich gespeichert!",
        STATUS_CLEARED = "Slot %d geleert.",
        LABEL_NAME = "Makroname*:",

        -- Reiter (Tabs)
        TAB_EDITOR = "Kette & Aktionen",
        TAB_PREVIEW = "Makro-Vorschau",
        TAB_SETTINGS = "Einstellungen",
        SETTING_SEC_TITLE = "Statusanzeigen & Anzeige-Optionen",
        ERR_COMBAT_LOCKDOWN = "Makros können im Kampf nicht erstellt oder auf die Leiste gezogen werden.",
        DEBUG_ENABLED = "DinoMacro Debug-Modus aktiviert.",
        DEBUG_DISABLED = "DinoMacro Debug-Modus deaktiviert.",

        -- Editor & Kette
        EDITOR_TITLE = "Makro-Editor für Slot %d",
        RESET_TIME_LABEL = "Zeitreset (Sek.): 0 = aus",
        RESET_TARGET_CHECK = "Bei Zielwechsel zurücksetzen",
        AUTHOR_SIGNATURE = "by X4rinia",
        CHAT_LOAD_MSG = "DinoMacro 1.4.17 by X4rinia – /dm",
        MOUSEOVER_CHECK = "Mouseover aktivieren",
        MOUSEOVER_HARM = "Feindlich",
        MOUSEOVER_HELP = "Freundlich",
        TOOLTIP_MOUSEOVER_TITLE = "Mouseover-Modus",
        TOOLTIP_MOUSEOVER_HARM_DESC = "Wirkt auf feindliche Mouseover-Ziele ([@mouseover,harm,nodead]). Bei keinem Mouseover-Ziel wird das normale Ziel anvisiert.",
        TOOLTIP_MOUSEOVER_HELP_DESC = "Wirkt auf freundliche Mouseover-Ziele ([@mouseover,help,nodead]). Bei keinem Mouseover-Ziel wird das normale Ziel anvisiert.",
        TOOLTIP_MOUSEOVER_CLICK_HINT = "Klicken zum Umschalten (Freundlich <-> Feindlich)",
        MOUSEOVER_COMBINED = "Kombiniert",
        MOUSEOVER_EXACT = "Priorität: [@mouseover,exists,nodead]",
        SEC_SPELLS_TITLE = "Zauberkette (Genau 4 Zauberschritte)",
        SPELL_EMPTY = "Leer - Zauber hierher ziehen",
        SPELL_DROP_HINT = "Aus Zauberbuch ablegen",
        COND_ALWAYS = "Immer",
        COND_COMBAT = "Im Kampf",
        COND_NOCOMBAT = "Außerhalb",
        FORM_NONE = "Jede Gestalt",
        FORM_HUMANOID = "Normalform (keine Gestalt)",
        FORM_PREFIX_ONLY = "Nur:",
        FORM_PREFIX_NOT = "Nicht:",
        STATUS_NO_FORMS_AVAILABLE = "Für deine Klasse sind keine unterstützten Gestalten oder Haltungen verfügbar.",
        TOOLTIP_FORM_TITLE = "Gestalt-/Haltungsbedingung",
        TOOLTIP_FORM_DESC = "Prüft beim Ausführen die aktuelle Gestalt oder Haltung des Charakters.",
        GROUPING_INFO = "Automatische Kampfgruppierung: aktiv",
        UNKNOWN_SPELL = "Unbekannter Zauber",

        -- Statusmeldungen im Editor
        STATUS_NAME_REQUIRED = "Bitte gib einen Makronamen ein.",
        STATUS_ACTION_REQUIRED_TO_DRAG = "Mindestens eine Aktion wird benötigt, um das Makro in die Leiste zu ziehen.",
        STATUS_DRAFT_SAVED = "Makro als Entwurf gespeichert (mindestens eine Aktion für Ausführung erforderlich).",
        STATUS_STEP_CLEARED = "Schritt entfernt.",
        STATUS_STEP_REMOVED = "Schritt entfernt.",
        STATUS_CURSOR_NOT_AVAILABLE = "GetCursorInfo nicht verfügbar.",
        STATUS_DROP_PLAYER_SPELL = "Bitte einen Zauber aus dem Zauberbuch ablegen.",
        STATUS_PET_SPELLS_NOT_SUPPORTED = "Pet-Zauberbuch wird in den oberen Feldern nicht unterstützt.",
        STATUS_SPELL_NOT_READ = "Der abgelegte Zauber konnte nicht gelesen werden.",
        STATUS_PASSIVE_SPELL_WARN = "Passive Zauber können nicht ausgelöst werden.",
        STATUS_SPELL_RECEIVED = "%s abgelegt.",
        STATUS_STEP_RANGE_ERR = "Eine Kette braucht mindestens 1 Schritt oder eine Zusatzaktion.",
        STATUS_STEP_UNAVAILABLE = "Schritt %d ist nicht verfügbar.",
        STATUS_RESET_RANGE_ERR = "Resetzeit muss zwischen 0 und 3600 Sekunden liegen.",
        STATUS_MACRO_TOO_LONG = "Makrotext zu lang (%d/255 Zeichen). Bitte kürzen.",
        STATUS_SLOT_CLEARED = "Der Slot wurde vollständig geleert.",
        STATUS_SAVE_FIRST_WARN = "Bitte die Kette zuerst mit 'Speichern' sichern!",
        STATUS_COMBAT_SAVE_NOTICE = "Im Kampf: Änderungen werden nach dem Kampf aktiv.",
        STATUS_NO_MACRO_SLOT = "Kein freier charakterspezifischer Makroplatz vorhanden.",
        STATUS_MACRO_ON_CURSOR = "%s liegt am Cursor: auf Aktionsleiste ziehen.",
        STATUS_ITEM_ONLY = "Hier können nur Gegenstände abgelegt werden.",
        STATUS_ITEM_CLEARED = "Gegenstand entfernt.",
        STATUS_ITEM_RECEIVED = "%s abgelegt.",
        STATUS_TEXT_COPIED = "Text markiert. Mit Strg+C in die Zwischenablage kopieren.",

        -- Zusätzliche Aktionen
        SEC_ACTIONS_TITLE = "Zusätzliche Aktionen",
        ACTION_POS_BEFORE = "Vor Kette",
        ACTION_POS_AFTER = "Nach Kette",
        TRINKET_1_LABEL = "Schmuckstück 1 (13)",
        TRINKET_2_LABEL = "Schmuckstück 2 (14)",
        TRINKET_NONE_EQUIPPED = "Kein Schmuck angelegt",
        TRINKET_SLOT_13_DESC = "Löst /use 13 aus. Funktioniert auch, wenn erst später angelegt.",
        TRINKET_SLOT_14_DESC = "Löst /use 14 aus. Funktioniert auch, wenn erst später angelegt.",
        PET_ATTACK_LABEL = "Pet angreifen",
        PET_ATTACK_DESC = "Löst /petattack [harm,nodead] aus. Funktioniert auch, wenn das Pet erst später beschworen wird.",

        -- Freie Gegenstandsplätze
        ITEM_HEADER_TITLE = "Freie Gegenstandsplätze",
        ITEM_SLOT_1_LABEL = "Gegenstand 1",
        ITEM_SLOT_2_LABEL = "Gegenstand 2",
        ITEM_DROP_HINT = "Gegenstand hier ablegen",
        ITEM_DESIGN_HINT = "Gegenstände aus Taschen oder Ausrüstung per Drag & Drop ablegen. Rechtsklick zum Entfernen.",
        EQUIP_SLOT_LABEL = "Ausrüstungsslot %d",
        TOOLTIP_ITEM_RIGHT_CLICK = "Rechtsklick: Gegenstand entfernen",

        -- Begleiter-Befehle
        PET_ACTION_LABEL = "Begleiterbefehl:",
        PET_CMD_NONE = "Keine Begleiteraktion",
        PET_CMD_ATTACK = "Angreifen (/petattack)",
        PET_CMD_FOLLOW = "Folgen (/petfollow)",
        PET_CMD_PASSIVE = "Passiv (/petpassive)",
        PET_CMD_DEFENSIVE = "Defensiv (/petdefensive)",

        -- Makro-Vorschau Tab
        PREVIEW_TAB_TITLE = "Integrierte Makro-Vorschau",
        PREVIEW_MODE_CURRENT = "Aktuelles Makro (Slot %d)",
        PREVIEW_MODE_ALL = "Alle 14 Makros",
        BTN_COPY_TEXT = "Text kopieren",
        PREVIEW_CHARS = "Zeichenanzahl: %d / %d",
        PREVIEW_WARN_LIMIT = "Achtung: Das Makro überschreitet das Limit von %d Zeichen! Bitte kürzen.",
        PREVIEW_OK = "Makro liegt vollständig innerhalb des Limits.",
        PREVIEW_ORDER_INFO = "Reihenfolge: #showtooltip -> Aktionen (Vor) -> Zaubergruppen -> Aktionen (Nach)",
        PREVIEW_COPY_HINT = "Hinweis: 'Text kopieren' markiert den gesamten Inhalt zum Kopieren mit Strg+C.",
        PREVIEW_ALL_HEADER = "--- DinoMacro Übersicht (Alle 14 Makros) ---",
        PREVIEW_ALL_NOTE = "Hinweis: Diese Textübersicht dient als lesbare Sicherung der generierten Makrobefehle.",

        -- Dialoge & Bestätigungen
        CONFIRM_CLEAR_MSG = "Slot %d wirklich leeren? Alle Zauber und Einstellungen werden zurückgesetzt.",
        BTN_YES = "Ja",
        BTN_NO = "Nein",
    },

    enUS = {
        -- General & Titles
        ADDON_NAME = "DinoMacro",
        ADDON_TITLE = "DinoMacro 1.4.17",
        SLASH_HINT = "DinoMacro opened. Command: /dinomacro or /dm",
        LANG_SWITCH = "Language: DE | EN",
        LANG_NAME = "English",

        -- Main Window & Slots
        HEADER_SLOTS = "14 Macro Slots",
        TOOLTIP_SLOT = "Slot %d",
        TOOLTIP_EMPTY = "Empty",
        TOOLTIP_SELECT = "Click to select",
        TOOLTIP_NEXT_STEP = "Next step: %s",
        TOOLTIP_ACTIONBAR = "Drag onto action bar",
        BTN_ACTIONBAR = "Drag to Bar",
        BTN_SAVE = "Save",
        BTN_CLEAR = "Clear",
        BTN_CLOSE = "Close",
        BTN_SETTINGS = "Settings",
        SETTINGS_TITLE = "DinoMacro - Settings",
        SETTING_COOLDOWN_NUMBERS = "Show Cooldown as numbers",
        SETTING_COOLDOWN_DESC = "Displays remaining cooldown time as a numeric countdown on DinoMacro icons. (Action bars use native Blizzard display).",
        SETTING_RESOURCE_COLOR = "Show missing resource in blue",
        SETTING_RESOURCE_DESC = "Tints DinoMacro icons blue when lacking mana, rage, energy, or focus. (Action bars use native mana dimming).",
        SETTING_RANGE_COLOR = "Show out of range in red",
        SETTING_RANGE_DESC = "Tints DinoMacro icons red when target is out of range. (Action bars use native range dot via #showtooltip).",
        SETTING_ACTIONBAR_NOTE = "Note: Blizzard action bars are protected and use native #showtooltip logic for range and cooldowns.",
        STATUS_DEFAULT = "Ready. Select a slot and configure actions.",
        STATUS_SAVED = "Slot %d successfully saved!",
        STATUS_CLEARED = "Slot %d cleared.",
        LABEL_NAME = "Macro Name*:",

        -- Tabs
        TAB_EDITOR = "Chain & Actions",
        TAB_PREVIEW = "Macro Preview",
        TAB_SETTINGS = "Settings",
        SETTING_SEC_TITLE = "Status Indicators & Display Options",
        ERR_COMBAT_LOCKDOWN = "Cannot create or drag macros to action bar during combat.",
        DEBUG_ENABLED = "DinoMacro debug mode enabled.",
        DEBUG_DISABLED = "DinoMacro debug mode disabled.",

        -- Editor & Sequence
        EDITOR_TITLE = "Macro Editor for Slot %d",
        RESET_TIME_LABEL = "Time Reset (sec): 0 = off",
        RESET_TARGET_CHECK = "Reset on Target Switch",
        AUTHOR_SIGNATURE = "by X4rinia",
        CHAT_LOAD_MSG = "DinoMacro 1.4.17 by X4rinia – /dm",
        MOUSEOVER_CHECK = "Enable Mouseover",
        MOUSEOVER_HARM = "Hostile",
        MOUSEOVER_HELP = "Friendly",
        TOOLTIP_MOUSEOVER_TITLE = "Mouseover Mode",
        TOOLTIP_MOUSEOVER_HARM_DESC = "Casts on hostile mouseover targets ([@mouseover,harm,nodead]). Falls back to normal target if no mouseover.",
        TOOLTIP_MOUSEOVER_HELP_DESC = "Casts on friendly mouseover targets ([@mouseover,help,nodead]). Falls back to normal target if no mouseover.",
        TOOLTIP_MOUSEOVER_CLICK_HINT = "Click to toggle (Friendly <-> Hostile)",
        MOUSEOVER_COMBINED = "Combined",
        MOUSEOVER_EXACT = "Priority: [@mouseover,exists,nodead]",
        SEC_SPELLS_TITLE = "Spell Sequence (Exactly 4 Spell Steps)",
        SPELL_EMPTY = "Empty - Drag spell here",
        SPELL_DROP_HINT = "Drop from spellbook",
        COND_ALWAYS = "Always",
        COND_COMBAT = "In Combat",
        COND_NOCOMBAT = "No Combat",
        FORM_NONE = "Any Stance",
        FORM_HUMANOID = "Normal Form (No Stance)",
        FORM_PREFIX_ONLY = "Only:",
        FORM_PREFIX_NOT = "Not:",
        STATUS_NO_FORMS_AVAILABLE = "No supported forms or stances are available for your class.",
        TOOLTIP_FORM_TITLE = "Stance / Form Condition",
        TOOLTIP_FORM_DESC = "Checks the character's current stance or form on execution.",
        GROUPING_INFO = "Automatic combat grouping: active",
        UNKNOWN_SPELL = "Unknown Spell",

        -- Editor Status Messages
        STATUS_NAME_REQUIRED = "Please enter a macro name.",
        STATUS_ACTION_REQUIRED_TO_DRAG = "At least one action is required to drag the macro to the action bar.",
        STATUS_DRAFT_SAVED = "Macro saved as draft (at least one action required for execution).",
        STATUS_STEP_CLEARED = "Step removed.",
        STATUS_STEP_REMOVED = "Step removed.",
        STATUS_CURSOR_NOT_AVAILABLE = "GetCursorInfo not available.",
        STATUS_DROP_PLAYER_SPELL = "Please drop a player spell from your spellbook.",
        STATUS_PET_SPELLS_NOT_SUPPORTED = "Pet spellbook is not supported in the top spell fields.",
        STATUS_SPELL_NOT_READ = "Could not read dropped spell.",
        STATUS_PASSIVE_SPELL_WARN = "Passive spells cannot be triggered.",
        STATUS_SPELL_RECEIVED = "%s placed.",
        STATUS_STEP_RANGE_ERR = "A sequence requires at least 1 step or additional action.",
        STATUS_STEP_UNAVAILABLE = "Step %d is not available.",
        STATUS_RESET_RANGE_ERR = "Reset timer must be between 0 and 3600 seconds.",
        STATUS_MACRO_TOO_LONG = "Macro text too long (%d/255 chars). Please shorten.",
        STATUS_SLOT_CLEARED = "The slot was cleared.",
        STATUS_SAVE_FIRST_WARN = "Please save the sequence first!",
        STATUS_COMBAT_SAVE_NOTICE = "In combat: changes will apply after combat.",
        STATUS_NO_MACRO_SLOT = "No free character-specific macro slot.",
        STATUS_MACRO_ON_CURSOR = "%s is on cursor: drop onto action bar.",
        STATUS_ITEM_ONLY = "Only items can be placed here.",
        STATUS_ITEM_CLEARED = "Item removed.",
        STATUS_ITEM_RECEIVED = "%s placed.",
        STATUS_TEXT_COPIED = "Text selected. Press Ctrl+C to copy to clipboard.",

        -- Additional Actions
        SEC_ACTIONS_TITLE = "Additional Actions",
        ACTION_POS_BEFORE = "Before Seq",
        ACTION_POS_AFTER = "After Seq",
        TRINKET_1_LABEL = "Trinket 1 (13)",
        TRINKET_2_LABEL = "Trinket 2 (14)",
        TRINKET_NONE_EQUIPPED = "No trinket equipped",
        TRINKET_SLOT_13_DESC = "Triggers /use 13. Works even if equipped later.",
        TRINKET_SLOT_14_DESC = "Triggers /use 14. Works even if equipped later.",
        PET_ATTACK_LABEL = "Pet Attack",
        PET_ATTACK_DESC = "Triggers /petattack [harm,nodead]. Works even if pet is summoned later.",

        -- Free Item Slots
        ITEM_HEADER_TITLE = "Free Item Slots",
        ITEM_SLOT_1_LABEL = "Item 1",
        ITEM_SLOT_2_LABEL = "Item 2",
        ITEM_DROP_HINT = "Drop item here",
        ITEM_DESIGN_HINT = "Drag & drop items from bags or character sheet. Right-click to remove.",
        EQUIP_SLOT_LABEL = "Equipment Slot %d",
        TOOLTIP_ITEM_RIGHT_CLICK = "Right-click: Remove item",

        -- Pet Commands
        PET_ACTION_LABEL = "Pet Command:",
        PET_CMD_NONE = "No Pet Action",
        PET_CMD_ATTACK = "Attack (/petattack)",
        PET_CMD_FOLLOW = "Follow (/petfollow)",
        PET_CMD_PASSIVE = "Passive (/petpassive)",
        PET_CMD_DEFENSIVE = "Defensive (/petdefensive)",

        -- Macro Preview Tab
        PREVIEW_TAB_TITLE = "Integrated Macro Preview",
        PREVIEW_MODE_CURRENT = "Current Macro (Slot %d)",
        PREVIEW_MODE_ALL = "All 14 Macros",
        BTN_COPY_TEXT = "Copy Text",
        PREVIEW_CHARS = "Character Count: %d / %d",
        PREVIEW_WARN_LIMIT = "Warning: Macro exceeds the %d character limit! Please shorten.",
        PREVIEW_OK = "Macro is completely within the character limit.",
        PREVIEW_ORDER_INFO = "Order: #showtooltip -> Actions (Before) -> Spell Groups -> Actions (After)",
        PREVIEW_COPY_HINT = "Note: 'Copy Text' selects all text for copying with Ctrl+C.",
        PREVIEW_ALL_HEADER = "--- DinoMacro Overview (All 14 Macros) ---",
        PREVIEW_ALL_NOTE = "Note: This text overview serves as a readable backup of the generated macro commands.",

        -- Dialogs & Confirmations
        CONFIRM_CLEAR_MSG = "Clear Slot %d? All spells and settings will be reset.",
        BTN_YES = "Yes",
        BTN_NO = "No",
    }
};

function DM.L(key, ...)
    local loc = (DinoMacroDB and DinoMacroDB.locale) or DM.currentLocale or "enUS";
    local dict = DM.Locales[loc] or DM.Locales["enUS"];
    local str = dict[key] or DM.Locales["enUS"][key] or key;
    if ... ~= nil then
        local ok, formatted = pcall(string.format, str, ...);
        if ok and formatted then
            return formatted;
        end
    end
    return str;
end
