# DinoMacro

**Created by X4rinia**

DinoMacro ist ein vielseitiger und kompakter Makro- und Zauberketten-Manager für World of Warcraft (WoW Forever, Classic 1.12 bis neuere Clients).

---

## 📦 Installation

### 1. Über WoWUp (Empfohlen für automatische Updates)
1. Öffne die **WoWUp**-App.
2. Gehe auf den Reiter **Addons suchen** oder **Aus URL installieren** (*Install from URL*).
3. Gib die GitHub-Repository-URL ein:
   ```text
   https://github.com/x4rinia/DinoMacro
   ```
4. Klicke auf **Importieren / Installieren**. WoWUp erkennt automatisch die neuesten Releases und hält das Addon aktuell.

### 2. Manuelle Installation
1. Lade die neueste `DinoMacro-vX.X.X.zip` aus den [GitHub Releases](https://github.com/x4rinia/DinoMacro/releases) herunter.
2. Entpacke das Archiv in dein WoW-Addon-Verzeichnis:
   ```text
   World of Warcraft/_retail_/Interface/AddOns/
   World of Warcraft/_classic_/Interface/AddOns/
   World of Warcraft/Interface/AddOns/ (1.12 / Forever)
   ```
3. Stelle sicher, dass der Ordner direkt `DinoMacro` heißt und die Datei `DinoMacro.toc` enthält.
4. Starte World of Warcraft neu oder führe `/reload` im Spiel aus.

---

## 🎮 Befehle im Spiel

| Befehl | Beschreibung |
|---|---|
| `/dinomacro` oder `/dm` | Öffnet das Hauptfenster von DinoMacro |
| `/dm debug` | Aktiviert oder deaktiviert den Debug-Modus |
| `/dm reset` | Setzt Fensterpositionen und Einstellungen zurück |

---

## ✨ Features

- **14 konfigurierbare Makro-Slots** mit intuitiver Oberfläche.
- **In-Place Bearbeitung:** Saubere Aktualisierung bestehender Makros im Blizzard-Makrobuch ohne Duplikate.
- **Blizzlike Sequenz-Icons:** Automatische Vorschau für den nächsten Zauber (`#showtooltip` / `?`) inklusive Cooldowns und Tooltips.
- **Intelligente Zauberketten:** Unterstützung für Zeitreset (`reset=X`), Zielwechsel-Reset (`reset=target`), Mouseover (`[@mouseover,exists,nodead]`), Begleiterangriff (`/petattack`) und Schmuckstücke (`/use 13`, `/use 14`).
- **Drag & Drop:** Zauber und Gegenstände können direkt aus dem Zauberbuch oder Inventar in die Slots gezogen werden.
- **Mehrsprachig:** Automatische Zauber- und Gegenstandsauflösung für deutsche und englische Clients.
- **Automatische Duplikat-Bereinigung:** Entfernt verwaiste Makro-Duplikate früherer Versionen automatisch beim Speichern.

---

## 📝 Changelog

### Version 1.4.17
- **In-Place Makrobearbeitung ohne Duplikate:**
  - Beim Speichern wird das bestehende Makro im Blizzard-Makrobuch gezielt mit `EditMacro` in-place aktualisiert. Es werden keine doppelten Makros mehr im Makrofenster erzeugt.
  - **Automatische Duplikat-Bereinigung (`DM.CleanupDuplicateMacros`):** Sollten aus früheren Versionen noch Makroduplikate mit altem oder gleichem Namen im Spiel existieren, werden diese beim Speichern automatisch aufgeräumt, sodass genau ein Makro pro Slot existiert.
- **Exakter Makroname beim Ziehen in die Leiste:**
  - Der vom Benutzer im Feld „Makroname“ eingegebene Name (z. B. `X-start`) wird direkt als nativer Makroname verwendet (bis maximal 16 Zeichen nach Blizzard-Standard).
  - Beim Klick auf „In Leiste ziehen“ wird das Makro unter diesem exakten Namen auf den Cursor gelegt.
  - Auch wenn der Name nachträglich im Editor geändert wird, benennt DinoMacro das Makro direkt um – Aktionen auf der Aktionsleiste bleiben erhalten.
- **Saubere Neugenerierung des Makrotextes:**
  - Beim Klick auf „Speichern“ wird der Makrotext vollständig frisch und sauber aus den aktuell angeklickten Optionen generiert (aktive Zauber, Mouseover, Zeitreset, Zielwechsel-Reset, Begleiterangriff, Schmuckstücke, Gegenstände).
  - Keine doppelten Zeilen oder versehentlich wiederholte Zauber im Makrotext.
- **Mehrsprachigkeit & Englischer Client-Support (aus 1.4.16):**
  - Auf englischen Clients (`GetLocale() ~= "deDE"`) oder bei Einstellung auf Englisch werden Zaubernamen und Gegenstände automatisch in die korrekte englische Bezeichnung übersetzt (`DM.ResolveSpell` / `DM.SPELL_NAME_TO_ID`).
- **Blizzlike Sequenz-Icons (aus 1.4.15):**
  - Makros nutzen `INV_MISC_QUESTIONMARK` (`?`) und `#showtooltip`, wodurch Blizzard auf der Aktionsleiste automatisch zum nächsten Zauber (Icon, Tooltip, Cooldown) weiterschaltet, sobald der vorherige Zauber gewirkt wurde.
