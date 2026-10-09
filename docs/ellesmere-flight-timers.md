# Ellesmere flight-timer data

Research note for FlightAnnounce. No code changes. Sources are the addons' own files on GitHub, pinned below. CurseForge and Wago pages were not used as evidence for the schema.

Pinned trees:

- EllesmereUI `main` `e7c51bf229b1247dd2023a806d77cc47aa1ec34b` (2026-10-09). Flight-timer Lua matches release tag `v9.4` (`52e68688b68bfaeba4af4cbf2cb702aa35a541a8`, 2026-10-07). The Forever Essentials TOC on `main` only adds macro files after that tag.
- InFlight `main` `310f5fa167c6171ec2858561077ec441989541ae` (2026-08-08).

Base URLs:

- https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/
- https://github.com/LudiusMaximus/InFlight/blob/310f5fa167c6171ec2858561077ec441989541ae/

## What "Ellesmere" is

There is no separate addon whose folder is `Ellesmere`. The flight timer ships inside **EllesmereUI Forever Essentials**.

| Fact | Value | Source |
| --- | --- | --- |
| Suite | EllesmereUI | [`EllesmereUI.toc`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/EllesmereUI.toc) `Title`, `Author` |
| Module folder | `EllesmereUIForeverEssentials` | [`.pkgmeta`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/.pkgmeta) `move-folders` |
| TOC file | `EllesmereUIForeverEssentials_Camelot.toc` only. No `EllesmereUIForeverEssentials.toc` in the tree. | repo tree; TOC path |
| Title | `EllesmereUI Forever Essentials` | Camelot TOC line 3 |
| Author | Ellesmere | Camelot TOC `## Author: Ellesmere`; parent TOC `## Author: Ellesmere` |
| Version on these files | 9.4 | Parent TOC and Camelot TOC `## Version: 9.4` |
| License | Custom. Copyright 2026, all rights reserved. Not a permissive license. | [`license.txt`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/license.txt) |
| Saved variables (parent) | `EllesmereUIDB` | Parent TOC `## SavedVariables: EllesmereUIDB` |
| Saved variables (this module) | None of its own. Settings are account-wide keys inside `EllesmereUIDB`. | [`EllesmereUIForeverEssentials.lua`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/EllesmereUIForeverEssentials/EllesmereUIForeverEssentials.lua) `ns.Feature` |

The parent package moves `EllesmereUIForeverEssentials` out to its own addon folder (`.pkgmeta`). The Camelot TOC lists the flight-timer files:

```toc
## Dependencies: EllesmereUI
EllesmereUIForeverEssentials_FlightTimerData.lua
EllesmereUIForeverEssentials_FlightTimer.lua
```

Source: [`EllesmereUIForeverEssentials_Camelot.toc`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/EllesmereUIForeverEssentials/EllesmereUIForeverEssentials_Camelot.toc).

## Clients

Parent `EllesmereUI.toc` declares:

```toc
## Interface: 120000, 120001, 120005, 120007, 120100, 16001
```

Forever Essentials declares:

```toc
## Interface: 16001
## AllowLoadGameType: camelot
```

Runtime gate, `EllesmereUI_ClientGate.lua`: `select(4, GetBuildInfo())` in `16000..19999` sets `EUI_CLIENT_FOREVER` and does not block. Any other interface below `120100` sets `EUI_CLIENT_BLOCKED`. The comment in that file calls Forever "Blizzard game type camelot" and "the 12.1 engine with vanilla content, reporting a 1.60+ toc (16001)". Classic Era `115xx` and retail `12xxxx` are described there as ranges that do not overlap Forever.

`EllesmereUI_Lite.lua` then sets `EllesmereUI.IS_FOREVER = (EUI_CLIENT_FOREVER == true)`.

Both flight-timer files return immediately unless that flag is set:

```lua
if EUI_CLIENT_BLOCKED then return end
if not (EllesmereUI and EllesmereUI.IS_FOREVER) then return end
```

