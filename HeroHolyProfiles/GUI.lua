local addonName, HHP = ...

local mainFrame

function HHP.CreateGUI()
    if mainFrame then
        return mainFrame
    end
    
    mainFrame = CreateFrame("Frame", "HeroHolyProfilesFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(700, 500)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()
    
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.title:SetFontObject("GameFontHighlightLarge")
    mainFrame.title:SetPoint("TOP", mainFrame, "TOP", 0, -5)
    mainFrame.title:SetText("HeroHolyProfiles")
    
    local statusText = mainFrame:CreateFontString(nil, "OVERLAY")
    statusText:SetFontObject("GameFontNormal")
    statusText:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -35)
    statusText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -15, -35)
    statusText:SetJustifyH("LEFT")
    statusText:SetHeight(40)
    mainFrame.statusText = statusText
    
    local saveButton = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    saveButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -80)
    saveButton:SetSize(120, 25)
    saveButton:SetText("Speichern")
    saveButton:SetNormalFontObject("GameFontNormal")
    saveButton:SetHighlightFontObject("GameFontHighlight")
    saveButton:SetScript("OnClick", function()
        HHP.ShowSaveDialog()
    end)
    
    local checkButton = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    checkButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
    checkButton:SetSize(120, 25)
    checkButton:SetText("Status prüfen")
    checkButton:SetNormalFontObject("GameFontNormal")
    checkButton:SetHighlightFontObject("GameFontHighlight")
    checkButton:SetScript("OnClick", function()
        HHP.UpdateGUIStatus()
    end)
    
    local refreshButton = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    refreshButton:SetPoint("LEFT", checkButton, "RIGHT", 10, 0)
    refreshButton:SetSize(120, 25)
    refreshButton:SetText("Aktualisieren")
    refreshButton:SetNormalFontObject("GameFontNormal")
    refreshButton:SetHighlightFontObject("GameFontHighlight")
    refreshButton:SetScript("OnClick", function()
        HHP.RefreshProfileList()
    end)
    
    local settingsFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    settingsFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -115)
    settingsFrame:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -340, -115)
    settingsFrame:SetHeight(360)
    settingsFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    settingsFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    settingsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    mainFrame.settingsFrame = settingsFrame
    
    local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY")
    settingsTitle:SetFontObject("GameFontNormalLarge")
    settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
    settingsTitle:SetText("|cFFFFD700Aktuelle Settings|r")
    
    local settingsScrollFrame = CreateFrame("ScrollFrame", nil, settingsFrame, "UIPanelScrollFrameTemplate")
    settingsScrollFrame:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -35)
    settingsScrollFrame:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -30, 10)
    
    local settingsScrollChild = CreateFrame("Frame", nil, settingsScrollFrame)
    settingsScrollChild:SetSize(300, 1)
    settingsScrollFrame:SetScrollChild(settingsScrollChild)
    mainFrame.settingsScrollChild = settingsScrollChild
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 355, -115)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 15)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(305, 1)
    scrollFrame:SetScrollChild(scrollChild)
    mainFrame.scrollChild = scrollChild
    
    HHP.UpdateGUIStatus()
    
    return mainFrame
end

function HHP.UpdateGUIStatus()
    if not mainFrame then return end
    
    local status = ""
    
    if HHP.CheckHolySettings() then
        status = "|cFF00FF00✓ HeroRotation Holy Settings verfügbar|r\n"
        local settings = HHP.GetHolySettings()
        if settings then
            local count = 0
            for _ in pairs(settings) do count = count + 1 end
            status = status .. "Verfügbare Einstellungen: " .. count
        end
    else
        status = "|cFFFF0000✗ HeroRotation Settings nicht verfügbar|r\n"
        status = status .. "Öffne das HeroRotation GUI mindestens einmal!"
    end
    
    mainFrame.statusText:SetText(status)
    HHP.RefreshProfileList()
    HHP.RefreshSettingsDisplay()
end

