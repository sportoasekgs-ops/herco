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
    
    -- Method 1: Try GUISettingsGet (recommended)
    if hr.GUISettingsGet then
        HHP.Debug("Using GUISettingsGet method")
        local settings = hr.GUISettingsGet("APL", "Paladin", "Holy")
        if settings then
            HHP.Debug("Settings retrieved via GUISettingsGet")
            return settings
        end
    else
        HHP.Debug("GUISettingsGet not available")
    end
    
    -- Method 2: Direct access to HeroLibDB.GUISettings (most common)
    if _G.HeroLibDB and _G.HeroLibDB.GUISettings then
        HHP.Debug("Trying HeroLibDB.GUISettings")
        local guiSettings = _G.HeroLibDB.GUISettings
        
        if guiSettings.APL and guiSettings.APL.Paladin and guiSettings.APL.Paladin.Holy then
            HHP.Debug("Holy Paladin settings found in HeroLibDB!")
            return guiSettings.APL.Paladin.Holy
        else
            HHP.Debug("APL.Paladin.Holy path not found in HeroLibDB")
            if guiSettings.APL then
                HHP.Debug("APL exists, checking classes...")
                for className, _ in pairs(guiSettings.APL) do
                    HHP.Debug("  Found class: " .. tostring(className))
                end
            end
        end
    else
        HHP.Debug("HeroLibDB or HeroLibDB.GUISettings not available")
        HHP.Debug("HeroLibDB exists: " .. tostring(_G.HeroLibDB ~= nil))
    end
    
    -- Method 3: Try GetSavedVariables
    if hr.GetSavedVariables and type(hr.GetSavedVariables) == "function" then
        HHP.Debug("Trying GetSavedVariables")
        local hrDB = hr:GetSavedVariables()
        if hrDB and hrDB.APL and hrDB.APL.Paladin and hrDB.APL.Paladin.Holy then
            HHP.Debug("Settings found via GetSavedVariables")
            return hrDB.APL.Paladin.Holy
        else
            HHP.Debug("GetSavedVariables didn't return expected structure")
        end
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
        
        -- Auto-load last profile after all addons loaded their defaults
        if HHP.Initialized and HeroHolyProfilesDB and HeroHolyProfilesDB.settings then
            if HeroHolyProfilesDB.settings.autoLoad and HeroHolyProfilesDB.settings.lastProfile then
                local profileName = HeroHolyProfilesDB.settings.lastProfile
                HHP.Print("|cFFFFAA00⏱ Auto-Loading:|r Profil '" .. profileName .. "' wird in 10 Sekunden geladen...")
                HHP.Print("|cFF888888(Wartet bis HeroRotation fertig geladen ist)|r")
                HHP.Debug("Auto-load triggered for profile: " .. profileName)
                HHP.LoadProfileDelayed(profileName)
            else
                HHP.Debug("Auto-load not triggered: autoLoad=" .. tostring(HeroHolyProfilesDB.settings.autoLoad) .. ", lastProfile=" .. tostring(HeroHolyProfilesDB.settings.lastProfile))
            end
        else
            HHP.Debug("Auto-load check skipped - addon not fully initialized")
        end
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
        HHP.Print("/hhp inspect - Zeigt HeroRotation Methoden")
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
    elseif cmd == "inspect" then
        HHP.InspectHeroRotation()
    else
        HHP.Print("Unbekannter Befehl. Nutze /hhp help für Hilfe.")
    end
end

_G["HeroHolyProfiles"] = HHP