Source: [`EllesmereUIForeverEssentials_FlightTimer.lua`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/EllesmereUIForeverEssentials/EllesmereUIForeverEssentials_FlightTimer.lua) lines 1–2 and [`EllesmereUIForeverEssentials_FlightTimerData.lua`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/EllesmereUIForeverEssentials/EllesmereUIForeverEssentials_FlightTimerData.lua) lines 1–2.

Against FlightAnnounce's TOC (`30401`, `16001`):

| Client | FlightAnnounce TOC | Ellesmere flight data loads? |
| --- | --- | --- |
| Wrath 3.4.1 | 30401 | No. 30401 is below 120100 and outside 16000–19999, so the suite sets `EUI_CLIENT_BLOCKED`. Forever Essentials also has no Wrath TOC and `AllowLoadGameType: camelot`. |
| Forever | 16001 | Yes, when game type is camelot and both `EllesmereUI` and `EllesmereUIForeverEssentials` are enabled. |
| Classic Era, TBC, Cata, MoP | not declared by FlightAnnounce | Not declared by Ellesmere either. The client gate blocks those interface numbers. |
| Retail 12.0.x (`120000`–`120007`) | not declared | Listed on the parent TOC, then disabled by the pre-12.1 failsafe. |
| Retail 12.1+ (`120100`) | not declared | Parent can run. Forever Essentials still returns because `IS_FOREVER` is false, and its TOC is camelot-only. |

No Classic Era, Cataclysm, or MoP interface numbers appear in either TOC.

## Where a duration lives

Ellesmere does not store flight durations, and it does not key routes by faction or by node name.

### Route table (code, not saved variables)

`EllesmereUI._FlightTimerRoutes` is a flat table of **yards**, assigned at file load. The file header is:

```lua
-- Generated by .tools/forever-taxi-lengths.py from WoW Forever build 1.60.1.69913.
-- Flown length of each flight route in yards, keyed fromNodeID * 10000 + toNodeID.
EllesmereUI._FlightTimerRoutes = {
```