function HHP.RefreshSettingsDisplay()
    if not mainFrame or not mainFrame.settingsScrollChild then return end
    
    for _, child in pairs({mainFrame.settingsScrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local settings = HHP.GetHolySettings()
    if not settings then
        local noSettingsText = mainFrame.settingsScrollChild:CreateFontString(nil, "OVERLAY")
        noSettingsText:SetFontObject("GameFontNormal")
        noSettingsText:SetPoint("TOP", mainFrame.settingsScrollChild, "TOP", 0, -10)
        noSettingsText:SetText("|cFFFF8800Keine Settings verfügbar|r\n\nÖffne das HeroRotation\nGUI mindestens einmal!")
        return
    end
    
    local yOffset = 0
    local displayedSettings = {}
    
    local function addSetting(name, value)
        local settingFrame = CreateFrame("Frame", nil, mainFrame.settingsScrollChild)
        settingFrame:SetSize(280, 22)
        settingFrame:SetPoint("TOPLEFT", mainFrame.settingsScrollChild, "TOPLEFT", 0, -yOffset)
        
        local keyText = settingFrame:CreateFontString(nil, "OVERLAY")
        keyText:SetFontObject("GameFontNormalSmall")
        keyText:SetPoint("LEFT", settingFrame, "LEFT", 5, 0)
        keyText:SetWidth(180)
        keyText:SetJustifyH("LEFT")
        keyText:SetText(name)
        
        local valueText = settingFrame:CreateFontString(nil, "OVERLAY")
        valueText:SetFontObject("GameFontHighlightSmall")
        valueText:SetPoint("RIGHT", settingFrame, "RIGHT", -5, 0)
        valueText:SetJustifyH("RIGHT")
        
        local displayValue = tostring(value)
        if type(value) == "number" then
            displayValue = string.format("%.0f", value)
        elseif type(value) == "boolean" then
            displayValue = value and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
        end
        valueText:SetText(displayValue)
        
        yOffset = yOffset + 22
        table.insert(displayedSettings, {name = name, value = value})
    end
    
    local function processSetting(key, value, prefix)
        prefix = prefix or ""
        
        if type(value) == "table" then
            if value.value ~= nil then
                addSetting(prefix .. key, value.value)
            else
                local sortedSubKeys = {}
                for subKey in pairs(value) do
                    table.insert(sortedSubKeys, subKey)
                end
                table.sort(sortedSubKeys)
                
                for _, subKey in ipairs(sortedSubKeys) do
                    processSetting(subKey, value[subKey], prefix .. key .. " > ")
                end
            end
        elseif type(value) == "number" or type(value) == "boolean" then
            addSetting(prefix .. key, value)
        end
    end
    
    local sortedKeys = {}
    for key in pairs(settings) do
        table.insert(sortedKeys, key)
    end
    table.sort(sortedKeys)
    
    for _, key in ipairs(sortedKeys) do
        processSetting(key, settings[key])
    end
    
    if #displayedSettings == 0 then
        local emptyText = mainFrame.settingsScrollChild:CreateFontString(nil, "OVERLAY")
        emptyText:SetFontObject("GameFontNormal")
        emptyText:SetPoint("TOP", mainFrame.settingsScrollChild, "TOP", 0, -10)
        emptyText:SetText("|cFF888888Keine konfigurierbaren\nSettings gefunden.|r\n\nDebug aktivieren:\n/hhp debug")
        yOffset = 80
    end
    
    mainFrame.settingsScrollChild:SetHeight(math.max(yOffset, 1))
end

function HHP.RefreshProfileList()
    if not mainFrame or not mainFrame.scrollChild then return end
    
    for _, child in pairs({mainFrame.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yOffset = 0
    local profileCount = 0
    
    for profileName, profile in pairs(HeroHolyProfilesDB.profiles) do
        profileCount = profileCount + 1
        
        local profileFrame = CreateFrame("Frame", nil, mainFrame.scrollChild, "BackdropTemplate")
        profileFrame:SetSize(295, 60)
        profileFrame:SetPoint("TOPLEFT", mainFrame.scrollChild, "TOPLEFT", 0, -yOffset)
        profileFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        profileFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        profileFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        local nameText = profileFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFontObject("GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", profileFrame, "TOPLEFT", 10, -10)
        nameText:SetText("|cFFFFD700" .. profileName .. "|r")
        
        local dateText = profileFrame:CreateFontString(nil, "OVERLAY")
        dateText:SetFontObject("GameFontNormalSmall")
        dateText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
        dateText:SetText("Gespeichert: " .. date("%d.%m.%Y %H:%M", profile.timestamp))
        
        local loadBtn = CreateFrame("Button", nil, profileFrame, "GameMenuButtonTemplate")
        loadBtn:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -10, -8)
        loadBtn:SetSize(80, 20)
        loadBtn:SetText("Laden")
        loadBtn:SetNormalFontObject("GameFontNormalSmall")
        loadBtn:SetScript("OnClick", function()
            if HHP.LoadProfile(profileName) then
                HHP.UpdateGUIStatus()
            end
        end)
        
        local deleteBtn = CreateFrame("Button", nil, profileFrame, "GameMenuButtonTemplate")
        deleteBtn:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -10, -32)
        deleteBtn:SetSize(80, 20)
        deleteBtn:SetText("Löschen")
        deleteBtn:SetNormalFontObject("GameFontNormalSmall")
        deleteBtn:SetScript("OnClick", function()
            StaticPopup_Show("HHP_DELETE_PROFILE", profileName, nil, profileName)
        end)
        
        yOffset = yOffset + 65
    end
    
    if profileCount == 0 then
        local emptyText = mainFrame.scrollChild:CreateFontString(nil, "OVERLAY")
        emptyText:SetFontObject("GameFontNormal")
        emptyText:SetPoint("TOP", mainFrame.scrollChild, "TOP", 0, -20)
        emptyText:SetText("|cFF888888Keine Profile gespeichert.|r\nKlicke 'Speichern' um ein neues Profil zu erstellen.")
    end
    
    mainFrame.scrollChild:SetHeight(math.max(yOffset, 1))
end

function HHP.ShowSaveDialog()
    StaticPopupDialogs["HHP_SAVE_PROFILE"] = {
        text = "Gib einen Namen für das Profil ein:",
        button1 = "Speichern",
        button2 = "Abbrechen",
        hasEditBox = 1,
        maxLetters = 32,
        OnAccept = function(self)
            local editBox = _G[self:GetName().."EditBox"]
            if editBox then
                local text = editBox:GetText()
                if text and text ~= "" then
                    if HHP.SaveProfile(text) then
                        HHP.RefreshProfileList()
                    end
                end
            end
        end,
        OnShow = function(self)
            local editBox = _G[self:GetName().."EditBox"]
            if editBox then
                editBox:SetFocus()
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local text = self:GetText()
            if text and text ~= "" then
                if HHP.SaveProfile(text) then
                    HHP.RefreshProfileList()
                end
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("HHP_SAVE_PROFILE")
end

StaticPopupDialogs["HHP_DELETE_PROFILE"] = {
    text = "Profil '%s' wirklich löschen?",
    button1 = "Löschen",
    button2 = "Abbrechen",
    OnAccept = function(self, profileName)
        if HHP.DeleteProfile(profileName) then
            HHP.RefreshProfileList()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function HHP.ToggleGUI()
    if not mainFrame then
        HHP.CreateGUI()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        HHP.UpdateGUIStatus()
        mainFrame:Show()
    end
end
