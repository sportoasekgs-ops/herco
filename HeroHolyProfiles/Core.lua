local addonName, HHP = ...

HHP.Version = "1.0.0"
HHP.Initialized = false
HHP.HRSettingsReady = false
HHP.CheckTimer = 0

local frame = CreateFrame("Frame")

function HHP.Print(msg)
    print("|cFFFFD700[HeroHolyProfiles]|r " .. tostring(msg))
end

function HHP.Debug(msg)
    if HHP.DebugMode then
        HHP.Print("|cFF00FF00[DEBUG]|r " .. tostring(msg))
    end
end

function HHP.CheckHolySettings()
    HHP.Debug("Checking for HeroRotation Holy settings...")
    
    if not HeroRotation then
        HHP.Debug("HeroRotation addon not loaded")
        return false
    end
    
    local settings = HHP.GetHolySettings()
    if settings then
        HHP.Debug("Paladin Holy settings found!")
        HHP.HRSettingsReady = true
        HHP.CurrentSettings = settings
        return true
    end
    
    HHP.Debug("Paladin Holy settings not found yet")
    return false
end

function HHP.GetHolySettings()
    if not HeroRotation then
        return nil
    end
    
    local hr = HeroRotation()
    if not hr then
        HHP.Debug("HeroRotation() returned nil")
        return nil
    end
    
    if hr.GUISettingsGet then
        HHP.Debug("Using GUISettingsGet method")
        local settings = hr.GUISettingsGet("APL", "Paladin", "Holy")
        if settings then
            return settings
        end
    else
        HHP.Debug("GUISettingsGet not available, trying direct DB access")
    end
    
    if HeroRotationDB and HeroRotationDB.ProfileSelected then
        local profileName = HeroRotationDB.ProfileSelected
        HHP.Debug("Selected profile: " .. tostring(profileName))
        
        if HeroRotationDB.Profiles and HeroRotationDB.Profiles[profileName] then
            local profile = HeroRotationDB.Profiles[profileName]
            HHP.Debug("Profile found in DB")
            
            if profile.APL and profile.APL.Paladin and profile.APL.Paladin.Holy then
                HHP.Debug("Holy Paladin settings found in profile!")
                return profile.APL.Paladin.Holy
            else
                HHP.Debug("Holy Paladin path not found in profile")
            end
        else
            HHP.Debug("Profile not found in DB")
        end
    else
        HHP.Debug("HeroRotationDB or ProfileSelected not available")
    end
    
    return nil
end

function HHP.OnUpdate(self, elapsed)
    HHP.CheckTimer = HHP.CheckTimer + elapsed
    
    if HHP.CheckTimer >= 2 then
        HHP.CheckTimer = 0
        
        if not HHP.HRSettingsReady then
            if HHP.CheckHolySettings() then
                HHP.Print("|cFF00FF00Erfolgreich!|r HeroRotation Holy Settings gefunden!")
            end
        end
    end
end

frame:SetScript("OnUpdate", HHP.OnUpdate)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        HHP.Debug("HeroHolyProfiles loaded")
        
        if not HeroHolyProfilesDB then
            HeroHolyProfilesDB = {}
        end
        
        if not HeroHolyProfilesDB.profiles then
            HeroHolyProfilesDB.profiles = {}
        end
        
        if not HeroHolyProfilesDB.settings then
            HeroHolyProfilesDB.settings = {
                debugMode = false,
                lastProfile = nil
            }
        end
        
        HHP.DebugMode = HeroHolyProfilesDB.settings.debugMode or false
        
        HHP.Initialized = true
        HHP.Print("Version " .. HHP.Version .. " geladen. Nutze /hhp für Befehle.")
    end
    
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HHP.CheckHolySettings()
    end
end)

SLASH_HEROHOLYPROFILES1 = "/hhp"
SLASH_HEROHOLYPROFILES2 = "/heroholyprofiles"

SlashCmdList["HEROHOLYPROFILES"] = function(msg)
    local cmd = strtrim(msg or ""):lower()
    
    if cmd == "" or cmd == "help" then
        HHP.Print("Befehle:")
        HHP.Print("/hhp gui - Öffnet die Profilverwaltung")
        HHP.Print("/hhp check - Prüft HeroRotation Settings")
        HHP.Print("/hhp debug - Schaltet Debug-Modus um")
        HHP.Print("/hhp save <name> - Speichert aktuelles Profil")
        HHP.Print("/hhp load <name> - Lädt ein Profil")
        HHP.Print("/hhp list - Zeigt alle Profile")
    elseif cmd == "gui" then
        HHP.ToggleGUI()
    elseif cmd == "check" then
        if HHP.CheckHolySettings() then
            HHP.Print("|cFF00FF00✓|r HeroRotation Holy Settings verfügbar!")
            local settings = HHP.GetHolySettings()
            if settings then
                HHP.Print("Settings gefunden. Nutze /hhp gui zum Speichern.")
            end
        else
            HHP.Print("|cFFFF0000✗|r HeroRotation Holy Settings noch nicht verfügbar.")
            HHP.Print("Tipp: Öffne das HeroRotation GUI mindestens einmal.")
        end
    elseif cmd == "debug" then
        HHP.DebugMode = not HHP.DebugMode
        HeroHolyProfilesDB.settings.debugMode = HHP.DebugMode
        HHP.Print("Debug-Modus: " .. (HHP.DebugMode and "|cFF00FF00AN|r" or "|cFFFF0000AUS|r"))
    elseif cmd:match("^save ") then
        local profileName = cmd:match("^save (.+)")
        HHP.SaveProfile(profileName)
    elseif cmd:match("^load ") then
        local profileName = cmd:match("^load (.+)")
        HHP.LoadProfile(profileName)
    elseif cmd == "list" then
        HHP.ListProfiles()
    else
        HHP.Print("Unbekannter Befehl. Nutze /hhp help für Hilfe.")
    end
end

_G["HeroHolyProfiles"] = HHP
