# HeroHolyProfiles

Ein World of Warcraft Addon zur Verwaltung von HeroRotation Holy Paladin Profilen.

## Features

- **Automatische Erkennung** der HeroRotation Holy Settings
- **Profile speichern** mit allen Healing/Special Healing Thresholds
- **Profile laden** für verschiedene Situationen (Raid, M+, etc.)
- **GUI-Interface** zur einfachen Verwaltung
- **Slash-Commands** für schnellen Zugriff

## Installation

1. Entpacke den Ordner `HeroHolyProfiles` in deinen WoW AddOns Ordner:
   - `World of Warcraft\_retail_\Interface\AddOns\`
2. Starte World of Warcraft neu
3. Aktiviere das Addon im AddOn-Menü

## Verwendung

### Befehle

- `/hhp` oder `/hhp help` - Zeigt alle Befehle
- `/hhp gui` - Öffnet die Profilverwaltung
- `/hhp check` - Prüft ob HeroRotation Settings verfügbar sind
- `/hhp save <name>` - Speichert aktuelles Profil
- `/hhp load <name>` - Lädt ein Profil
- `/hhp list` - Zeigt alle gespeicherten Profile
- `/hhp debug` - Schaltet Debug-Modus um

### GUI

Das GUI bietet:
- Übersicht aller gespeicherten Profile
- Laden von Profilen mit einem Klick
- Löschen von Profilen
- Status-Anzeige der HeroRotation Settings

## Wichtige Hinweise

⚠️ **WICHTIG**: Bevor du Profile speichern kannst:
1. **HeroRotation muss installiert sein**
2. **Öffne das HeroRotation GUI mindestens einmal** (z.B. mit `/hr` oder über das Interface-Addon-Menü)
3. Erst dann werden die Settings verfügbar und du kannst Profile speichern/laden

Zusätzliche Infos:
- Das Addon prüft alle 2 Sekunden automatisch, ob die Settings verfügbar sind
- Funktioniert unabhängig davon, ob die Rotation aktiv ist oder nicht
- Nach dem ersten Öffnen des HR GUI bleiben die Settings dauerhaft verfügbar

## Technische Details

Das Addon nutzt:
- `HeroRotation().GUISettingsGet("APL", "Paladin", "Holy")` zum Auslesen der Settings
- Automatische Hintergrund-Prüfung alle 2 Sekunden
- Persistente Speicherung in `HeroHolyProfilesDB`

## Version

1.0.0 - Erste Release-Version
