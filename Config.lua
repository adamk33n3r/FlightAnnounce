local function HandleUpgrade(version)
    -- Upgrading from 1.0.0
    if FlightAnnounceDB.version == '1.0.0' then
        FlightAnnounceDB.selfChat = true
    end
    FlightAnnounceDB.version = version
end

local function AddSettingsCheckbox(category, variable, name, tooltip, defaultValue)
    -- The Settings variable is prefixed so it does not collide with other addons.
    -- The table key stays the FlightAnnounceDB field SendAnnouncement already reads.
    local setting = Settings.RegisterAddOnSetting(category, "FlightAnnounce_" .. variable, variable, FlightAnnounceDB, type(defaultValue), name, defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
end

-- Forever's settings panel is the 12.1 UI. OptionsCheckButtonTemplate was removed
-- in that rewrite, so a canvas of classic checkboxes dies at the first CreateFrame
-- and only the header font strings remain.
local function CreateModernConfig()
    local category, layout = Settings.RegisterVerticalLayoutCategory("FlightAnnounce")
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Chat Channels"))
    end

    AddSettingsCheckbox(category, "partyChat", "Party Chat", "Send to Party Chat if you are in a party", true)
    AddSettingsCheckbox(category, "raidChat", "Raid Chat", "Send to Raid Chat if you are in a raid group", false)
    AddSettingsCheckbox(category, "selfChat", "Self", "Print to your chat if you are not in a group", true)

    Settings.RegisterAddOnCategory(category)
    FlightAnnounceSettingsCategory = category
end

local function CreateLegacyConfig()
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.name = "FlightAnnounce"
    InterfaceOptions_AddCategory(panel)

    local TitleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    TitleText:SetJustifyH("LEFT")
    TitleText:SetPoint("TOPLEFT", 16, -16)
    TitleText:SetText("FlightAnnounce")
    local TitleSubText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    TitleSubText:SetJustifyH("LEFT")
    TitleSubText:SetPoint("TOPLEFT", TitleText, "BOTTOMLEFT", 0, -8)
    TitleSubText:SetText("These are general options for FlightAnnounce.")
    TitleSubText:SetTextColor(1, 1, 1, 1)

    local AlarmText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AlarmText:SetJustifyH("LEFT")
    AlarmText:SetPoint("TOPLEFT", TitleSubText, "BOTTOMLEFT", 0, -8)
    AlarmText:SetText("Chat Channels")

    local partyCheck = CreateCheck(panel, AlarmText, "Send to Party Chat if you are in a party", "Party Chat")
    local raidCheck = CreateCheck(panel, partyCheck, "Send to Raid Chat if you are in a raid group", "Raid Chat")
    local selfCheck = CreateCheck(panel, raidCheck, "Print to your chat if you are not in a group", "Self")
    partyCheck:SetScript("OnClick", function(self, button)
        FlightAnnounceDB.partyChat = partyCheck:GetChecked()
    end)
    raidCheck:SetScript("OnClick", function(self, button)
        FlightAnnounceDB.raidChat = raidCheck:GetChecked()
    end)
    selfCheck:SetScript("OnClick", function(self, button)
        FlightAnnounceDB.selfChat = selfCheck:GetChecked()
    end)
    partyCheck:SetChecked(FlightAnnounceDB.partyChat)
    raidCheck:SetChecked(FlightAnnounceDB.raidChat)
    selfCheck:SetChecked(FlightAnnounceDB.selfChat)
end

function CreateConfig(version)
    HandleUpgrade(version)

    -- Wrath has no Settings table, so it keeps the Interface Options panel.
    if Settings and Settings.RegisterVerticalLayoutCategory and Settings.CreateCheckbox then
        CreateModernConfig()
    else
        CreateLegacyConfig()
    end
end

function CreateCheck(parent, prevRegion, tip, text)
	local check = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", prevRegion, "BOTTOMLEFT", 0, 0)
	check.tooltipText = tip
	check.Text = check:CreateFontString(nil, "BACKGROUND","GameFontNormal")
	check.Text:SetPoint("LEFT", check, "RIGHT", 0)
	check.Text:SetText(text)
	return check
end

function CreateDropdown(parent, prevRegion, opts)
    local wrapper = CreateFrame('Frame', nil, parent)
    wrapper:SetSize(1, 32)
    wrapper:SetPoint('TOPLEFT', prevRegion, 'BOTTOMLEFT')
    local dropDown = CreateFrame('Frame', nil, wrapper, 'UIDropDownMenuTemplate')
    dropDown:SetPoint('TOPLEFT', wrapper, 'TOPLEFT', -16, -4)
    UIDropDownMenu_SetWidth(dropDown, 156)
    UIDropDownMenu_SetButtonWidth(dropDown, 156 + 20)
    -- UIDropDownMenu_SetText(dropDown, "Audio: " .. favoriteNumber)

    local function OnSelect(cb)
        return function(self, newValue)
            selectedID = newValue
            if cb then
                cb(newValue)
            end
            UIDropDownMenu_SetSelectedID(dropDown, self:GetID())
            CloseDropDownMenus()
        end
    end

    UIDropDownMenu_Initialize(dropDown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        -- Display a nested group of 10 favorite number options

        for i, opt in ipairs(opts) do
            info.text = opt.name
            info.func = OnSelect(opt.func)
            info.arg1 = opt.val
            info.checked = opt.selected
            UIDropDownMenu_AddButton(info, level)
        end

    end)

    return wrapper, dropDown
end
