local name, _FlightAnnounce = ...

local frame = CreateFrame("Frame")

local COLOR_MAIZE = "|cffffd700"
local COLOR_ORANGE = "|cffff8c00"
local COLOR_ERROR = "|cffee3333"
local COLOR_ADDON = "|cff3bd0ed"

local eventSent = false
local taxiSrc, taxiDst
local oldTakeTaxiNode

local function ShortenName(name)  -- shorten name to lighten saved vars and display
    return gsub(name, ", .+", "")
end

local function FormatTime(secs)  -- simple time format
    if not secs then
        return "??"
    end

    return format(TIMER_MINUTES_DISPLAY, secs / 60, secs % 60)
end

local function Print(...)
    print(COLOR_ADDON .. "<FlightAnnounce>|r:", ...)
end

frame:RegisterEvent("ADDON_LOADED")
-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TAXIMAP_OPENED")
function frame:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "FlightAnnounce" then
        local version = GetAddOnMetadata(name, "version")
        if FlightAnnounceDB == nil then
            FlightAnnounceDB = { version = version, partyChat = true, raidChat = false, selfChat = true }
        end
        CreateConfig(version)
        oldTakeTaxiNode = TakeTaxiNode
        TakeTaxiNode = function(slot)
            taxiDst = TaxiNodeName(slot)
            oldTakeTaxiNode(slot)
        end
        print(COLOR_ADDON .. "<FlightAnnounce>|r Version " .. version .. " has been loaded!")
    elseif event == "TAXIMAP_OPENED" then
        taxiSrc = nil
        for i = 1, NumTaxiNodes(), 1 do
            local tb = _G["TaxiButton"..i]
            if TaxiNodeGetType(i) == "CURRENT" then
                taxiSrc = TaxiNodeName(i)
            end
        end
            -- Workaround for Blizzard bug on OutLand Flight Map
        if not taxiSrc and GetTaxiMapID() == 1467 and GetMinimapZoneText() == "Shatter Point" then
            taxiSrc = "Shatter Point"
        end
    end
end
frame:SetScript("OnEvent", frame.OnEvent)

frame:SetScript("OnUpdate", function(self, elapsed)
    if eventSent == false and UnitOnTaxi("player") == true then
        eventSent = true
        SendAnnouncement(BuildMessage(taxiSrc, taxiDst))
    elseif eventSent == true and UnitOnTaxi("player") == false then
        eventSent = false
        local message = format("The bird has landed at %s", taxiDst)
        SendAnnouncement(message)
        taxiSrc = nil
        taxiDst = nil
    end
end)

SLASH_FLIGHTANNOUNCE1 = '/flightannounce'

function SlashCmdList.FLIGHTANNOUNCE(msg, editbox)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if cmd == "config" or cmd == nil then
        -- Called twice because sometimes (like after a /reload) it doesn't work right
        InterfaceOptionsFrame_OpenToCategory("FlightAnnounce")
        InterfaceOptionsFrame_OpenToCategory("FlightAnnounce")
    elseif cmd == "help" then
        print("Available commands:")
        print("    /flightannounce config - Open up the config")
    end
end

function BuildMessage(src, dst)
    local message = format("Taking flight from %s to %s", src, dst)
    if InFlight then
        local faction = UnitFactionGroup("player")
        local ttl = InFlight.db.global[faction][ShortenName(src)][ShortenName(dst)]
        message = message..format(" (%s)", FormatTime(ttl))
    end
    return message
end

function SendAnnouncement(message)
    local sent = false
    if UnitInParty("player") and FlightAnnounceDB.partyChat then
        SendChatMessage(message, "PARTY")
        sent = true
    end
    if UnitInRaid("player") and FlightAnnounceDB.raidChat then
        SendChatMessage(message, "RAID")
        sent = true
    end
    if not sent and FlightAnnounceDB.selfChat then
        Print(message)
    end
end


-- Adapted from InFlight_Load
local t
do
t = {
    ["Amber Ledge"]                  = {{ find = "I'd like passage to the Transitus Shield",                         s = "Amber Ledge",                d = "Transitus Shield (Scenic Route)" }},
    ["Argent Tournament Grounds"]    = {{ find = "Mount the Hippogryph and prepare for battle",                      s = "Argent Tournament Grounds",  d = "Return" }},
    ["Blackwind Landing"]            = {{ find = "Send me to the Skyguard Outpost",                                  s = "Blackwind Landing",          d = "Skyguard Outpost" }},
    ["Caverns of Time"]              = {{ find = "Please take me to the master's lair",                              s = "Caverns of Time",            d = "Nozdormu's Lair" }},
    ["Expedition Point"]             = {{ find = "Send me to Shatter Point",                                         s = "Expedition Point",           d = "Shatter Point" }},
    ["Hellfire Peninsula"]           = {{ find = "Send me to Shatter Point",                                         s = "Honor Point",                d = "Shatter Point" }},
    ["Nighthaven"]                   = {{ find = "I'd like to fly to Rut'theran Village",                            s = "Nighthaven",                 d = "Rut'theran Village" },
                                        { find = "I'd like to fly to Thunder Bluff",                                 s = "Nighthaven",                 d = "Thunder Bluff" }},
    ["Old Hillsbrad Foothills"]      = {{ find = "I'm ready to go to Durnholde Keep",                                s = "Old Hillsbrad Foothills",    d = "Durnholde Keep" }},
    ["Reaver's Fall"]                = {{ find = "Lend me a Windrider.  I'm going to Spinebreaker Post",             s = "Reaver's Fall",              d = "Spinebreaker Post" }},
    ["Shatter Point"]                = {{ find = "Send me to Honor Point",                                           s = "Shatter Point",              d = "Honor Point" }},
    ["Skyguard Outpost"]             = {{ find = "Yes, I'd love a ride to Blackwind Landing",                        s = "Skyguard Outpost",           d = "Blackwind Landing" }},
    ["Stormwind City"]               = {{ find = "I'd like to take a flight around Stormwind Harbor",                s = "Stormwind City",             d = "Return" }},
    ["Sun's Reach Harbor"]           = {{ find = "Speaking of action, I've been ordered to undertake an air strike", s = "Shattered Sun Staging Area", d = "Return" },
                                        { find = "I need to intercept the Dawnblade reinforcements",                 s = "Shattered Sun Staging Area", d = "The Sin'loren" }},
    ["The Sin'loren"]                = {{ find ="Ride the dragonhawk to Sun's Reach",                                s = "The Sin'loren",              d = "Shattered Sun Staging Area" }},
    ["Valgarde"]                     = {{ find = "Take me to the Explorers' League Outpost",                         s = "Valgarde",                   d = "Explorers' League Outpost" }},
}
end

hooksecurefunc("GossipTitleButton_OnClick", function(this, button)
    if this.type ~= "Gossip" then
        return
    end

    local subzone = GetMinimapZoneText()
    local tsz = t[subzone]
    if not tsz then
        return
    end

    local text = this:GetText()
    if not text or text == "" then
        return
    end
    
    local source, destination
    for _, sz in ipairs(tsz) do
        if strfind(text, sz.find, 1, true) then
            source = sz.s
            destination = sz.d
            break
        end
    end

    if source and destination then
        SendAnnouncement(BuildMessage(source, destination))
    end
end)
