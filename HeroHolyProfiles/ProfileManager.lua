local addonName, HHP = ...

function HHP.GetCurrentThresholds()
    local settings = HHP.GetHolySettings()
    if not settings then
        return nil
    end
    
    local thresholds = {}
    
    for key, value in pairs(settings) do
        if type(value) == "table" and value.value ~= nil then
            thresholds[key] = value.value
        end
    end
    
    return thresholds
end

function HHP.SaveProfile(profileName)
    if not profileName or profileName == "" then
        HHP.Print("|cFFFF0000Fehler:|r Profilname erforderlich!")
        return false
    end
    
    local thresholds = HHP.GetCurrentThresholds()
    if not thresholds then
        HHP.Print("|cFFFF0000Fehler:|r HeroRotation Settings nicht verfügbar!")
        HHP.Print("Tipp: Öffne das HeroRotation GUI mindestens einmal.")
        return false
    end
    
    HeroHolyProfilesDB.profiles[profileName] = {
        thresholds = thresholds,
        timestamp = time(),
        version = HHP.Version
    }
    
    HHP.Print("|cFF00FF00Profil gespeichert:|r " .. profileName)
    HHP.Debug("Gespeicherte Werte: " .. HHP.TableToString(thresholds))
    
    return true
end

function HHP.LoadProfile(profileName)
    if not profileName or profileName == "" then
        HHP.Print("|cFFFF0000Fehler:|r Profilname erforderlich!")
        return false
    end
    
    local profile = HeroHolyProfilesDB.profiles[profileName]
    if not profile then
        HHP.Print("|cFFFF0000Fehler:|r Profil '" .. profileName .. "' nicht gefunden!")
        return false
    end
    
    if not HeroRotation or not HeroRotation() or not HeroRotation().GUISettingsGet then
        HHP.Print("|cFFFF0000Fehler:|r HeroRotation Settings nicht verfügbar!")
        return false
    end
    
    local settings = HeroRotation().GUISettingsGet("APL", "Paladin", "Holy")
    if not settings then
        HHP.Print("|cFFFF0000Fehler:|r Paladin Holy Settings nicht gefunden!")
        return false
    end
    
    local loadedCount = 0
    for key, value in pairs(profile.thresholds) do
        if settings[key] and type(settings[key]) == "table" then
            settings[key].value = value
            loadedCount = loadedCount + 1
            HHP.Debug("Geladen: " .. key .. " = " .. tostring(value))
        end
    end
    
    HeroHolyProfilesDB.settings.lastProfile = profileName
    
    HHP.Print("|cFF00FF00Profil geladen:|r " .. profileName .. " (" .. loadedCount .. " Werte)")
    
    return true
end

function HHP.DeleteProfile(profileName)
    if not profileName or profileName == "" then
        return false
    end
    
    if not HeroHolyProfilesDB.profiles[profileName] then
        HHP.Print("|cFFFF0000Fehler:|r Profil '" .. profileName .. "' nicht gefunden!")
        return false
    end
    
    HeroHolyProfilesDB.profiles[profileName] = nil
    HHP.Print("|cFF00FF00Profil gelöscht:|r " .. profileName)
    
    return true
end

function HHP.ListProfiles()
    local count = 0
    HHP.Print("Gespeicherte Profile:")
    
    for profileName, profile in pairs(HeroHolyProfilesDB.profiles) do
        count = count + 1
        local date = date("%d.%m.%Y %H:%M", profile.timestamp)
        HHP.Print("  |cFFFFD700" .. profileName .. "|r - " .. date)
    end
    
    if count == 0 then
        HHP.Print("  |cFF888888Keine Profile gespeichert.|r")
    end
end

function HHP.TableToString(tbl, indent)
    indent = indent or 0
    local str = ""
    local spaces = string.rep("  ", indent)
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            str = str .. spaces .. tostring(k) .. " = {\n"
            str = str .. HHP.TableToString(v, indent + 1)
            str = str .. spaces .. "}\n"
        else
            str = str .. spaces .. tostring(k) .. " = " .. tostring(v) .. "\n"
        end
    end
    
    return str
end
