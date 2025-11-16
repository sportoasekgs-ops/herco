local addonName, HHP = ...

function HHP.GetCurrentThresholds()
    local settings = HHP.GetHolySettings()
    if not settings then
        return nil
    end
    
    local thresholds = {}
    
    -- Recursive function to extract all values
    local function extractValues(tbl, prefix)
        prefix = prefix or ""
        
        for key, value in pairs(tbl) do
            local fullKey = prefix ~= "" and (prefix .. "." .. key) or key
            
            if type(value) == "table" then
                -- Check if this table has a .value field
                if value.value ~= nil then
                    thresholds[fullKey] = value.value
                    HHP.Debug("Found setting: " .. fullKey .. " = " .. tostring(value.value))
                else
                    -- Recursively search deeper
                    extractValues(value, fullKey)
                end
            elseif type(value) == "number" or type(value) == "boolean" then
                -- Direct value
                thresholds[fullKey] = value
                HHP.Debug("Found setting: " .. fullKey .. " = " .. tostring(value))
            end
        end
    end
    
    extractValues(settings)
    
    HHP.Debug("Total settings extracted: " .. HHP.CountTableKeys(thresholds))
    
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

function HHP.ApplyThresholdsToHeroRotation(thresholds)
    if not HeroRotation or not HeroRotation() then
        return false, "HeroRotation nicht verfügbar"
    end
    
    local hr = HeroRotation()
    local loadedCount = 0
    local currentSettings = HHP.GetHolySettings()
    
    if not currentSettings then
        return false, "Konnte aktuelle Settings nicht abrufen"
    end
    
    HHP.Debug("=== Diagnosing HeroRotation access ===")
    HHP.Debug("_G.HeroLibDB exists: " .. tostring(_G.HeroLibDB ~= nil))
    if _G.HeroLibDB then
        HHP.Debug("HeroLibDB.GUISettings exists: " .. tostring(_G.HeroLibDB.GUISettings ~= nil))
    end
    HHP.Debug("hr.GetSavedVariables exists: " .. tostring(hr.GetSavedVariables ~= nil))
    
    -- Try method 1: Direct access via _G.HeroLibDB.GUISettings (most reliable)
    -- HeroLib uses DOT-NOTATION STRING KEYS, not nested tables!
    if _G.HeroLibDB and _G.HeroLibDB.GUISettings then
        local guiSettings = _G.HeroLibDB.GUISettings
        HHP.Debug("Loading into HeroLibDB.GUISettings using dot-notation keys")
        
        HHP.Debug("=== Profile has " .. HHP.CountTableKeys(thresholds) .. " keys ===")
        HHP.Debug("=== Current settings has " .. HHP.CountTableKeys(currentSettings) .. " keys ===")
        
        -- Log first few keys from profile and current settings
        local profileKeys = HHP.GetTableKeys(thresholds)
        local currentKeys = HHP.GetTableKeys(currentSettings)
        
        HHP.Debug("First 5 profile keys: " .. table.concat({unpack(profileKeys, 1, math.min(5, #profileKeys))}, ", "))
        HHP.Debug("First 5 current keys: " .. table.concat({unpack(currentKeys, 1, math.min(5, #currentKeys))}, ", "))
        
        -- Apply each threshold using dot-notation string keys
        for key, value in pairs(thresholds) do
            HHP.Debug("Loading key: " .. tostring(key) .. " = " .. tostring(value))
            
            -- 1. Write to HeroLibDB.GUISettings (saved variable)
            guiSettings[key] = value
            
            -- 2. Also update the runtime HL.GUISettings
            local keys = {}
            for k in string.gmatch(key, "[^.]+") do
                table.insert(keys, k)
            end
            
            -- Navigate and update HL.GUISettings runtime table
            if _G.HL and _G.HL.GUISettings then
                local runtimeSettings = _G.HL.GUISettings
                for i = 1, #keys - 1 do
                    if not runtimeSettings[keys[i]] then
                        runtimeSettings[keys[i]] = {}
                    end
                    runtimeSettings = runtimeSettings[keys[i]]
                end
                local finalKey = keys[#keys]
                runtimeSettings[finalKey] = value
                HHP.Debug("Updated HL.GUISettings runtime: " .. key)
            end
            
            loadedCount = loadedCount + 1
            HHP.Debug("Applied to GUISettings['" .. key .. "'] = " .. tostring(value))
        end
        
        -- Force HeroLib to reload settings from DB
        if _G.HL and _G.HL.GUI and _G.HL.GUI.LoadSettingsRecursively and _G.HL.GUISettings then
            HHP.Debug("Forcing HeroLib to reload all settings from DB...")
            _G.HL.GUI.LoadSettingsRecursively(_G.HL.GUISettings)
            HHP.Debug("HeroLib settings reloaded")
        end
        
        -- Try to refresh HeroRotation GUI if it's open
        HHP.RefreshHeroRotationGUI(hr)
        
        return true, loadedCount
    end
    
    -- Try method 2: GetSavedVariables (fallback)
    if hr.GetSavedVariables and type(hr.GetSavedVariables) == "function" then
        HHP.Debug("Using GetSavedVariables method")
        
        local hrDB = hr:GetSavedVariables()
        if hrDB and hrDB.APL and hrDB.APL.Paladin and hrDB.APL.Paladin.Holy then
            local holySettings = hrDB.APL.Paladin.Holy
            HHP.Debug("Loading into GetSavedVariables APL.Paladin.Holy")
            
            -- Apply each threshold
            for key, value in pairs(thresholds) do
                if currentSettings[key] then
                    if type(currentSettings[key]) == "table" then
                        if not holySettings[key] then
                            holySettings[key] = {}
                        end
                        
                        if type(holySettings[key]) == "table" then
                            holySettings[key].value = value
                        else
                            holySettings[key] = {value = value}
                        end
                    else
                        holySettings[key] = value
                    end
                    
                    loadedCount = loadedCount + 1
                    HHP.Debug("Geladen: " .. key .. " = " .. tostring(value))
                else
                    HHP.Debug("Warning: Key '" .. key .. "' not found, skipping")
                end
            end
            
            HHP.RefreshHeroRotationGUI(hr)
            
            return true, loadedCount
        else
            return false, "GetSavedVariables hat keine APL.Paladin.Holy Struktur"
        end
    end
    
    return false, "Keine Methode zum Laden verfügbar (HeroLibDB und GetSavedVariables fehlgeschlagen)"
end

function HHP.RefreshHeroRotationGUI(hr)
    -- Try multiple methods to refresh the HeroRotation GUI
    local refreshed = false
    
    -- Method 1: GUI.Refresh
    if hr.GUI and type(hr.GUI.Refresh) == "function" then
        HHP.Debug("Calling HeroRotation GUI.Refresh()")
        local success = pcall(function() hr.GUI:Refresh() end)
        if success then
            refreshed = true
            HHP.Debug("GUI.Refresh() successful")
        end
    end
    
    -- Method 2: GUIRefresh
    if hr.GUIRefresh and type(hr.GUIRefresh) == "function" then
        HHP.Debug("Calling HeroRotation GUIRefresh()")
        local success = pcall(function() hr:GUIRefresh() end)
        if success then
            refreshed = true
            HHP.Debug("GUIRefresh() successful")
        end
    end
    
    -- Method 3: UpdateGUI
    if hr.UpdateGUI and type(hr.UpdateGUI) == "function" then
        HHP.Debug("Calling HeroRotation UpdateGUI()")
        local success = pcall(function() hr:UpdateGUI() end)
        if success then
            refreshed = true
            HHP.Debug("UpdateGUI() successful")
        end
    end
    
    -- Method 4: Trigger events
    if hr.GUI and hr.GUI.MainFrame then
        HHP.Debug("Found GUI.MainFrame, triggering update")
        local frame = hr.GUI.MainFrame
        if frame.UpdatePanel and type(frame.UpdatePanel) == "function" then
            pcall(function() frame:UpdatePanel() end)
            refreshed = true
        end
    end
    
    if not refreshed then
        HHP.Debug("No GUI refresh method found or all failed")
    end
    
    return refreshed
end

function HHP.LoadProfileDelayed(profileName)
    -- Wait 10 seconds after PLAYER_ENTERING_WORLD to ensure HeroRotation finished loading
    C_Timer.After(10, function()
        HHP.Debug("Delayed profile load starting (10s delay)...")
        local success, result = HHP.ApplyThresholdsToHeroRotation(HeroHolyProfilesDB.profiles[profileName].thresholds)
        
        if success then
            HHP.Print("|cFF00FF00✓ Auto-Load erfolgreich:|r Profil '" .. profileName .. "' aktiv! (" .. result .. " Werte)")
            HHP.Print("|cFFFFAA00Info:|r Prüfe HeroRotation GUI um die Werte zu verifizieren")
        else
            HHP.Print("|cFFFF0000Auto-Load Fehler:|r " .. tostring(result))
        end
    end)
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
    
    -- Show diagnostic info first
    HHP.Print("|cFFFFAA00Diagnose:|r")
    HHP.Print("  _G.HeroLibDB: " .. tostring(_G.HeroLibDB ~= nil))
    if _G.HeroLibDB then
        HHP.Print("  HeroLibDB.GUISettings: " .. tostring(_G.HeroLibDB.GUISettings ~= nil))
        if _G.HeroLibDB.GUISettings and _G.HeroLibDB.GUISettings.APL then
            HHP.Print("  APL exists: true")
            if _G.HeroLibDB.GUISettings.APL.Paladin then
                HHP.Print("  Paladin exists: true")
                if _G.HeroLibDB.GUISettings.APL.Paladin.Holy then
                    HHP.Print("  Holy exists: true")
                end
            end
        end
    end
    
    local hr = HeroRotation and HeroRotation()
    if hr and hr.GetSavedVariables then
        local hrDB = hr:GetSavedVariables()
        HHP.Print("  GetSavedVariables: " .. tostring(hrDB ~= nil))
        if hrDB and hrDB.APL then
            HHP.Print("  GetSavedVariables.APL: true")
        end
    end
    
    -- Apply the thresholds
    local success, result = HHP.ApplyThresholdsToHeroRotation(profile.thresholds)
    
    if success then
        HeroHolyProfilesDB.settings.lastProfile = profileName
        HeroHolyProfilesDB.settings.autoLoad = true
        HHP.Print("|cFF00FF00Profil geladen:|r " .. profileName .. " (" .. result .. " Werte)")
        HHP.Print("|cFFFFAA00Wichtig:|r Gib |cFFFFFFFF/reload|r ein!")
        HHP.Print("|cFF00FF00Auto-Load aktiviert:|r Wird beim nächsten Login automatisch geladen")
        HHP.Debug("Set autoLoad=true, lastProfile=" .. profileName)
        return true
    else
        HHP.Print("|cFFFF0000Fehler beim Laden:|r " .. tostring(result))
        HHP.Print("|cFFFFAA00Tipp:|r Aktiviere Debug-Modus mit /hhp debug für mehr Infos")
        return false
    end
end

function HHP.GetTableKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

function HHP.CountTableKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
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
