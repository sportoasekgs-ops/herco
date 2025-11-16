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

function HHP.InspectHeroRotation()
    if not HeroRotation or not HeroRotation() then
        HHP.Print("HeroRotation not available")
        return
    end
    
    local hr = HeroRotation()
    HHP.Print("=== HeroRotation Methods ===")
    
    local methods = {}
    for key, value in pairs(hr) do
        if type(value) == "function" then
            table.insert(methods, key)
        end
    end
    table.sort(methods)
    
    for _, method in ipairs(methods) do
        HHP.Print("  " .. method)
    end
    
    HHP.Print("=== Looking for Settings-related ===")
    for key, value in pairs(hr) do
        local keyLower = string.lower(tostring(key))
        if string.find(keyLower, "setting") or string.find(keyLower, "option") or string.find(keyLower, "config") then
            HHP.Print("  " .. key .. " = " .. type(value))
        end
    end
    
    HHP.Print("=== Testing GetSavedVariables ===")
    if hr.GetSavedVariables then
        local result = hr:GetSavedVariables()
        HHP.Print("Result type: " .. type(result))
        if result then
            HHP.Print("Keys in result:")
            for k, v in pairs(result) do
                HHP.Print("  " .. tostring(k) .. " = " .. type(v))
            end
        else
            HHP.Print("GetSavedVariables returned nil")
        end
    end
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
    
    if not HeroRotation or not HeroRotation() then
        HHP.Print("|cFFFF0000Fehler:|r HeroRotation nicht verfügbar!")
        return false
    end
    
    local hr = HeroRotation()
    local loadedCount = 0
    local failedCount = 0
    
    if hr.GetSavedVariables and type(hr.GetSavedVariables) == "function" then
        HHP.Debug("Using GetSavedVariables to access HeroRotation DB")
        
        local hrDB = hr:GetSavedVariables()
        HHP.Debug("GetSavedVariables returned: " .. tostring(hrDB))
        HHP.Debug("Type: " .. type(hrDB))
        
        if hrDB then
            HHP.Debug("hrDB.ProfileSelected: " .. tostring(hrDB.ProfileSelected))
            HHP.Debug("hrDB.Profiles: " .. tostring(hrDB.Profiles))
            
            HHP.Print("=== hrDB keys ===")
            for k, v in pairs(hrDB) do
                HHP.Print("  " .. tostring(k) .. " = " .. type(v))
            end
        end
        
        if hrDB and hrDB.ProfileSelected then
            local selectedProfile = hrDB.ProfileSelected
            HHP.Debug("Current HeroRotation profile: " .. tostring(selectedProfile))
            
            if hrDB.Profiles and hrDB.Profiles[selectedProfile] then
                local hrProfile = hrDB.Profiles[selectedProfile]
                
                if not hrProfile.APL then hrProfile.APL = {} end
                if not hrProfile.APL.Paladin then hrProfile.APL.Paladin = {} end
                if not hrProfile.APL.Paladin.Holy then hrProfile.APL.Paladin.Holy = {} end
                
                for key, value in pairs(profile.thresholds) do
                    if not hrProfile.APL.Paladin.Holy[key] then
                        hrProfile.APL.Paladin.Holy[key] = {}
                    end
                    
                    if type(hrProfile.APL.Paladin.Holy[key]) == "table" then
                        hrProfile.APL.Paladin.Holy[key].value = value
                        loadedCount = loadedCount + 1
                        HHP.Debug("Geladen: " .. key .. " = " .. tostring(value))
                    else
                        hrProfile.APL.Paladin.Holy[key] = value
                        loadedCount = loadedCount + 1
                        HHP.Debug("Geladen (direct): " .. key .. " = " .. tostring(value))
                    end
                end
                
                HHP.Debug("Successfully modified HeroRotation database")
            else
                HHP.Print("|cFFFF0000Fehler:|r HeroRotation Profil '" .. tostring(selectedProfile) .. "' nicht gefunden!")
                return false
            end
        else
            HHP.Print("|cFFFF0000Fehler:|r GetSavedVariables gab keine gültigen Daten zurück")
            return false
        end
    elseif _G.HeroRotationDB and _G.HeroRotationDB.ProfileSelected then
        HHP.Debug("Using direct DB access via _G to load profile")
        local selectedProfile = _G.HeroRotationDB.ProfileSelected
        HHP.Debug("Current HeroRotation profile: " .. tostring(selectedProfile))
        
        if _G.HeroRotationDB.Profiles and _G.HeroRotationDB.Profiles[selectedProfile] then
            local hrProfile = _G.HeroRotationDB.Profiles[selectedProfile]
            
            if not hrProfile.APL then hrProfile.APL = {} end
            if not hrProfile.APL.Paladin then hrProfile.APL.Paladin = {} end
            if not hrProfile.APL.Paladin.Holy then hrProfile.APL.Paladin.Holy = {} end
            
            for key, value in pairs(profile.thresholds) do
                if not hrProfile.APL.Paladin.Holy[key] then
                    hrProfile.APL.Paladin.Holy[key] = {}
                end
                
                if type(hrProfile.APL.Paladin.Holy[key]) == "table" then
                    hrProfile.APL.Paladin.Holy[key].value = value
                    loadedCount = loadedCount + 1
                    HHP.Debug("Geladen (DB): " .. key .. " = " .. tostring(value))
                else
                    hrProfile.APL.Paladin.Holy[key] = value
                    loadedCount = loadedCount + 1
                    HHP.Debug("Geladen (direct): " .. key .. " = " .. tostring(value))
                end
            end
            
            if hr.GUI and type(hr.GUI.Refresh) == "function" then
                HHP.Debug("Calling HeroRotation GUI Refresh")
                pcall(function() hr.GUI:Refresh() end)
            end
            
            if hr.GUIRefresh and type(hr.GUIRefresh) == "function" then
                HHP.Debug("Calling HeroRotation GUIRefresh")
                pcall(function() hr:GUIRefresh() end)
            end
        else
            HHP.Print("|cFFFF0000Fehler:|r HeroRotation Profil '" .. tostring(selectedProfile) .. "' nicht gefunden!")
            HHP.Debug("Available profiles: " .. table.concat(HHP.GetTableKeys(_G.HeroRotationDB.Profiles or {}), ", "))
            return false
        end
    else
        HHP.Print("|cFFFF0000Fehler:|r Keine Methode zum Laden verfügbar!")
        HHP.Print("HeroRotation: " .. tostring(HeroRotation ~= nil))
        HHP.Print("HeroRotation(): " .. tostring(HeroRotation and HeroRotation() ~= nil))
        HHP.Print("_G.HeroRotationDB: " .. tostring(_G.HeroRotationDB ~= nil))
        if _G.HeroRotationDB then
            HHP.Print("ProfileSelected: " .. tostring(_G.HeroRotationDB.ProfileSelected))
            HHP.Print("Profiles: " .. tostring(_G.HeroRotationDB.Profiles ~= nil))
        end
        return false
    end
    
    HeroHolyProfilesDB.settings.lastProfile = profileName
    
    if failedCount > 0 then
        HHP.Print("|cFFFFAA00Profil teilweise geladen:|r " .. profileName .. " (" .. loadedCount .. " erfolgreich, " .. failedCount .. " fehlgeschlagen)")
    else
        HHP.Print("|cFF00FF00Profil geladen:|r " .. profileName .. " (" .. loadedCount .. " Werte)")
        HHP.Print("|cFFFFAA00Hinweis:|r Öffne das HeroRotation GUI um die Änderungen zu sehen, oder gib /reload ein")
    end
    
    return true
end

function HHP.GetTableKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
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
