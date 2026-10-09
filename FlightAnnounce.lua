local name, _FlightAnnounce = ...

local frame = CreateFrame("Frame")

local COLOR_MAIZE = "|cffffd700"
local COLOR_ORANGE = "|cffff8c00"
local COLOR_ERROR = "|cffee3333"
local COLOR_ADDON = "|cff3bd0ed"

local eventSent = false
local taxiSrc, taxiDst
-- Click-time Ellesmere estimate. InFlight's measured time wins at announce time.
local taxiSeconds
local oldTakeTaxiNode

-- Yards per direct hop, keyed fromNodeID * 10000 + toNodeID. The taxi map is
-- closed by announce time, so the sum happens on click. 30.4 is Ellesmere's
-- speed until a landing teaches one. The standalone package renames the suite
-- globals to EUICoreStandaloneForeverEssentials and its DB.
local ELLESMERE_DEFAULT_SPEED = 30.4

local function EllesmereTimerData()
    if EllesmereUI and EllesmereUI._FlightTimerRoutes then
        return EllesmereUI._FlightTimerRoutes, EllesmereUIDB and EllesmereUIDB.flightTimer
    end
    local core = EUICoreStandaloneForeverEssentials
    if core and core._FlightTimerRoutes then
        local db = EUICoreStandaloneForeverEssentialsDB
        return core._FlightTimerRoutes, db and db.flightTimer
    end
end

local function EllesmereSeconds(slot)
    local routes, settings = EllesmereTimerData()
    if not routes then
        return nil
    end
    local mapID = GetTaxiMapID()
    local nodes = mapID and C_TaxiMap.GetAllTaxiNodes(mapID)
    if not nodes then
        return nil
    end
    local idBySlot = {}
    for _, node in ipairs(nodes) do
        idBySlot[node.slotIndex] = node.nodeID
    end
    local hops = GetNumRoutes(slot)
    if hops < 1 then
        return nil
    end
    local yards = 0
    for hop = 1, hops do
        local fromID = idBySlot[TaxiGetNodeSlot(slot, hop, true)]
        local toID = idBySlot[TaxiGetNodeSlot(slot, hop, false)]
        local hopYards = fromID and toID and routes[fromID * 10000 + toID]
        if type(hopYards) ~= "number" then
            return nil
        end
        yards = yards + hopYards
    end
    local speed = settings and settings.speed or ELLESMERE_DEFAULT_SPEED
    if type(speed) ~= "number" or speed <= 0 then
        return nil
    end
    -- Frequent Flier is trait node 110300 on tree 1188. Stored speed excludes it.
    local mult = 1
    local configID = C_Traits.GetConfigIDByTreeID(1188)
    local node = configID and C_Traits.GetNodeInfo(configID, 110300)
    if node and (node.activeRank or 0) > 0 then
        mult = 1.2
    end
    return yards / (speed * mult)
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

-- GetAddOnMetadata was removed on the modern client Forever uses. Wrath still has the global.
local function GetAddonVersion()
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(name, "version")
    end
    return GetAddOnMetadata(name, "version")
end

local function OpenConfig()
    -- Forever registers a vertical Settings category. Wrath still uses the old options frame,
    -- which often needs a second call before the category is selected after a reload.
    -- C_SettingsUtil.OpenSettingsPanel takes the numeric category ID. The category
    -- table itself is out of that int32 range and errors inside OpenToCategory.
    if Settings and Settings.OpenToCategory and FlightAnnounceSettingsCategory then
        Settings.OpenToCategory(FlightAnnounceSettingsCategory:GetID())
        return
    end
    InterfaceOptionsFrame_OpenToCategory("FlightAnnounce")
    InterfaceOptionsFrame_OpenToCategory("FlightAnnounce")
end

frame:RegisterEvent("ADDON_LOADED")
-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TAXIMAP_OPENED")
function frame:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "FlightAnnounce" then
        local version = GetAddonVersion()
        if FlightAnnounceDB == nil then
            FlightAnnounceDB = { version = version, partyChat = true, raidChat = false, selfChat = true }
        end
        CreateConfig(version)
        oldTakeTaxiNode = TakeTaxiNode
        TakeTaxiNode = function(slot)
            taxiDst = TaxiNodeName(slot)
            taxiSeconds = EllesmereSeconds(slot)
            oldTakeTaxiNode(slot)
        end
        print(COLOR_ADDON .. "<FlightAnnounce>|r Version " .. version .. " has been loaded!")
    elseif event == "TAXIMAP_OPENED" then
        taxiSrc = nil
        taxiSeconds = nil
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
        if taxiSrc ~= nil and taxiDst ~= nil then
			SendAnnouncement(BuildMessage(taxiSrc, taxiDst))
        end
    elseif eventSent == true and UnitOnTaxi("player") == false then
        eventSent = false
        local message
        if taxiDst ~= nil then
			message = format("The bird has landed at %s", taxiDst)
        else
			message = "The bird has landed"
		end
		SendAnnouncement(message)
        taxiSrc = nil
        taxiDst = nil
        taxiSeconds = nil
    end
end)

SLASH_FLIGHTANNOUNCE1 = '/flightannounce'

function SlashCmdList.FLIGHTANNOUNCE(msg, editbox)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if cmd == "config" or cmd == nil then
        OpenConfig()
    elseif cmd == "help" then
        print("Available commands:")
        print("    /flightannounce config - Open up the config")
    end
end

function BuildMessage(src, dst)
    local message = format("Taking flight from %s to %s", src, dst)
    -- InFlight keys saved routes by node id, not by the names we announce.
    -- GetFlightTime is the seconds it already resolved for this takeoff
    -- (known time or hop estimate), including gossip flights via StartMiscFlight.
    -- It is nil when InFlight has no time, and missing on older builds.
    local ttl
    if InFlight and InFlight.GetFlightTime then
        local inflight = InFlight:GetFlightTime()
        if type(inflight) == "number" and inflight > 0 then
            ttl = inflight
        end
    end
    if not ttl and type(taxiSeconds) == "number" and taxiSeconds > 0 then
        ttl = taxiSeconds
    end
    if ttl then
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
    ["The Sin'loren"]                = {{ find = "Ride the dragonhawk to Sun's Reach",                               s = "The Sin'loren",              d = "Shattered Sun Staging Area" }},
    ["Valgarde"]                     = {{ find = "Take me to the Explorers' League Outpost",                         s = "Valgarde",                   d = "Explorers' League Outpost" }},
}
end

local function OnGossipOptionClicked(text)
    local subzone = GetMinimapZoneText()
    local tsz = t[subzone]
    if not tsz then
        return
    end

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
        taxiSrc = source
        taxiDst = destination
        taxiSeconds = nil
    end
end

-- Forever's gossip buttons are the mixin. Wrath still creates GossipTitleButton1..N,
-- and hooking a missing mixin would stop the addon from loading there.
if GossipOptionButtonMixin then
    hooksecurefunc(GossipOptionButtonMixin, "OnClick", function(this)
        OnGossipOptionClicked(this:GetText())
    end)
else
    local index = 1
    while true do
        local button = _G["GossipTitleButton" .. index]
        if not button then
            break
        end
        button:HookScript("OnClick", function(self)
            OnGossipOptionClicked(self:GetText())
        end)
        index = index + 1
    end
end