One shipped entry is `[800025] = 2074`. The generator [`.tools/forever-taxi-lengths.py`](https://github.com/EllesmereGaming/EllesmereUI/blob/e7c51bf229b1247dd2023a806d77cc47aa1ec34b/.tools/forever-taxi-lengths.py) writes that formula: key = `fromNodeID * 10000 + toNodeID`, value = rounded spline length in yards. It skips paths that have a waypoint delay or that cross continents (boats and zeppelins). It aborts if either node id is `>= 10000`.

The Horde preview route in `PREVIEW_ROUTES` names node `80` as Ratchet and node `25` as Crossroads. `80 * 10000 + 25` is `800025`, so that entry is 2074 yards. The value is a number. It is not a nested table. There is no faction key and no name key.

```lua
local yards = EllesmereUI._FlightTimerRoutes[80 * 10000 + 25] -- 2074
```

A multi-stop flight is the sum of direct hops. The same preview route continues Crossroads `25` to Freewind Post `30` (`250030` = `5566` yards) and Freewind Post `30` to Gadgetzan `40` (`300040` = `2810` yards). There is no single Ratchet-to-Gadgetzan entry. `RouteInfo` in `FlightTimer.lua` walks `GetNumRoutes(slot)` and sums `routes[from * 10000 + to]`, returning nil yards if any hop is missing.

Alliance uses different node ids, still with no faction key. The Alliance preview starts at Ironforge `6` to Thorium Point `74`, key `60074` = `2621` yards.

### Turning yards into seconds

`FlightTimer.lua` header: the client exposes no flight duration, so time is length / speed.

```lua
local DEFAULT_SPEED = 30.4 -- yards per second
flight.eta = yards / (Speed() * flight.mult)
```

`Speed()` is `EllesmereUIDB.flightTimer.speed` or `30.4`. `flight.mult` is `SpeedMultiplier()`: `1.2` when Adventure Legacy tree `1188`, node `110300` ("Frequent Flier") has `activeRank > 0`, otherwise `1`. A missing trait config is treated as no perk. The comment says the perk is per character and the stored speed excludes it so characters can share one speed.

Ratchet to Crossroads at the default speed, perk off:

`2074 / 30.4` ≈ **68.2 seconds**.

With Frequent Flier: `2074 / (30.4 * 1.2)` ≈ **56.9 seconds**.

`Land` writes `EllesmereUIDB.flightTimer.speed` only after a normal landing, and only when the measured yards-per-second (perk divided out) is within 75%–133% of the current speed. It moves the stored speed one quarter of the way toward the measurement. Early landing learns nothing.

`EllesmereUIDB.flightTimer` is display settings plus that one speed number (`Feature("flightTimer", ...)`). It is account-wide, not per character, and not per route. Reset clears `EllesmereUIDB.flightTimer` (`EUI_ForeverEssentials_Options.lua` `onReset`). The route table is not in saved variables, so a reset does not delete it.

### Globals another addon can see

| Global | What it is |
| --- | --- |
| `EllesmereUI` | Suite table. Created in `EllesmereUI_Lite.lua`. |
| `EllesmereUI.IS_FOREVER` | Boolean. |
| `EllesmereUI._FlightTimerRoutes` | Yards by packed node ids. Present only after Forever Essentials loads on Forever. |
| `EllesmereUI._FlightTimer` | Options hooks: `Get`, `Cfg`, `Apply`, `ApplyStyle`, `ApplyPosition`, `textures`, `CreateSettingsPreview`. Assigned at the bottom of `FlightTimer.lua`. |
| `EllesmereUIDB.flightTimer` | Account-wide settings. Optional `speed` in yards per second. |
| `EllesmereUIDB.flightTimer.pos` | Unlock-mode anchor, not a route. |
| `EUICoreStandaloneForeverEssentials._FlightTimerRoutes` | Same yards table in the standalone package. Folder name is `EUIStandaloneForeverEssentials` (Curse file `v9.4-forever`). |
| `EUICoreStandaloneForeverEssentialsDB.flightTimer` | Standalone account-wide settings. Optional `speed`, same role as `EllesmereUIDB.flightTimer`. |

`PLUGINS_API.md` says fields whose names start with `_` are internal and can change or disappear in any update. `_FlightTimerRoutes` and `_FlightTimer` are in that class. The plugin API documents settings pages. It does not document a flight-time query.

There is no function that takes two names, or two node ids, and returns seconds. `RouteInfo(slot)` is the lookup, and it is `local`. It needs an open taxi map: `GetTaxiMapID()`, `C_TaxiMap.GetAllTaxiNodes`, `TaxiGetNodeSlot`, `GetNumRoutes`. `StartFlight` keeps `flight.eta` in a file-local `flight` table that is not exported.

## Load order, InFlight, and both addons at once

Forever Essentials has `## Dependencies: EllesmereUI`, so the parent loads first. The yards table is assigned while the data file runs, which the TOC places before `FlightTimer.lua`. The enabled toggle does not gate that assignment. Turning the bar off only skips `hooksecurefunc("TakeTaxiNode", ...)`.

Nothing in the flight-timer files mentions InFlight. Saved variables do not overlap (`EllesmereUIDB` vs `InFlightDB`). Both addons can be enabled together.

`TakeTaxiNode` interaction:

- Ellesmere uses `hooksecurefunc("TakeTaxiNode", OnTakeTaxiNode)` from `Apply()`, which runs on `PLAYER_LOGIN`.
- Current InFlight replaces the global `TakeTaxiNode` inside `LoadBulk` during `ADDON_LOADED`, and calls the previous function.
- FlightAnnounce also replaces `TakeTaxiNode` on its own `ADDON_LOADED`.

`hooksecurefunc` attaches to the function that is current when it runs. A later replacement that does not call the previous function will not run Ellesmere's hook. FlightAnnounce and InFlight both call the saved previous function, so a wrapper chain from `ADDON_LOADED` still reaches them. Ellesmere's hook is registered later, on `PLAYER_LOGIN`.

FlightAnnounce reads a duration when `UnitOnTaxi` becomes true, which is after `TakeTaxiNode` returns. The yards table does not depend on that hook. It is already there if the addon loaded.

`## OptionalDeps` does not load a disabled addon. It does load an enabled optional dependency first. A lookup that runs at taxi time only needs a nil check. `OptionalDeps` is still the right TOC line so the dependency is explicit and so an `ADDON_LOADED` probe would see the global.

Suggested TOC line, beside the existing InFlight dep:

```toc
## OptionalDeps: InFlight, EllesmereUIForeverEssentials, EUIStandaloneForeverEssentials
```

The last name is the standalone Curse package's folder, not a second copy of the suite module. Its packager renames `EllesmereUI` to `EUICoreStandaloneForeverEssentials`.

`EllesmereUIForeverEssentials` already depends on `EllesmereUI`, so the parent loads before it. A hard `## Dependencies` line would stop FlightAnnounce on Wrath, where this module cannot load.

## Name matching

Ellesmere never shortens names and never uses them as keys. Subzone suffixes on `TaxiNodeName` do not change the yards lookup. Faction-specific flight masters are different node ids, not `"Alliance"` / `"Horde"` strings.

`RouteInfo` uses the live taxi map. If `GetTaxiMapID()` is missing, it returns nil yards and the bar counts elapsed time only.

FlightAnnounce's gossip table never goes through `TakeTaxiNode`. Ellesmere only records a route from that hook. Those special flights are also absent from the generated table, which is direct `TaxiPath` hops between taxi node ids. Names FlightAnnounce sets by hand are not keys:

- `Transitus Shield (Scenic Route)`, `Return`, `Nozdormu's Lair`, `Explorers' League Outpost`, `The Sin'loren`, `Skyguard Outpost`, and the rest of the gossip `d` fields in `FlightAnnounce.lua`.

Shatter Point is the same class of problem. FlightAnnounce forces `taxiSrc = "Shatter Point"` when map `1467` has no CURRENT node. Ellesmere has no Shatter Point special case. Without a current slot and a node id, `RouteInfo` cannot sum hops.

Display names in the preview (`"Ratchet"`, `"Crossroads"`) are literals for the options demo. The data file does not store them.

## How FlightAnnounce reads it

`FlightAnnounce.lua` does this. `TakeTaxiNode` stores the estimate while the taxi map is open. `BuildMessage` prefers `InFlight:GetFlightTime()` (measured seconds) and uses the stored Ellesmere estimate only when that is missing. Do not vendor `FlightTimerData.lua`. `license.txt` reserves the rights, and the table is regenerated per Forever build.

Use Ellesmere only on Forever, and only as a taxi-map estimate. Wrath `30401` will not have the table.

Lookup order when building the announcement:

1. If InFlight has already resolved **this** takeoff to a number, use that number. See the InFlight section. `InFlight:GetFlightTime()` returns the seconds for the flight its `TakeTaxiNode` wrapper just armed, including gossip via `StartMiscFlight`. It returns nil when InFlight has no time.
2. Else, if the suite table `EllesmereUI._FlightTimerRoutes` or the standalone table `EUICoreStandaloneForeverEssentials._FlightTimerRoutes` exists, and this takeoff has a taxi slot (not a gossip destination), sum hop yards and divide by speed. The suite is used when both are loaded.
3. If either hop yards or speed cannot be read safely, omit the parenthetical. `BuildMessage` already omits it when `GetFlightTime` is missing or not a positive number.

Nil-safe Ellesmere read, at the moment `TakeTaxiNode(slot)` runs, while the taxi map is still open. This mirrors `RouteInfo`. It is not a public API; it copies the key formula.

```lua
local function EllesmereSeconds(slot)
    local routes = EllesmereUI and EllesmereUI._FlightTimerRoutes
    local settings = EllesmereUIDB and EllesmereUIDB.flightTimer
    if not routes then
        local core = EUICoreStandaloneForeverEssentials
        if core and core._FlightTimerRoutes then
            routes = core._FlightTimerRoutes
            local db = EUICoreStandaloneForeverEssentialsDB
            settings = db and db.flightTimer
        end
    end
    if not routes or not GetNumRoutes or not C_TaxiMap or not GetTaxiMapID then
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
    local speed = settings and settings.speed or 30.4
    if type(speed) ~= "number" or speed <= 0 then
        return nil
    end
    local mult = 1
    if C_Traits and C_Traits.GetConfigIDByTreeID and C_Traits.GetNodeInfo then
        local configID = C_Traits.GetConfigIDByTreeID(1188)
        local node = configID and C_Traits.GetNodeInfo(configID, 110300)
        if node and (node.activeRank or 0) > 0 then
            mult = 1.2
        end
    end
    return yards / (speed * mult)
end
```

Name normalization: do not run `ShortenName` on this path. The keys are node ids from the open map.

Keep gossip flights on the InFlight string keys, or announce them with no time. Ellesmere cannot answer `"Stormwind City"` to `"Return"`.

`_FlightTimerRoutes` is an underscore internal. Any integration should treat a missing or reshaped table as "no time", not as a load error.

## InFlight, for comparison

Current source: [LudiusMaximus/InFlight](https://github.com/LudiusMaximus/InFlight) `310f5fa`. Authors in the TOC: TotalPackage, Deranjata, LudiusMaximus. License: MIT (`LICENSE`). Folder name: `InFlight`. Saved variable: `InFlightDB`. Global frame: `CreateFrame("Frame", "InFlight")`, so other addons see the global `InFlight`.

TOC interface numbers in this tree:

| File | Interface |
| --- | --- |
| `InFlight.toc` | 120007 |
| `InFlight_Classic.toc` | 11509 |
| `InFlight_BCC.toc` | 20506 |
| `InFlight_Mists.toc` | 50504 |

No `30401`, no `16001`, no Cata TOC, no Wrath TOC. `OptionalDeps: InFlight_Load, Immersion`. The file still calls `C_AddOns.IsAddOnLoaded` at load. Whether an older Wrath build of InFlight still uses names is outside this commit.

### What is actually stored

`InFlight.db` is AceDB over `InFlightDB`, with `InFlight.defaults` as defaults (`InFlight:LoadBulk`). Defaults supply routes the player has not flown. `InFlight.db.global` is therefore the merged table.

Taxi flights are keyed by **node id**, then **node id**, and the leaf is a **number of seconds** with speed boosts divided out:

```lua
taxiSrc = GetNodeID(i)          -- C_TaxiMap.GetAllTaxiNodes
taxiDst = GetNodeID(slot)
-- on landing:
InFlight.db.global[faction][taxiSrc][taxiDst] = newBaseTime
```

`faction` is `"FactionslessZones"` when `InFlight.noFactionsZoneNodes[taxiSrc]` is set (Shadowlands, Dragon Isles, Khaz Algar, filled at `PLAYER_ENTERING_WORLD` in `Converter.lua`). Otherwise it is `UnitFactionGroup("player")` (`"Alliance"` or `"Horde"`).

Each source entry also has a string field `name` (the shortened display name). Destination values are numbers. Example from `Defaults.lua` `InFlight.defaults.global`:

```lua
["Horde"] = {
  [10] = {
    ["name"] = "The Sepulcher",
    [11] = 112,
    [13] = 96,
  },
},
["FactionslessZones"] = {
  [2395] = {
    ["name"] = "Oribos",
    [2398] = 66,
  },
},
```

`112` and `66` are seconds. At read time InFlight multiplies by `KhazAlgarFlightMasterFactor(nodeID)` (`1.25` until achievement `40430` is complete, else `1`) and `RideLikeTheWindFactor()` (`0.8` when `LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_MISTS_OF_PANDARIA` and spell `117983` is known, else `1`). On Wrath and Forever both factors are `1` if those conditions are false. The stored number is still the unboosted base.

`ShortenName` still does `gsub(name, L["DestParse"], "")`, and `enUS` sets `L["DestParse"] = ", .+"`. That matches FlightAnnounce's strip. It is applied to the **display** name stored under `"name"`, not to the taxi lookup key. `Converter.lua` leaves the old name-to-id converter commented out under the heading "Convert names (old InFlight Classic) to IDs."

Gossip flights are the exception that still uses English name strings, under the faction table, not under `FactionslessZones`. `StartMiscFlight(src, dst)` sets `taxiSrc` and `taxiDst` to those strings. `Defaults.lua` marks them `-- Flightpath started by gossip option.` Alliance example:

```lua
["Stormwind City"] = {
  ["Return"] = 65,
},
["Amber Ledge"] = {
  ["Transitus Shield (Scenic Route)"] = 62,
},
```

Those destination strings are the full gossip names. They do not go through `ShortenName` because they contain no `", .+"`.

Era overlay: for `buildInterface < 40000`, `Defaults.lua` copies `global_classic`, then `global_tbc` when `>= 20000`, then `global_wrath` when `>= 30000`, on top of the post-Cataclysm id table. `global_wrath` is empty (`-- No Wrath Classic exports yet.`). Keys stay node ids.

`InFlightDB.version` separates saves: `"post-cata"`, `"wrath"`, `"tbc"`, or `"classic-era"`. That is a saved-variable generation tag, not a second key layout.

### FlightAnnounce's duration read

`BuildMessage` calls `InFlight:GetFlightTime()` when that method exists, and appends the parenthetical only when the result is a number greater than 0. It does not index `InFlight.db`.

The old read was:

```lua
local ttl = InFlight.db.global[faction][ShortenName(src)][ShortenName(dst)]
```

Against this InFlight source, that is a seconds read only for gossip rows whose source and dest are those English strings (`"Amber Ledge"` to `"Transitus Shield (Scenic Route)"`). A normal taxi source key is a node id. `"Orgrimmar"` does not occur as a key in `Defaults.lua`. The index is nil, and the next index errors. InFlight itself uses `dstNodes and dstNodes[taxiDst]`.

`InFlight:GetFlightTime()` returns the local `endTime` for the flight just started (seconds already multiplied by the two factors, or nil). InFlight sets that inside its `TakeTaxiNode` wrapper, and inside `StartMiscFlight`, before the flight begins. FlightAnnounce reads it later, when `UnitOnTaxi` becomes true. `InFlight:GetDestination()` returns the shortened destination name. Neither function accepts a from/to pair. Place names in the announcement still come from `TaxiNodeName` and the gossip table.

Direct taxi time is one number for the clicked destination, not a sum the caller has to build. `GetEstimatedTime(slot)` sums known hops when the direct pair is missing, and returns nil if any hop's node id cannot be resolved. That estimate is what InFlight uses internally. It is not exported.

## Where this was looked up

The flight-timer implementation is in the GitHub repo linked from the suite, `EllesmereGaming/EllesmereUI`, folder `EllesmereUIForeverEssentials`. The tree search that found it used the Git trees API on `main` (1068 paths). There is no second addon folder named `Ellesmere`. I did not unpack the CurseForge standalone zip, so this note describes the GitHub module that `.pkgmeta` publishes as `EllesmereUIForeverEssentials`, at the commits above. Wiki, Wago, and CurseForge descriptions were not used as evidence.

## Blockers

- Wrath `30401` cannot see Ellesmere's table. The suite failsafe blocks that interface, and Forever Essentials is camelot / `16001` only.
- Forever `16001` can see `EllesmereUI._FlightTimerRoutes` when both addons are enabled. The value is yards per direct hop, not seconds, and the key is `fromNodeID * 10000 + toNodeID`.
- No supported "time from A to B" function. The underscore table is documented as internal.
- Endpoint names are not enough. Multi-stop time is a sum of hop yards, and the node ids exist only while the taxi map can be queried.
- Gossip and scenic flights that FlightAnnounce special-cases are outside the table.
- The seconds figure is `yards / speed`, with a shared learned speed and a per-character 1.2 perk. It is an estimate, not a recorded duration.
- Copying the data file into FlightAnnounce fights the license and will go stale on the next Forever taxi build.
