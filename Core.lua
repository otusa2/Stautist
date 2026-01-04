-- Stautist Core - Phase 1 (Rev 3)
-- Client: 3.3.5a (WotLK)

local addonName, addonTable = ...

-- ============================================================================
-- 1. LIBRARIES & ADDON INITIALIZATION (MUST BE AT TOP)
-- ============================================================================

-- FAILSAFE: Check if Ace3 is loaded globally
if not LibStub then 
    print("|cffff0000Stautist Error:|r LibStub not found. Please install Ace3.")
    return 
end

local AceAddon = LibStub("AceAddon-3.0", true)
if not AceAddon then
    print("|cffff0000Stautist Error:|r AceAddon-3.0 not found. Enable 'Ace3'.")
    return
end

-- Initialize Object (MOVED TO TOP)
Stautist = AceAddon:NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceComm-3.0")



-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================

Stautist.VERSION = "0.204"

-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================

-- ===========================================================================



function Stautist:GetSortedList(rawTable)
    local sortedKeys = {}
    for k, v in pairs(rawTable) do table.insert(sortedKeys, k) end
    table.sort(sortedKeys, function(a, b) 
        if a == "All" then return true end
        if b == "All" then return false end
        local nameA = rawTable[a] or ""
        local nameB = rawTable[b] or ""
        return nameA < nameB 
    end)
    return sortedKeys
end

function Stautist:GetShortName(fullName)
    if not fullName then return nil end
    return string.match(fullName, "([^-]+)")
end




-- FAILSAFE: Ensure Class Icon Coords exist (3.3.5a fallback)
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
    ["WARRIOR"] = {0, 0.25, 0, 0.25}, ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25}, ["DRUID"] = {0.75, 1, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5}, ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5}, ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75}, ["DEATHKNIGHT"] = {0.25, 0.5, 0.5, 0.75},
}

local DB_VERSION = 1
local L = LibStub("AceLocale-3.0"):GetLocale("Stautist", true)
if not L then
    L = {
        ["ADDON_LOADED"] = "Stautist Engine Loaded. Type /stau for options.",
        ["DB_VERSION_MISMATCH"] = "Database version mismatch."
    }
end


-- FAILSAFE: Safe Class Color Lookup
function Stautist:SafeGetClassColor(class)
    if not class or type(class) ~= "string" then return {r=0.5, g=0.5, b=0.5} end
    local c = RAID_CLASS_COLORS[class:upper()]
    if c then return c end
    return {r=0.5, g=0.5, b=0.5} -- Grey fallback
end




-- FONT HELPER
local FONT_MAIN = "Interface\\AddOns\\Stautist\\Fonts\\PTSans.ttf"

local function ApplyFont(widget, size)
    if not widget then return end
    local s = size or 11
    
    if widget.type == "Label" or widget.type == "InteractiveLabel" then
        widget:SetFont(FONT_MAIN, s)
    elseif widget.type == "Button" then
        if widget.text then widget.text:SetFont(FONT_MAIN, s) end
    elseif widget.type == "CheckBox" then
        if widget.text then widget.text:SetFont(FONT_MAIN, s) end
    elseif widget.type == "Dropdown" then
        if widget.text then widget.text:SetFont(FONT_MAIN, s) end
        if widget.label then widget.label:SetFont(FONT_MAIN, s) end
    elseif widget.type == "Slider" then
        if widget.label then widget.label:SetFont(FONT_MAIN, s) end
        if widget.valtext then widget.valtext:SetFont(FONT_MAIN, s) end
        if widget.lowtext then widget.lowtext:SetFont(FONT_MAIN, s) end
        if widget.hightext then widget.hightext:SetFont(FONT_MAIN, s) end
    elseif widget.type == "InlineGroup" or widget.type == "TabGroup" then
        if widget.titletext then widget.titletext:SetFont(FONT_MAIN, s + 2) end
    end
end




-- ============================================================================
-- 2. STATIC POPUPS (Confirmations)
-- ============================================================================

StaticPopupDialogs["STAUTIST_EDIT_NOTE"] = {
    text = "Edit Note for %s:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 200,
    OnShow = function(self)
        -- Failsafe check for data
        local currentNote = (self.data and self.data.note) or ""
        self.editBox:SetText(currentNote)
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        if self.data and self.data.target then
            self.data.target.note = text 
            if self.data.callback then self.data.callback() end
            Stautist:Print("Note saved.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["STAUTIST_EDIT_NOTE"].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
}


StaticPopupDialogs["STAUTIST_RESET_1"] = {
    text = "This will clean ALL your data (Runs, History, Logs).\nThere is no coming back.",
    button1 = "Continue",
    button2 = "Cancel",
    OnAccept = function() StaticPopup_Show("STAUTIST_RESET_2") end,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["STAUTIST_RESET_2"] = {
    text = "|cffff0000WARNING:|r Are you sure you want to wipe your ENTIRE database?\n\nLast chance.",
    button1 = "WIPE IT",
    button2 = "Cancel",
    OnAccept = function() 
        Stautist.db:ResetDB("Default")
        ReloadUI()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["STAUTIST_DELETE_RUN"] = {
    text = "Are you sure you want to delete this run entry?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        local index = data
        if index and Stautist.db.global.run_history[index] then
            table.remove(Stautist.db.global.run_history, index)
            Stautist:RefreshLeaderboard()
            Stautist:Print("Run deleted.")
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["STAUTIST_RUN_ONGOING"] = {
    text = "Stautist: You left the instance while a run was active.",
    button1 = "Run Finished", -- OnAccept
    button2 = "Keep Active",  -- OnCancel (Safe default)
    button3 = "Abandon",      -- OnAlt (Destructive)
    
    OnAccept = function() 
        Stautist:StopRun(false, "Manual Stop") 
    end,
    
    OnCancel = function() 
        -- SAFE: Do nothing, just keep the data alive.
        Stautist:Print("Run kept active. Waiting for re-entry...")
        Stautist:ShowHUD()
    end,
    
    OnAlt = function() 
        -- DESTRUCTIVE: Only wipes if you explicitly click the 3rd button
        local state = Stautist.db.char.active_run_state
        state.is_running = false
        state.hud_forced = nil
        state.zone_id = nil 
        Stautist.debug_mode = false 
        
        Stautist:Print("Run Abandoned (Data discarded).")
        Stautist:UpdateHUDText("ABORTED")
        Stautist:HideHUD()
    end,
    
    timeout = 0, whileDead = true, hideOnEscape = true, 
    preferredIndex = 3,
}

StaticPopupDialogs["STAUTIST_RELOAD"] = {
    text = "Font changed. You need to reload the UI for changes to take effect.\nReload now?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["STAUTIST_SHOW_HUD"] = {
    text = "Stautist: Run Started.\nShow HUD for this run?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function() 
        Stautist.db.char.active_run_state.hud_forced = true
        Stautist:ShowHUD() 
    end,
    OnCancel = function()
        Stautist.db.char.active_run_state.hud_forced = false
        Stautist:HideHUD()
    end,
    timeout = 0, whileDead = true, hideOnEscape = false,
    preferredIndex = 3,
}

function Stautist:ShowRunOngoingPopup()
    -- 1. Cooldown Check (15 Seconds)
    -- Prevents the pulse checks from triggering multiple popups in a row
    if self.popup_cooldown and GetTime() < self.popup_cooldown then return end
    
    -- 2. Visibility Check
    -- If it's already on screen, don't try to show it again
    if StaticPopup_Visible("STAUTIST_RUN_ONGOING") then return end

    -- 3. Show Popup
    StaticPopup_Show("STAUTIST_RUN_ONGOING")
    
    -- 4. Set Cooldown
    self.popup_cooldown = GetTime() + 15
end

-- ============================================================================
-- 3. CORE LOGIC
-- ============================================================================

function Stautist:OnInitialize()
    -- Defined defaults
    local defaults = {
        global = {
            db_version = DB_VERSION,
            social_ledger = {}, 
            social_notes = {}, -- Persistent Player Notes
            run_history = {},
            guild_cache = {}, -- NEW: Stores guild PBs
            gold_log = {},
            -- instance_log removed from global
        },
        profile = {
            first_run = true,
            minimap = { hide = false },
            timer_pos = { a="CENTER", p="UIParent", x=0, y=200 },
            timer_scale = 1.0,
            hud_width = 240,
            config_scale = 1.0,
            font_title = "Interface\\AddOns\\Stautist\\Fonts\\Molard.ttf",
            font_general = "Interface\\AddOns\\Stautist\\Fonts\\CORPOREA.TTF",
            timer_locked = false,
            hud_behavior = "Show",
            announce_completion = true,
            announce_resets = true,
            announce_lockouts = true,
            show_splits = true,
            show_wipes = true,
            announce_fastest_kill = true,
        },
        char = {
            active_run_state = { is_running = false, wipes = 0, current_boss_count = 0 },
            saved_instances = {},
            instance_log = {}, -- MOVED HERE (Per Character)
            last_instance_name = nil, -- Tracking for re-entry
            reset_detected = false,   -- Tracking for reset
        }
    }

    -- Initialize DB
    self.db = LibStub("AceDB-3.0"):New("StautistDB", defaults, true)
    
    -- Set Global Font Variable for use across the addon
    self.FONT = self.db.profile.font
    
    -- Register Chat Command
    self:RegisterChatCommand("stau", "OnChatCommand")

    -- Load HUD
    if self.CreateHUD then
        self:CreateHUD()
    else
        print("|cffff0000Stautist Error:|r HUD.lua failed to load.")
    end
end

function Stautist:OnEnable()
    -- Schedule the Welcome Message (delayed for UI)
    self:ScheduleTimer("StartupSequence", 4)
    if self.SetupComm then self:SetupComm() end
end

function Stautist:CleanupInstanceLog()
    if not self.db.char.instance_log then self.db.char.instance_log = {} return end
    
    local now = time()
    local limit = 3600 -- 60 Minutes
    
    -- Iterate backwards to remove items safely
    for i = #self.db.char.instance_log, 1, -1 do
        local entry = self.db.char.instance_log[i]
        if not entry.time or (now - entry.time) > limit then
            table.remove(self.db.char.instance_log, i)
        end
    end
end

function Stautist:StartupSequence()
    -- CLEANUP: Wipe old instances immediately on login
    self:CleanupInstanceLog()
    print("|cffffd700[Stautist DEBUG] Delayed startup sequence initiated.|r")

    -- 1. Load Data
    if self.LoadBossDatabase and (not self.NPC_TO_ZONE or next(self.NPC_TO_ZONE) == nil) then
        print("[DEBUG] Data file seems loaded. Building NPC->Zone map...")
        self:LoadBossDatabase(true)
    else
        print("[DEBUG] NPC->Zone map already built or function is missing.")
    end

    -- 2. Start the Engine
    if self.SetupEngine then
        print("[DEBUG] Engine file seems loaded. Starting it now.")
        self:SetupEngine()
    else
        print("[DEBUG] CRITICAL FAILURE: SetupEngine function not found. Check Engine.lua.")
        return
    end

-- 4. Setup Wizard Check
    if self.db.profile.first_run then
        self.db.profile.first_run = false
        self:RunSetupWizard()
    end


-- 3. Print Welcome / Resume Message
    local state = self.db.char.active_run_state
    if state.is_running then
        self:Print("|cff00ff00[Resume]|r Active run detected (" .. (state.zone_name or "Unknown") .. "). Restoring UI...")
        -- Force an immediate check, bypassing the 2s delay usually found in OnEnterInstance
        if self.CheckZoneStatus then self:CheckZoneStatus() end
    else
        self:Print(L["ADDON_LOADED"] or "Stautist Engine Loaded.")
        local count = 0
        for _ in pairs(self.NPC_TO_ZONE or {}) do count = count + 1 end
        self:Print("Database ready. " .. count .. " NPCs mapped. Waiting for dungeon entry...")
    end
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

function Stautist:OnChatCommand(input)
    local cmd, arg = input:trim():match("^(%S+)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "" then
        self:OpenConfigWindow()
    elseif cmd == "help" then
        print("|cff00ff00Stautist Commands:|r")
        print("  /stau start - Force restart current run")
        print("  /stau stop - Stop current run")
        print("  /stau debug [zoneID] - Force START a test run")
        print("  /stau fakekill [ID] - Simulate a boss kill")
        print("  /stau resetdb - WIPE ALL DATA")
    elseif cmd == "start" then
        self:Print("Force restarting run...")
        local state = self.db.char.active_run_state
        state.is_running = false
        self:CheckZoneStatus()
    elseif cmd == "stop" then
        if self.StopRun then self:StopRun(false, "Manual") end
    elseif cmd == "show" then
        self.db.char.active_run_state.user_hidden_hud = false -- Clear flag
        self:ShowHUD()
    elseif cmd == "hide" then
        self.db.char.active_run_state.user_hidden_hud = true -- Set flag
        self:HideHUD()
    elseif cmd == "resethud" then
        self.db.profile.timer_pos = { a="CENTER", p="UIParent", x=0, y=200 }
        if self.hudFrame then
            self.hudFrame:ClearAllPoints()
            self.hudFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end
    elseif cmd == "id" then
        self:GetTargetID()
    elseif cmd == "zone" then
        local name, type, diff, diffName, maxPlayers = GetInstanceInfo()
        local real = GetRealZoneText()
        local sub = GetSubZoneText()
        
        self:Print("|cffffd700[Zone Debug Info]|r")
        self:Print("InstanceInfo Name: " .. (name or "nil"))
        self:Print("RealZoneText: " .. (real or "nil"))
        self:Print("SubZoneText: " .. (sub or "nil"))
        self:Print("Type: " .. (type or "nil"))
        
        local id = self.currentZoneID or "N/A"
        if id == "N/A" and self.db.char.active_run_state.zone_id then
            id = self.db.char.active_run_state.zone_id .. " (Saved)"
        end
        self:Print("Stautist Locked ID: " .. id)
    elseif cmd == "debug" then
            local zoneID = tonumber(arg) or 389 
            self:Print("|cffffff00[Debug Mode]|r Forcing run start for Zone ID: " .. zoneID)
            
            -- FAILSAFE: Inject Mock Data into Real DB so Engine doesn't crash
            if not self.BossDB[zoneID] then
                self:Print("Zone ID not found. Injecting Mock Data...")
                self.BossDB[zoneID] = {
                    name = "Debug Zone " .. zoneID,
                    tier = "Classic",
                    type = "dungeon", -- Needed for filters
                    textureID = nil,  -- Trigger fallback
                    bosses = {
                        [99901] = { name = "Test Boss A", order = 1 },
                        [99902] = { name = "Test Boss B", order = 2 },
                        [99903] = { name = "Test Boss C", order = 3 }
                    }
                }
                -- Add to Name Map so other lookups work
                if self.NAME_TO_ID then self.NAME_TO_ID["Debug Zone " .. zoneID] = zoneID end
            end

            self.currentZoneID = zoneID
            self.debug_mode = true 
            
            local state = self.db.char.active_run_state
            state.is_running = true
            state.zone_id = zoneID
            
            local zData = self.BossDB[zoneID]
            state.zone_name = zData.name
            state.difficulty = "Normal"
            state.start_time = GetTime()
            state.boss_kills = {}
            state.wipes = 0
            state.roster = self:GetRosterSnapshot()
            state.splits_invalid = false
            
            -- 1. PB LOOKUP (Crucial for Splits)
            state.pb_run_data = nil
            local bestTimeFound = nil
            local bestRun = nil
            
            if self.db.global.run_history then
                for _, run in pairs(self.db.global.run_history) do
                    if run.zone_id == zoneID and run.difficulty == "Normal" and run.success then
                        if not bestRun or run.total_time < bestRun.total_time then
                            bestRun = run
                        end
                    end
                end
            end

            if not bestRun then
                self:Print("|cff00ccff[Debug]|r No PB found. Generating Mock PB for testing...")
                bestRun = {
                    total_time = 300, 
                    boss_kills = {}
                }
                local count = 0
                for _ in pairs(zData.bosses) do count = count + 1 end
                local step = 300 / (count > 0 and count or 1)
                
                local tempBosses = {}
                for id, b in pairs(zData.bosses) do
                    local bOrder = (type(b)=="table" and b.order) or 50
                    table.insert(tempBosses, {id=id, order=bOrder})
                end
                table.sort(tempBosses, function(a,b) return a.order < b.order end)

                for i, b in ipairs(tempBosses) do
                    bestRun.boss_kills[b.id] = { split_time = step * i }
                end
            else
                self:Print("PB Loaded for Debug Splits: " .. self:FormatTime(bestRun.total_time))
            end

            state.pb_run_data = bestRun
            bestTimeFound = bestRun.total_time
            state.best_time_cache = bestTimeFound

            -- 2. BUILD HUD
            if self.ClearBossList then self:ClearBossList() end
            
            local bosses = {}
            for npcID, data in pairs(zData.bosses) do
                local bName = (type(data)=="table" and data.name or data)
                local bOrder = (type(data)=="table" and data.order or 50)
                table.insert(bosses, { id = npcID, name = bName, order = bOrder })
            end
            table.sort(bosses, function(a,b) return a.order < b.order end)

            for _, b in ipairs(bosses) do
                self:AddBossToList(b.id, b.name, b.order)
            end
            
            -- THIS LINE IS CRITICAL:
            if self.SortBossRows then self:SortBossRows() end

            self:UpdateHUDHeight()
            self:SetDungeonTitle(state.zone_name .. " (TEST)", false)
            
            if self.hudFrame then
                if self.hudFrame.timeToBeat then
                    local btText = bestTimeFound and self:FormatTime(bestTimeFound) or "--:--"
                    self.hudFrame.timeToBeat:SetText("PB: " .. btText)
                end
                if self.UpdateHUDWipes then self:UpdateHUDWipes(0) end
                if self.UpdateHUDLayout then self:UpdateHUDLayout() end
            end
            
            self:ShowHUD()
        elseif cmd == "fakekill" then
            local npcID = tonumber(arg)
            if npcID then
                if not self.db.char.active_run_state.is_running then
                    self:Print("No active run! Starting Debug Run...")
                    local zID = self.NPC_TO_ZONE and self.NPC_TO_ZONE[npcID] or 409
                    self:OnChatCommand("debug " .. zID)
                end

                local bName = "Unknown Boss"
                if self.currentZoneID and self.BossDB[self.currentZoneID] then
                    local bData = self.BossDB[self.currentZoneID].bosses[npcID]
                    bName = type(bData) == "table" and bData.name or bData
                end
                
                if self.AddBossToList then self:AddBossToList(npcID, bName) end
                if self.OnBossKill then self:OnBossKill(npcID, bName) end
            end
        elseif cmd == "resetdb" then
            self.db:ResetDB("Default")
            ReloadUI()
        end
    end




function Stautist:GetTargetID()
    local guid = UnitGUID("target")
    if not guid then self:Print("No target selected."); return end
    local id = tonumber(guid:sub(9, 12), 16)
    local name = UnitName("target")
    self:Print(string.format("Target: |cff00ff00%s|r | ID: |cffffcc00%d|r", name, id))
end

-- ============================================================================
-- CONFIGURATION GUI
-- ============================================================================

local UI_WIDTH = 850
local UI_HEIGHT = 650
local C_RED = {1, 0.2, 0.2, 1}
local C_DARK_RED = {0.6, 0.1, 0.1, 1}
local C_BLACK_50 = {0, 0, 0, 0.5} 
local C_BORDER = {1, 1, 1, 1} 

function Stautist:OpenConfigWindow()
    if self.ConfigFrame then
        if self.ConfigFrame:IsShown() then self.ConfigFrame:Hide() else self.ConfigFrame:Show(); self:SwitchTab("General") end
        return
    end

    local f = CreateFrame("Frame", "StautistConfigMain", UIParent)
    f:SetSize(UI_WIDTH, UI_HEIGHT)
    f:SetPoint("CENTER")
    f:SetScale(self.db.profile.config_scale or 1.0)
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnHide", function() Stautist:StopFakeSimulation() end)


    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(unpack(C_BLACK_50))
    f:SetBackdropBorderColor(unpack(C_BORDER))

    f.logo = f:CreateTexture(nil, "ARTWORK")
    f.logo:SetSize(256, 100) 
    f.logo:SetPoint("TOP", 0, -20)
    f.logo:SetTexture("Interface\\AddOns\\Stautist\\Textures\\logo.tga")
    f.logo:SetBlendMode("BLEND")
    
    f.verText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.verText:SetPoint("TOP", f.logo, "BOTTOM", 0, -5)
    f.verText:SetText("v" .. Stautist.VERSION)
    f.verText:SetTextColor(unpack(C_RED))
    f.verText:SetFont(FONT_MAIN, 10, "OUTLINE")

    self:CreateHeaderButton(f, "SETUP", "TOPLEFT", 20, -20, function() self:RunSetupWizard() end)
    self:CreateHeaderButton(f, "CLOSE", "TOPRIGHT", -20, -20, function() f:Hide() end)

    local tabY = -160
    self.tabButtons = {}
    local tabs = {"General", "Leaderboard", "Black Book", "Logs", "Guild"}
    local btnWidth = 120
    local gap = 5
    local totalTabWidth = (#tabs * btnWidth) + ((#tabs - 1) * gap)
    local startX = (UI_WIDTH - totalTabWidth) / 2

    for i, name in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(btnWidth, 30)
        btn:SetPoint("TOPLEFT", startX + ((i-1)*(btnWidth + gap)), tabY)
        
        -- RESTORED: Background Texture Creation
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        btn.bg:SetVertexColor(0.2, 0.2, 0.2, 1)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER")
        btn.text:SetText(name:upper())
        btn.text:SetTextColor(1, 1, 1)
        btn.text:SetFont(FONT_MAIN, 12) 
        
        btn:SetScript("OnClick", function() self:SwitchTab(name) end)
        
        -- Logic for Hover Effects
        btn:SetScript("OnEnter", function(s) 
            if s.bg then s.bg:SetVertexColor(1, 0.2, 0.2, 1) end -- Bright Red
        end)
        btn:SetScript("OnLeave", function(s)
            if not s.bg then return end
            if s.selected then
                s.bg:SetVertexColor(1, 0.2, 0.2, 1) -- Keep Red if selected
            else
                s.bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Revert to Grey
            end
        end)
        
        btn.tabName = name
        self.tabButtons[name] = btn
    end

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", 20, tabY - 40)
    f.content:SetPoint("BOTTOMRIGHT", -20, 20)
    
    local AceGUI = LibStub("AceGUI-3.0")
    f.aceContainer = AceGUI:Create("SimpleGroup")
    f.aceContainer:SetLayout("Fill")
    f.aceContainer.frame:SetParent(f.content)
    f.aceContainer.frame:SetAllPoints()
    f.aceContainer.frame:Show()

    self.ConfigFrame = f
    self:SwitchTab("General")
end

function Stautist:CreateHeaderButton(parent, text, point, x, y, script)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(80, 25)
    btn:SetPoint(point, x, y)
    
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    btn.bg:SetVertexColor(0.6, 0.1, 0.1, 1) -- Default Dark Red
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text)
    btn.text:SetFont(FONT_MAIN, 10, "BOLD")
    
    btn:SetScript("OnClick", script)
    -- HOVER EFFECTS
    btn:SetScript("OnEnter", function(s) s.bg:SetVertexColor(1, 0.2, 0.2, 1) end) -- Bright Red
    btn:SetScript("OnLeave", function(s) s.bg:SetVertexColor(0.6, 0.1, 0.1, 1) end) -- Back to Dark Red
    return btn
end

function Stautist:NavigateBack()
    print("Back button clicked - History navigation to be implemented.")
end

function Stautist:SwitchTab(tabName)
    for name, btn in pairs(self.tabButtons) do
        if name == tabName then
            btn.selected = true
            btn.bg:SetVertexColor(unpack(C_RED))
            btn.text:SetTextColor(1, 1, 1)
        else
            btn.selected = false
            btn.bg:SetVertexColor(0.2, 0.2, 0.2)
            btn.text:SetTextColor(1, 1, 1)
        end
    end

    self.ConfigFrame.aceContainer:ReleaseChildren()
    -- FAILSAFE: Clear references to old tab widgets so we don't update them later
    self.lb_dropZone = nil
    self.lb_scroll = nil
    
    if tabName == "General" then
        self:DrawGeneralContent(self.ConfigFrame.aceContainer)
    elseif tabName == "Leaderboard" then
        self:DrawLeaderboardContent(self.ConfigFrame.aceContainer)
    elseif tabName == "Black Book" then
        self:DrawSocialContent(self.ConfigFrame.aceContainer)
    elseif tabName == "Logs" then
        self:DrawLogsContent(self.ConfigFrame.aceContainer)
    elseif tabName == "Guild" then
        if self.DrawGuildContent then
            self:DrawGuildContent(self.ConfigFrame.aceContainer)
        else
            self:DrawPlaceholderContent(self.ConfigFrame.aceContainer, "Guild Module Error")
        end
    end
end

-- ============================================================================
-- CONTENT DRAWING
-- ============================================================================

function Stautist:DrawGeneralContent(container)
    container:SetLayout("Fill") 
    local AceGUI = LibStub("AceGUI-3.0")
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    container:AddChild(scroll)

    -- Helper to create a specific row container
    local function CreateRow()
        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        return row
    end

    -- ============================================================
    -- 1. VISUAL SETTINGS
    -- ============================================================
    local grpVis = AceGUI:Create("InlineGroup")
    grpVis:SetTitle("Visual Settings")
    grpVis:SetLayout("Flow")
    grpVis:SetFullWidth(true)
    ApplyFont(grpVis, 12)
    scroll:AddChild(grpVis)

    -- ROW 1: HUD Scale | HUD Width
    local row1 = CreateRow()
    grpVis:AddChild(row1)

    local sldHud = AceGUI:Create("Slider")
    sldHud:SetLabel("HUD Scale")
    sldHud:SetSliderValues(0.5, 2.0, 0.1)
    sldHud:SetValue(self.db.profile.timer_scale or 1.0)
    sldHud:SetRelativeWidth(0.48) -- 48% to leave gap
    sldHud:SetCallback("OnMouseUp", function(widget) 
        local val = widget:GetValue(); val = math.floor(val * 10 + 0.5) / 10 
        self.db.profile.timer_scale = val
        if self.hudFrame then self.hudFrame:SetScale(val) end
        
        -- Trigger Test Mode if not running
        if not self.db.char.active_run_state.is_running then
            self:StartFakeSimulation()
        end
    end)
    ApplyFont(sldHud)
    row1:AddChild(sldHud)

    local sldWidth = AceGUI:Create("Slider")
    sldWidth:SetLabel("HUD Base Width")
    sldWidth:SetSliderValues(200, 500, 10)
    sldWidth:SetValue(self.db.profile.hud_width or 240)
    sldWidth:SetRelativeWidth(0.48)
    sldWidth:SetCallback("OnMouseUp", function(widget)
        self.db.profile.hud_width = widget:GetValue()
        if self.UpdateHUDLayout then self:UpdateHUDLayout() end
        
        -- Trigger Test Mode
        if not self.db.char.active_run_state.is_running then
            self:StartFakeSimulation()
        end
    end)
    ApplyFont(sldWidth)
    row1:AddChild(sldWidth)

    -- ROW 2: Menu Scale | Behavior
    local row2 = CreateRow()
    grpVis:AddChild(row2)

    local sldUI = AceGUI:Create("Slider")
    sldUI:SetLabel("Menu Scale")
    sldUI:SetSliderValues(0.5, 2.0, 0.1)
    sldUI:SetValue(self.db.profile.config_scale or 1.0)
    sldUI:SetRelativeWidth(0.48)
    sldUI:SetCallback("OnMouseUp", function(widget)
        local val = widget:GetValue(); val = math.floor(val * 10 + 0.5) / 10
        self.db.profile.config_scale = val
        if self.ConfigFrame then self.ConfigFrame:SetScale(val) end
    end)
    ApplyFont(sldUI)
    row2:AddChild(sldUI)

    local dropBehav = AceGUI:Create("Dropdown")
    dropBehav:SetLabel("HUD Visibility Behavior")
    dropBehav:SetList({ ["Show"] = "Always Show", ["Ask"] = "Ask on Enter", ["Hide"] = "Always Hide" })
    dropBehav:SetValue(self.db.profile.hud_behavior or "Show")
    dropBehav:SetRelativeWidth(0.48)
    dropBehav:SetCallback("OnValueChanged", function(_, _, val)
        self.db.profile.hud_behavior = val
        if self.db.char.active_run_state.is_running then
            if val == "Show" then self:ShowHUD() elseif val == "Hide" then self:HideHUD() end
        end
    end)
    ApplyFont(dropBehav)
    row2:AddChild(dropBehav)

    -- ROW 3: Lock | Reset
    local row3 = CreateRow()
    grpVis:AddChild(row3)

    local chkLock = AceGUI:Create("CheckBox")
    chkLock:SetLabel("Lock HUD Position")
    chkLock:SetRelativeWidth(0.48)
    chkLock:SetValue(self.db.profile.timer_locked)
    chkLock:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.timer_locked = value
        if self.hudFrame then self.hudFrame:EnableMouse(not value) end
    end)
    ApplyFont(chkLock)
    row3:AddChild(chkLock)

    local btnResetHUD = AceGUI:Create("Button")
    btnResetHUD:SetText("Reset HUD Position")
    btnResetHUD:SetRelativeWidth(0.48)
    btnResetHUD:SetCallback("OnClick", function() Stautist:OnChatCommand("resethud") end)
    ApplyFont(btnResetHUD)
    row3:AddChild(btnResetHUD)

    -- ROW 4: Splits | Wipes
    local row4 = CreateRow()
    grpVis:AddChild(row4)

    local chkSplits = AceGUI:Create("CheckBox")
    chkSplits:SetLabel("Show Split Timers (+/-)")
    chkSplits:SetValue(self.db.profile.show_splits)
    chkSplits:SetRelativeWidth(0.48)
    chkSplits:SetCallback("OnValueChanged", function(_, _, value) 
        self.db.profile.show_splits = value; if self.UpdateHUDLayout then self:UpdateHUDLayout() end 
    end)
    ApplyFont(chkSplits)
    row4:AddChild(chkSplits)

    local chkWipes = AceGUI:Create("CheckBox")
    chkWipes:SetLabel("Show Wipe Counter")
    chkWipes:SetValue(self.db.profile.show_wipes)
    chkWipes:SetRelativeWidth(0.48)
    chkWipes:SetCallback("OnValueChanged", function(_, _, value) 
        self.db.profile.show_wipes = value; if self.UpdateHUDLayout then self:UpdateHUDLayout() end 
    end)
    ApplyFont(chkWipes)
    row4:AddChild(chkWipes)

    -- ============================================================
    -- 2. FONT SETTINGS
    -- ============================================================
    local grpFonts = AceGUI:Create("InlineGroup")
    grpFonts:SetTitle("Font Settings (Requires Reload)")
    grpFonts:SetLayout("Flow")
    grpFonts:SetFullWidth(true)
    ApplyFont(grpFonts, 12)
    scroll:AddChild(grpFonts)

    local fontList = {
        ["Interface\\AddOns\\Stautist\\Fonts\\Molard.ttf"] = "Molard (Custom Title)",
        ["Interface\\AddOns\\Stautist\\Fonts\\CORPOREA.TTF"] = "Corporea (Custom Main)",
        ["Fonts\\ARIALN.TTF"] = "Standard (Arial)",
        ["Fonts\\FRIZQT__.TTF"] = "Warcraft (Friz)",
        ["Fonts\\MORPHEUS.TTF"] = "RPG (Morpheus)",
        ["Fonts\\SKURRI.TTF"] = "Combat (Skurri)",
    }

    local dropTitleFont = AceGUI:Create("Dropdown")
    dropTitleFont:SetLabel("Dungeon Title Font")
    dropTitleFont:SetList(fontList)
    dropTitleFont:SetValue(self.db.profile.font_title)
    dropTitleFont:SetRelativeWidth(0.48)
    dropTitleFont:SetCallback("OnValueChanged", function(_, _, val)
        if val ~= self.db.profile.font_title then
            self.db.profile.font_title = val
            StaticPopup_Show("STAUTIST_RELOAD")
        end
    end)
    ApplyFont(dropTitleFont)
    grpFonts:AddChild(dropTitleFont)

    local dropGenFont = AceGUI:Create("Dropdown")
    dropGenFont:SetLabel("Boss & Timer Font")
    dropGenFont:SetList(fontList)
    dropGenFont:SetValue(self.db.profile.font_general)
    dropGenFont:SetRelativeWidth(0.48)
    dropGenFont:SetCallback("OnValueChanged", function(_, _, val)
        if val ~= self.db.profile.font_general then
            self.db.profile.font_general = val
            StaticPopup_Show("STAUTIST_RELOAD")
        end
    end)
    ApplyFont(dropGenFont)
    grpFonts:AddChild(dropGenFont)

    -- ============================================================
    -- 3. AUTOMATION
    -- ============================================================
    local grpAuto = AceGUI:Create("InlineGroup")
    grpAuto:SetTitle("Automation")
    grpAuto:SetLayout("Flow")
    grpAuto:SetFullWidth(true)
    ApplyFont(grpAuto, 12)
    scroll:AddChild(grpAuto)

    local function AddAutoCheck(label, key)
        local c = AceGUI:Create("CheckBox")
        c:SetLabel(label)
        c:SetRelativeWidth(0.48)
        c:SetValue(self.db.profile[key])
        c:SetCallback("OnValueChanged", function(_, _, value) self.db.profile[key] = value end)
        ApplyFont(c)
        grpAuto:AddChild(c)
    end

    AddAutoCheck("Announce 5/Hour Limit", "announce_lockouts")
    AddAutoCheck("Announce Instance Resets", "announce_resets")
    AddAutoCheck("Announce Run Completion", "announce_completion")
    AddAutoCheck("Announce Fastest Kills (PB)", "announce_fastest_kill")

    -- ============================================================
    -- 4. DATA MANAGEMENT
    -- ============================================================
    local grpData = AceGUI:Create("InlineGroup")
    grpData:SetTitle("Data Management")
    grpData:SetLayout("Flow")
    grpData:SetFullWidth(true)
    ApplyFont(grpData, 12)
    scroll:AddChild(grpData)

    local btnExport = AceGUI:Create("Button")
    btnExport:SetText("Export Data")
    btnExport:SetRelativeWidth(0.32)
    btnExport:SetCallback("OnClick", function() self:ShowExportImportWindow("EXPORT") end)
    ApplyFont(btnExport)
    grpData:AddChild(btnExport)

    local btnImport = AceGUI:Create("Button")
    btnImport:SetText("Import Data")
    btnImport:SetRelativeWidth(0.32)
    btnImport:SetCallback("OnClick", function() self:ShowExportImportWindow("IMPORT") end)
    ApplyFont(btnImport)
    grpData:AddChild(btnImport)

    local btnWipe = AceGUI:Create("Button")
    btnWipe:SetText("Wipe dB") 
    btnWipe:SetRelativeWidth(0.32)
    btnWipe:SetCallback("OnClick", function() StaticPopup_Show("STAUTIST_RESET_1") end)
    ApplyFont(btnWipe)
    grpData:AddChild(btnWipe)
end
-- ============================================================================
-- LEADERBOARD TAB
-- ============================================================================

function Stautist:DrawLeaderboardContent(container)
    local AceGUI = LibStub("AceGUI-3.0")
    container:SetLayout("Flow")

    self.lb_filters = self.lb_filters or {
        expansion = "All", type = "All", zone = "All", difficulty = "All", size = "All", show_partial = false
    }

   -- Filter Container (Table Layout - Aggressive Minimums)
    local headerGrp = AceGUI:Create("SimpleGroup")
    headerGrp:SetLayout("Table")
    headerGrp:SetUserData("table", {
        columns = {
            {width = 70},              -- 1. Checkbox (Fixed)
            {weight = 1, min = 125},   -- 2. Expansion (Widened)
            {weight = 1, min = 115},   -- 3. Type (Widened)
            {weight = 1, min = 115},   -- 4. Difficulty (Widened)
            {weight = 0.5, min = 70},  -- 5. Size (Fixed small but visible)
            {weight = 2, min = 250},   -- 6. Zone (Massively Widened)
        },
        space = 10,
        align = "BOTTOM"
    })
    headerGrp:SetFullWidth(true)
    container:AddChild(headerGrp)

    -- 1. Checkbox
    local chkPartial = AceGUI:Create("CheckBox")
    chkPartial:SetLabel("Partial")
    chkPartial:SetValue(self.lb_filters.show_partial)
    chkPartial:SetCallback("OnValueChanged", function(_, _, val)
        self.lb_filters.show_partial = val; self:RefreshLeaderboard()
    end)
    ApplyFont(chkPartial)
    headerGrp:AddChild(chkPartial)

    -- 2. Expansion
    local dropExp = AceGUI:Create("Dropdown")
    dropExp:SetLabel("Expansion")
    dropExp:SetList({ ["All"]="Show All", ["Classic"]="Classic", ["TBC"]="TBC", ["WotLK"]="WotLK" })
    dropExp:SetValue(self.lb_filters.expansion)
    dropExp:SetCallback("OnValueChanged", function(_, _, val) 
        self.lb_filters.expansion = val; self.lb_filters.zone = "All"; self:RefreshLeaderboard() 
    end)
    ApplyFont(dropExp)
    headerGrp:AddChild(dropExp)

    -- 3. Type
    local dropType = AceGUI:Create("Dropdown")
    dropType:SetLabel("Type")
    dropType:SetList({ ["All"]="All", ["dungeon"]="Dungeon", ["raid"]="Raid" })
    dropType:SetValue(self.lb_filters.type)
    dropType:SetCallback("OnValueChanged", function(_, _, val) 
        self.lb_filters.type = val; self.lb_filters.zone = "All"; self:RefreshLeaderboard() 
    end)
    ApplyFont(dropType)
    headerGrp:AddChild(dropType)

    -- 4. Difficulty
    local dropDiff = AceGUI:Create("Dropdown")
    dropDiff:SetLabel("Difficulty")
    dropDiff:SetList({ ["All"]="All", ["Normal"]="Normal", ["Heroic"]="Heroic" })
    dropDiff:SetValue(self.lb_filters.difficulty)
    dropDiff:SetCallback("OnValueChanged", function(_, _, val)
        self.lb_filters.difficulty = val; self:RefreshLeaderboard()
    end)
    ApplyFont(dropDiff)
    headerGrp:AddChild(dropDiff)

    -- 5. Size
    local dropSize = AceGUI:Create("Dropdown")
    dropSize:SetLabel("Size")
    dropSize:SetList({ ["All"]="All", ["5"]="5", ["10"]="10", ["25"]="25", ["40"]="40" })
    dropSize:SetValue(self.lb_filters.size or "All")
    dropSize:SetCallback("OnValueChanged", function(_, _, val)
        self.lb_filters.size = val; self:RefreshLeaderboard()
    end)
    ApplyFont(dropSize)
    headerGrp:AddChild(dropSize)

    -- 6. Zone
    local zoneList = {["All"] = "All Zones"}
    if self.BossDB then
        for id, data in pairs(self.BossDB) do
            local tierMatch = (self.lb_filters.expansion == "All" or data.tier == self.lb_filters.expansion)
            local typeMatch = (self.lb_filters.type == "All" or data.type == self.lb_filters.type)
            if tierMatch and typeMatch then zoneList[id] = data.name end
        end
    end
    local dropZone = AceGUI:Create("Dropdown")
    dropZone:SetLabel("Zone")
    local sortedZoneIDs = self:GetSortedList(zoneList)
    dropZone:SetList(zoneList, sortedZoneIDs)
    dropZone:SetValue(self.lb_filters.zone)
    dropZone:SetCallback("OnValueChanged", function(_, _, val) 
        self.lb_filters.zone = val; self:RefreshLeaderboard() 
    end)
    self.lb_dropZone = dropZone 
    ApplyFont(dropZone)
    headerGrp:AddChild(dropZone)







    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetHeight(350) 
    container:AddChild(scroll)
    
    self.lb_scroll = scroll 
    self:RefreshLeaderboard()
end

function Stautist:RefreshLeaderboard()
    if not self.lb_scroll then return end
    self.lb_scroll:ReleaseChildren()
    local AceGUI = LibStub("AceGUI-3.0")

    if self.lb_dropZone and self.BossDB then
    local newList = {["All"] = "All Zones"}
    for id, data in pairs(self.BossDB) do
        local tierMatch = (self.lb_filters.expansion == "All" or data.tier == self.lb_filters.expansion)
        local typeMatch = (self.lb_filters.type == "All" or data.type == self.lb_filters.type)
        
        if tierMatch and typeMatch then
            newList[id] = data.name
        end
    end
    
    -- FIX: Re-sort the keys before calling SetList
    local sortedKeys = self:GetSortedList(newList)
    self.lb_dropZone:SetList(newList, sortedKeys)
    
    if self.lb_filters.zone ~= "All" and not newList[self.lb_filters.zone] then 
        self.lb_filters.zone = "All" 
        self.lb_dropZone:SetValue("All")
    end
end

    local runs = {}
    local history = self.db.global.run_history or {}
    
    print("|cff00ccff[Stautist DB]|r Total History: " .. #history)
    
    for i, run in ipairs(history) do
        run.original_index = i 
        
        local isValid = true
        
        if not run.zone_id then 
            print("Dropped Run #"..i..": No Zone ID")
            isValid = false 
        else
            local zData = self.BossDB[run.zone_id]
            if zData then
                if self.lb_filters.expansion ~= "All" and zData.tier ~= self.lb_filters.expansion then isValid = false end
                if self.lb_filters.type ~= "All" and zData.type ~= self.lb_filters.type then isValid = false end
            end
            
            if self.lb_filters.difficulty ~= "All" then
                local runDiff = run.difficulty or "Normal"
                if runDiff ~= self.lb_filters.difficulty then isValid = false end
            end
            if self.lb_filters.size and self.lb_filters.size ~= "All" then
                -- Convert to string for comparison
                local rSize = tostring(run.size or "5") -- Default old runs to 5 or ignore?
                if rSize ~= self.lb_filters.size then isValid = false end
            end
            if self.lb_filters.zone ~= "All" and run.zone_id ~= self.lb_filters.zone then isValid = false end
        end
        if not run.success and not self.lb_filters.show_partial then
            isValid = false
        end
        if isValid then
            table.insert(runs, run)
        end
    end

    print("|cff00ccff[Stautist DB]|r Runs after filter: " .. #runs)

    table.sort(runs, function(a, b) 
        local tA = a.total_time or 999999
        local tB = b.total_time or 999999
        return tA < tB 
    end)

    if #runs == 0 then
        local lbl = AceGUI:Create("Label")
        lbl:SetText("\n\nNo runs found matching filters.")
        lbl:SetColor(0.5, 0.5, 0.5)
        lbl:SetFullWidth(true)
        lbl:SetJustifyH("CENTER")
        self.lb_scroll:AddChild(lbl)
    else
        for i, run in ipairs(runs) do
            local status, err = pcall(function() self:CreateLeaderboardRow(self.lb_scroll, i, run) end)
            if not status then print("|cffff0000[Error Drawing Row]:|r " .. err) end
        end
    end
end

function Stautist:CreateLeaderboardRow(container, rank, run)
    local AceGUI = LibStub("AceGUI-3.0")
    local ICONS = {
        ["WARRIOR"] = {0, 0.25, 0, 0.25}, ["MAGE"] = {0.25, 0.5, 0, 0.25},
        ["ROGUE"] = {0.5, 0.75, 0, 0.25}, ["DRUID"] = {0.75, 1, 0, 0.25},
        ["HUNTER"] = {0, 0.25, 0.25, 0.5}, ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
        ["PRIEST"] = {0.5, 0.75, 0.25, 0.5}, ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
        ["PALADIN"] = {0, 0.25, 0.5, 0.75}, ["DEATHKNIGHT"] = {0.25, 0.5, 0.5, 0.75},
    }
    local CLASS_ORDER = {"WARRIOR", "PALADIN", "DEATHKNIGHT", "SHAMAN", "HUNTER", "DRUID", "ROGUE", "MAGE", "WARLOCK", "PRIEST"}

    local grp = AceGUI:Create("SimpleGroup")
    grp:SetLayout("Flow")
    grp:SetFullWidth(true)

    -- DATA PREPARATION
    local zName = "Unknown Zone"
    if run.zone_id and self.BossDB[run.zone_id] then 
        zName = self.BossDB[run.zone_id].name 
    end
    
    local displayName = zName
    
    -- Add Heroic Skull Icon
    if run.difficulty == "Heroic" then
        displayName = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12|t " .. displayName
    end
    
    if run.partial then displayName = displayName .. " |cffffcc00*|r" end 

    -- TOOLTIP FUNCTION (UPDATED)
    local function ShowTooltip(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
        GameTooltip:AddLine(zName, 1, 1, 1) -- Header
        
        -- Basic Stats
        local wipes = run.wipes or 0
        local wipeColor = (wipes > 0) and "|cffff0000" or "|cff888888"
        GameTooltip:AddLine(string.format("Time: %s   Wipes: %s%d", self:FormatTime(run.total_time, true), wipeColor, wipes), 1, 1, 1)

        -- Status
        if run.partial then
            GameTooltip:AddLine("Progress: " .. (run.progress or "?/?") .. " (Partial)", 1, 0.8, 0)
        else
            -- Check if actually 100%
            local k, t = strsplit("/", run.progress or "0/0")
            if k == t then
                GameTooltip:AddLine("Status: Full Clear", 0, 1, 0)
            else
                GameTooltip:AddLine("Status: Clear (Skipped "..(tonumber(t)-tonumber(k))..")", 1, 1, 0)
            end
        end
        GameTooltip:AddLine("Tier: " .. (run.tier or "Classic"), 0.6, 0.6, 0.6)

        -- BOSS KILLS & SPLITS (NEW)
        if run.boss_kills then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Boss Splits & Kills:", 1, 0.8, 0)
            
            -- Sort Bosses by Time (Split Time)
            local sortedBosses = {}
            for id, data in pairs(run.boss_kills) do
                table.insert(sortedBosses, data)
            end
            table.sort(sortedBosses, function(a,b) return (a.split_time or 0) < (b.split_time or 0) end)

            for _, b in ipairs(sortedBosses) do
                local bName = b.name or "Unknown"
                local sTime = self:FormatTime(b.split_time, true) -- Split (Run time)
                local kTime = self:FormatTime(b.duration, true)   -- Duration (Kill time)
                
                -- Format: BossName   Split   (KillTime)
                -- Using double columns logic for tooltip is hard, so we use spacing
                GameTooltip:AddDoubleLine(bName, string.format("|cffffffff%s|r (|cff00ff00%s|r)", sTime, kTime))
            end
        end
        -- NOTE DISPLAY
        if run.note and run.note ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Note: " .. run.note, 1, 0.82, 0, true) -- Wrap text
        end
        GameTooltip:Show()
    end
    local function HideTooltip() GameTooltip:Hide() end

    -- 1. SPACER
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetWidth(30)
    grp:AddChild(spacer)

    -- 2. RANK (Interactive)
    local lblRank = AceGUI:Create("InteractiveLabel")
    lblRank:SetText(tostring(rank) .. ".")
    lblRank:SetWidth(40)
    lblRank:SetColor(1, 0.8, 0)
    lblRank:SetCallback("OnEnter", ShowTooltip)
    lblRank:SetCallback("OnLeave", HideTooltip)
    grp:AddChild(lblRank)

    -- 3. ZONE NAME (Interactive)
    local lblZone = AceGUI:Create("InteractiveLabel")
    lblZone:SetText(displayName)
    lblZone:SetWidth(240)
    lblZone:SetColor(1, 1, 1)
    lblZone:SetCallback("OnEnter", ShowTooltip)
    lblZone:SetCallback("OnLeave", HideTooltip)
    grp:AddChild(lblZone)

    -- 4. TIME (Interactive)
    local lblTime = AceGUI:Create("InteractiveLabel")
    lblTime:SetText(self:FormatTime(run.total_time))
    lblTime:SetWidth(90)
    lblTime:SetColor(0, 1, 0)
    lblTime:SetCallback("OnEnter", ShowTooltip)
    lblTime:SetCallback("OnLeave", HideTooltip)
    grp:AddChild(lblTime)

    -- 5. ROSTER ICONS (UPDATED WITH LEVELS)
    local iconContainer = AceGUI:Create("SimpleGroup")
    iconContainer:SetWidth(250)
    iconContainer:SetLayout("Flow")
    grp:AddChild(iconContainer)

    if run.roster and #run.roster > 0 then
        local counts = {}
        local names = {}
        for _, player in ipairs(run.roster) do
            local cls = "PRIEST"
            if player.class and type(player.class) == "string" then
                cls = player.class:upper():gsub("%s+", "")
            end
            counts[cls] = (counts[cls] or 0) + 1
            if not names[cls] then names[cls] = "" end
            
            -- LEVEL DISPLAY ADDED HERE
            local lvlStr = player.level and (" (Lvl " .. player.level .. ")") or ""
            names[cls] = names[cls] .. player.name .. lvlStr .. "\n"
        end

        for _, cls in ipairs(CLASS_ORDER) do
            if counts[cls] and counts[cls] > 0 then
                -- 1. Create the Icon
                local icon = AceGUI:Create("Icon")
                icon:SetImageSize(16, 16)
                icon:SetWidth(20) -- Keep it tight
                local coords = ICONS[cls]
                if coords then
                    icon:SetImage("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", 
                        coords[1], coords[2], coords[3], coords[4])
                else
                    icon:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                
                -- Tooltip Logic
                icon:SetCallback("OnEnter", function(widget)
                    GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
                    GameTooltip:AddLine(names[cls], 1, 1, 1)
                    GameTooltip:Show()
                end)
                icon:SetCallback("OnLeave", HideTooltip)
                
                iconContainer:AddChild(icon)
                
                -- 2. If count > 1, add a separate Label NEXT to it
                if counts[cls] > 1 then
                    local countLbl = AceGUI:Create("Label")
                    countLbl:SetText(tostring(counts[cls]))
                    countLbl:SetWidth(10) -- Small width to stay inline
                    countLbl:SetColor(1, 1, 1)
                    
                    -- Apply Font Helper if available, else standard
                    if ApplyFont then ApplyFont(countLbl, 10) end
                    
                    iconContainer:AddChild(countLbl)
                end
            end
        end
    else
        local noData = AceGUI:Create("Label")
        noData:SetText("-")
        noData:SetWidth(20)
        iconContainer:AddChild(noData)
    end

    -- 6. DATE (Interactive)
    local lblDate = AceGUI:Create("InteractiveLabel")
    lblDate:SetText(run.date or "N/A")
    lblDate:SetWidth(100)
    lblDate:SetColor(0.6, 0.6, 0.6)
    lblDate:SetCallback("OnEnter", ShowTooltip)
    lblDate:SetCallback("OnLeave", HideTooltip)
    grp:AddChild(lblDate)

    -- 6.5 NOTE BUTTON
    local btnNote = AceGUI:Create("Icon")
    btnNote:SetImage("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btnNote:SetImageSize(16, 16)
    btnNote:SetWidth(20)
    btnNote:SetCallback("OnClick", function()
        local data = { target = run, note = run.note, callback = function() self:RefreshLeaderboard() end }
        -- OLD: StaticPopup_Show("STAUTIST_EDIT_NOTE", "Run #"..rank, data)
        -- NEW: Pass nil as 3rd arg
        StaticPopup_Show("STAUTIST_EDIT_NOTE", "Run #"..rank, nil, data)
    end)
    btnNote:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
        GameTooltip:AddLine("Edit Note", 1, 1, 1)
        if run.note then GameTooltip:AddLine(run.note, 1, 0.8, 0, true) end
        GameTooltip:Show()
    end)
    btnNote:SetCallback("OnLeave", HideTooltip)
    grp:AddChild(btnNote)

    -- 7. DELETE BUTTON
    local btnDel = AceGUI:Create("Icon")
    btnDel:SetImage("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    btnDel:SetImageSize(16, 16)
    btnDel:SetWidth(20)
    btnDel:SetCallback("OnClick", function()
        if run.original_index then
            StaticPopup_Show("STAUTIST_DELETE_RUN", nil, nil, run.original_index)
        end
    end)
    btnDel:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
        GameTooltip:AddLine("Delete Entry", 1, 0.2, 0.2)
        GameTooltip:Show()
    end)
    btnDel:SetCallback("OnLeave", HideTooltip)

    grp:AddChild(btnDel)
    
    container:AddChild(grp)
end

-- ============================================================================
-- SOCIAL LEDGER (Black Book)
-- ============================================================================

function Stautist:DrawSocialContent(container)
    container:SetLayout("Flow")
    
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- 1. HEADER (Search Box)
    local header = AceGUI:Create("SimpleGroup")
    header:SetFullWidth(true)
    header:SetLayout("Flow")
    container:AddChild(header)

    -- Centering Spacers
    local sp1 = AceGUI:Create("Label"); sp1:SetText(" "); sp1:SetRelativeWidth(0.25); header:AddChild(sp1)

    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetLabel("Search Player")
    searchBox:SetRelativeWidth(0.50)
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(widget, _, text)
        self:RefreshSocialList(self.socialScroll, text)
    end)
    -- Apply Font if helper exists
    if ApplyFont then ApplyFont(searchBox) end
    header:AddChild(searchBox)
    
    local sp2 = AceGUI:Create("Label"); sp2:SetText(" "); sp2:SetRelativeWidth(0.25); header:AddChild(sp2)

    -- 2. SCROLL FRAME (The List)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow") -- Essential for Grid
    scroll:SetFullWidth(true)
    
    -- CRITICAL FIX: Reduced height to prevent overflow
    -- Window Height (650) - Top Tabs/Header (~230) - Padding (20) = ~400
    scroll:SetHeight(400) 
    
    container:AddChild(scroll)
    self.socialScroll = scroll

    -- 3. DATA PREP
    self.socialDB = {}
    local history = self.db.global.run_history or {}
    for _, run in ipairs(history) do
        if run.roster then
            for _, char in ipairs(run.roster) do
                if char.name ~= UnitName("player") then
                    if not self.socialDB[char.name] then
                        self.socialDB[char.name] = {
                            name = char.name, class = char.class, runs = 0, history = {}
                        }
                    end
                    local p = self.socialDB[char.name]
                    p.runs = p.runs + 1
                    table.insert(p.history, run)
                end
            end
        end
    end

    self:RefreshSocialList(scroll, "")
end

function Stautist:RefreshSocialList(container, filter)
    container:ReleaseChildren()
    local AceGUI = LibStub("AceGUI-3.0")
    
    local list = {}
    for _, data in pairs(self.socialDB or {}) do table.insert(list, data) end
    
    -- Sort by Runs (Descending)
    table.sort(list, function(a,b) return a.runs > b.runs end)

    for _, pData in ipairs(list) do
        if filter == "" or string.find(string.lower(pData.name), string.lower(filter)) then
            
            -- CARD CONTAINER (Grid Item)
            local card = AceGUI:Create("SimpleGroup")
            card:SetLayout("Flow")
            -- 0.24 width allows 4 items per row (4 * 24% = 96%) with space for scrollbar
            card:SetRelativeWidth(0.24) 
            
            -- 1. CLASS ICON
            local icon = AceGUI:Create("Icon")
            icon:SetImageSize(18, 18)
            icon:SetWidth(24) -- Tight width
            local coords = CLASS_ICON_TCOORDS[pData.class:upper()] or {0,1,0,1}
            icon:SetImage("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", unpack(coords))
            card:AddChild(icon)

            -- 2. TEXT (Name & Runs)
            local lbl = AceGUI:Create("InteractiveLabel")
            local color = self:SafeGetClassColor(pData.class)
            local nameHex = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
            
            -- Format: Name (Colored) \n Runs: X (Grey)
            lbl:SetText(nameHex .. pData.name .. "|r\n|cff888888Runs: " .. pData.runs .. "|r")
            
            -- Fixed width to fit within the 1/4th column. 
            -- Total width ~210px. Icon takes 24px. 160px is safe.
            lbl:SetWidth(160) 
            lbl:SetFont(self.FONT or "Fonts\\ARIALN.TTF", 11)
            
            -- 3. INTERACTIONS
            lbl:SetCallback("OnClick", function() self:ShowPlayerDetails(pData) end)
            
            lbl:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
                GameTooltip:AddLine(pData.name, color.r, color.g, color.b)
                
                -- [NEW] Display Note if exists
                local note = self.db.global.social_notes[pData.name]
                if note and note ~= "" then
                    GameTooltip:AddLine("Note: " .. note, 1, 0.82, 0, true) -- Gold color, wrapping enabled
                end

                GameTooltip:AddLine("Total Runs: " .. pData.runs, 1, 1, 1)
                
                -- Mini History
                GameTooltip:AddLine(" ")
                for i = 1, math.min(3, #pData.history) do
                    local r = pData.history[i]
                    local zName = (self.BossDB[r.zone_id] and self.BossDB[r.zone_id].name) or "Unknown"
                    local wipeTxt = (r.wipes and r.wipes > 0) and (" |cffff0000("..r.wipes.." Wipes)|r") or ""
                    GameTooltip:AddLine(string.format("%s: %s%s", zName, self:FormatTime(r.total_time), wipeTxt), 0.7, 0.7, 0.7)
                end
                GameTooltip:AddLine("Click for details", 0, 1, 0)
                GameTooltip:Show()
            end)
            lbl:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            
            card:AddChild(lbl)
            container:AddChild(card)
        end
    end
end

function Stautist:ShowPlayerDetails(pData)
    local AceGUI = LibStub("AceGUI-3.0")
    local f = AceGUI:Create("Frame")
    
    -- Class Color Title
    local color = self:SafeGetClassColor(pData.class)
    local hex = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
    f:SetTitle("Details: " .. hex .. pData.name .. "|r")
    
    f:SetLayout("Flow")
    f:SetWidth(450); f:SetHeight(500) -- Widened slightly for better text fit
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow"); scroll:SetFullWidth(true); scroll:SetHeight(420)
    -- PLAYER NOTE EDITOR
    local noteGrp = AceGUI:Create("SimpleGroup")
    noteGrp:SetLayout("Flow"); noteGrp:SetFullWidth(true)
    
    local editNote = AceGUI:Create("MultiLineEditBox")
    editNote:SetLabel("Player Note")
    editNote:SetNumLines(3)
    editNote:SetFullWidth(true)
    
    -- Load existing note
    local existingNote = self.db.global.social_notes[pData.name] or ""
    editNote:SetText(existingNote)
    
    -- Save on Enter/Loss of Focus
    local function SaveNote(widget)
        local txt = widget:GetText()
        if txt and txt ~= "" then
            self.db.global.social_notes[pData.name] = txt
        else
            self.db.global.social_notes[pData.name] = nil
        end
    end
    
    editNote:SetCallback("OnEnterPressed", SaveNote)
    editNote:SetCallback("OnLeave", SaveNote)
    
    noteGrp:AddChild(editNote)
    f:AddChild(noteGrp)
    
    local div = AceGUI:Create("Heading"); div:SetFullWidth(true); div:SetHeight(10); f:AddChild(div)
    f:AddChild(scroll)

    -- Sort history: Newest first
    local sortedHistory = {}
    for _, r in ipairs(pData.history) do table.insert(sortedHistory, r) end
    table.sort(sortedHistory, function(a,b) 
        -- Fallback for sorting if date format varies, though usually standardized
        return a.date > b.date 
    end)

    for _, run in ipairs(sortedHistory) do
        local grp = AceGUI:Create("SimpleGroup")
        grp:SetLayout("Flow"); grp:SetFullWidth(true)
        
        local zName = (self.BossDB[run.zone_id] and self.BossDB[run.zone_id].name) or "Unknown"
        local wipeStr = (run.wipes and run.wipes > 0) and ("|cffff0000" .. run.wipes .. " Wipes|r") or "|cff00ff00Clean|r"
        local diffColor = (run.difficulty == "Heroic") and "|cffffcc00" or "|cffaaaaaa"
        
        -- FORMAT:
        -- Date | Zone (Heroic)
        -- Time | Wipes
        
        local line1 = string.format("|cff888888%s|r  |cffffd700%s|r %s(%s)|r", run.date, zName, diffColor, run.difficulty)
        local line2 = string.format("Time: |cffffffff%s|r   %s", self:FormatTime(run.total_time, true), wipeStr)
            
        -- Use InteractiveLabel for Tooltip
        local lbl = AceGUI:Create("InteractiveLabel")
        lbl:SetText(line1 .. "\n" .. line2)
        lbl:SetFullWidth(true)
        lbl:SetFont(self.FONT or "Fonts\\ARIALN.TTF", 12)
        
        -- RICH TOOLTIP LOGIC (Replicated from Leaderboard)
        lbl:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:AddLine(zName, 1, 1, 1)
            
            -- Basic Stats
            GameTooltip:AddLine(string.format("Time: %s   Wipes: %d", self:FormatTime(run.total_time, true), run.wipes or 0), 1, 1, 1)

            -- Boss Splits/Kills
            if run.boss_kills then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Boss Splits & Kills:", 1, 0.8, 0)
                local sortedBosses = {}
                for id, data in pairs(run.boss_kills) do table.insert(sortedBosses, data) end
                table.sort(sortedBosses, function(a,b) return (a.split_time or 0) < (b.split_time or 0) end)

                for _, b in ipairs(sortedBosses) do
                    local bName = b.name or "Unknown"
                    local sTime = self:FormatTime(b.split_time, true)
                    local kTime = self:FormatTime(b.duration, true)
                    GameTooltip:AddDoubleLine(bName, string.format("|cffffffff%s|r (|cff00ff00%s|r)", sTime, kTime))
                end
            end

            -- Roster with Levels
            if run.roster then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Group Members:", 1, 0.8, 0)
                for _, p in ipairs(run.roster) do
                    local c = RAID_CLASS_COLORS[(p.class or "PRIEST"):upper()] or {r=0.7,g=0.7,b=0.7}
                    local lvlStr = p.level and (" (Lvl " .. p.level .. ")") or ""
                    GameTooltip:AddLine(p.name .. lvlStr, c.r, c.g, c.b)
                end
            end
            GameTooltip:Show()
        end)
        lbl:SetCallback("OnLeave", function() GameTooltip:Hide() end)

        grp:AddChild(lbl)
        
        local div = AceGUI:Create("Heading"); div:SetFullWidth(true); div:SetHeight(5)
        grp:AddChild(div)
        
        scroll:AddChild(grp)
    end
end

-- ============================================================================
-- LOGS TAB
-- ============================================================================

function Stautist:DrawLogsContent(container)
    container:SetLayout("Flow")
    local AceGUI = LibStub("AceGUI-3.0")
    
    self:CleanupInstanceLog()

    -- NAVIGATION BUTTONS
    local navGrp = AceGUI:Create("SimpleGroup")
    navGrp:SetLayout("Flow")
    navGrp:SetFullWidth(true)
    container:AddChild(navGrp)

    local spNav = AceGUI:Create("Label"); spNav:SetText(" "); spNav:SetRelativeWidth(0.15); navGrp:AddChild(spNav)

    local btnLedger = AceGUI:Create("Button")
    btnLedger:SetText("Full Run Ledger")
    btnLedger:SetRelativeWidth(0.35)
    btnLedger:SetCallback("OnClick", function() self:OpenFullLedgerWindow() end)
    ApplyFont(btnLedger)
    navGrp:AddChild(btnLedger)

    local btnBossKills = AceGUI:Create("Button")
    btnBossKills:SetText("Boss Kills") 
    btnBossKills:SetRelativeWidth(0.35)
    btnBossKills:SetCallback("OnClick", function() 
        container:ReleaseChildren()
        self:DrawBossKillsView(container) 
    end)
    ApplyFont(btnBossKills)
    navGrp:AddChild(btnBossKills)

    local spacer = AceGUI:Create("Label"); spacer:SetText(" "); spacer:SetFullWidth(true); container:AddChild(spacer)
    
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetHeight(350)
    container:AddChild(scroll)
    
    -- HOURLY LIMIT TRACKER
    local grpLimit = AceGUI:Create("SimpleGroup")
    grpLimit:SetLayout("Flow")
    grpLimit:SetFullWidth(true)
    scroll:AddChild(grpLimit)

    local headerLimit = AceGUI:Create("Label")
    headerLimit:SetText("HOURLY LIMIT TRACKER")
    headerLimit:SetFont(self.db.profile.font_title or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    headerLimit:SetColor(1, 0.82, 0) 
    headerLimit:SetFullWidth(true)
    headerLimit:SetJustifyH("CENTER")
    grpLimit:AddChild(headerLimit)
    
    local div1 = AceGUI:Create("Heading"); div1:SetFullWidth(true); div1:SetHeight(10); grpLimit:AddChild(div1)

    local logDB = self.db.char.instance_log or {}
    local count = #logDB
    local colorHex = (count >= 5) and "|cffff0000" or (count >= 3) and "|cffffcc00" or "|cff00ff00"
    
    local limitText = AceGUI:Create("Label")
    limitText:SetText(string.format("Instances entered in last 60 min: %s%d / 5|r", colorHex, count))
    limitText:SetFont(FONT_MAIN, 14, "OUTLINE")
    limitText:SetFullWidth(true)
    limitText:SetJustifyH("CENTER")
    grpLimit:AddChild(limitText)

    if count > 0 then
        local oldestTime = logDB[1].time
        local timeLeft = (oldestTime + 3600) - time()
        if timeLeft > 0 then
            local m = math.floor(timeLeft / 60)
            local s = timeLeft % 60
            local nextFree = AceGUI:Create("Label")
            nextFree:SetText(string.format("Next slot opens in: |cff00ccff%d min %d sec|r", m, s))
            nextFree:SetFullWidth(true)
            nextFree:SetJustifyH("CENTER")
            grpLimit:AddChild(nextFree)
        end
        
        local spacer2 = AceGUI:Create("Label"); spacer2:SetText("\nRecent Entries:"); spacer2:SetFullWidth(true); spacer2:SetJustifyH("CENTER"); grpLimit:AddChild(spacer2)
        for i = count, 1, -1 do
            local log = logDB[i]
            local ago = math.floor((time() - log.time) / 60)
            local row = AceGUI:Create("Label")
            row:SetText(string.format("- %s (%d mins ago)", log.name or "Unknown", ago))
            row:SetColor(0.7, 0.7, 0.7)
            row:SetFullWidth(true)
            row:SetJustifyH("CENTER")
            grpLimit:AddChild(row)
        end
    else
        local row = AceGUI:Create("Label"); row:SetText("\nNo instances entered recently."); row:SetColor(0.5, 0.5, 0.5); row:SetFullWidth(true); row:SetJustifyH("CENTER"); grpLimit:AddChild(row)
    end

    local spG = AceGUI:Create("Label"); spG:SetText(" "); spG:SetHeight(20); spG:SetFullWidth(true); scroll:AddChild(spG)

    -- ACTIVE LOCKOUTS
    local grpLock = AceGUI:Create("SimpleGroup")
    grpLock:SetLayout("Flow")
    grpLock:SetFullWidth(true)
    scroll:AddChild(grpLock)

    local headerLock = AceGUI:Create("Label")
    headerLock:SetText("ACTIVE LOCKOUTS")
    headerLock:SetFont(self.db.profile.font_title or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    headerLock:SetColor(1, 0.82, 0)
    headerLock:SetFullWidth(true)
    headerLock:SetJustifyH("CENTER")
    grpLock:AddChild(headerLock)
    
    local div2 = AceGUI:Create("Heading"); div2:SetFullWidth(true); div2:SetHeight(10); grpLock:AddChild(div2)

    local numSaved = GetNumSavedInstances()
    local hasLock = false
    if numSaved > 0 then
        for i = 1, numSaved do
            local name, _, reset, _, locked, _, _, _, _, diffName = GetSavedInstanceInfo(i)
            if locked then
                hasLock = true
                
                -- FORMATTING LOGIC CHANGE:
                local days = math.floor(reset / 86400)
                local r = reset % 86400
                local hours = math.floor(r / 3600)
                r = r % 3600
                local mins = math.floor(r / 60)
                
                local timeStr = ""
                if days > 0 then
                    timeStr = string.format("%dd %02dh %02dm", days, hours, mins)
                else
                    timeStr = string.format("%02dh %02dm", hours, mins)
                end
                
                local txt = string.format("%s (%s) - Resets in: %s", name, (diffName or "Normal"), timeStr)
                
                local lbl = AceGUI:Create("Label")
                lbl:SetText(txt)
                lbl:SetFullWidth(true)
                lbl:SetJustifyH("CENTER")
                lbl:SetColor(1, 0.8, 0)
                grpLock:AddChild(lbl)
            end
        end
    end
    
    if not hasLock then
        local lbl = AceGUI:Create("Label"); lbl:SetText("No active lockouts."); lbl:SetColor(0.5, 0.5, 0.5); lbl:SetFullWidth(true); lbl:SetJustifyH("CENTER"); grpLock:AddChild(lbl)
    end
end



function Stautist:DrawBossKillsView(container)
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- 1. DEFAULTS
    self.log_filters = self.log_filters or {
        exp = "All", type = "All", zone = "All", boss = "All", size = "All", difficulty = "All"
    }

    -- HEADER
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow"); header:SetFullWidth(true)
    container:AddChild(header)
    
    local btnBack = AceGUI:Create("Button")
    btnBack:SetText("< Back")
    btnBack:SetWidth(80)
    btnBack:SetCallback("OnClick", function() 
        container:ReleaseChildren()
        self:DrawLogsContent(container) 
    end)
    if ApplyFont then ApplyFont(btnBack) end
    header:AddChild(btnBack)
    
    local title = AceGUI:Create("Label")
    title:SetText("  FASTEST BOSS KILLS (Top 20)")
    -- FIX: Use Main Font (PTSans)
    title:SetFont(FONT_MAIN, 14, "OUTLINE") 
    title:SetColor(1, 0.8, 0)
    title:SetWidth(250)
    header:AddChild(title)

    -- FILTERS
    local filters = AceGUI:Create("SimpleGroup")
    filters:SetLayout("Flow")
    filters:SetFullWidth(true)
    container:AddChild(filters)

    local function AddFilter(label, list, val, key, width)
        local d = AceGUI:Create("Dropdown")
        d:SetLabel(label)
        d:SetList(list)
        d:SetValue(val)
        d:SetRelativeWidth(width)
        d:SetCallback("OnValueChanged", function(_,_,v) 
            self.log_filters[key] = v
            if key == "exp" or key == "type" then 
                self.log_filters.zone = "All"; self.log_filters.boss = "All"
            elseif key == "zone" then
                self.log_filters.boss = "All"
            end
            container:ReleaseChildren(); self:DrawBossKillsView(container)
        end)
        filters:AddChild(d)
    end

    AddFilter("Expansion", {["All"]="All", ["Classic"]="Classic", ["TBC"]="TBC", ["WotLK"]="WotLK"}, self.log_filters.exp, "exp", 0.14)
    AddFilter("Type", {["All"]="All", ["dungeon"]="Dungeon", ["raid"]="Raid"}, self.log_filters.type, "type", 0.14)
    AddFilter("Difficulty", {["All"]="All", ["Normal"]="Normal", ["Heroic"]="Heroic"}, self.log_filters.difficulty, "difficulty", 0.14)
    AddFilter("Size", {["All"]="All", ["5"]="5", ["10"]="10", ["25"]="25"}, self.log_filters.size, "size", 0.10)

    -- Dynamic Zone List
    local zoneList = {["All"] = "All Zones"}
    for id, data in pairs(self.BossDB) do
        local expMatch = (self.log_filters.exp == "All") or (data.tier == self.log_filters.exp)
        local typeMatch = (self.log_filters.type == "All") or (data.type == self.log_filters.type)
        if expMatch and typeMatch then zoneList[id] = data.name end
    end
    if self.log_filters.zone ~= "All" and not zoneList[self.log_filters.zone] then self.log_filters.zone = "All" end
    local sortedZones = self:GetSortedList(zoneList)
    local dZone = AceGUI:Create("Dropdown")
    dZone:SetLabel("Zone")
    dZone:SetList(zoneList, sortedZones)
    dZone:SetValue(self.log_filters.zone)
    dZone:SetRelativeWidth(0.22)
    dZone:SetCallback("OnValueChanged", function(_,_,v) 
        self.log_filters.zone = v; self.log_filters.boss = "All"
        container:ReleaseChildren(); self:DrawBossKillsView(container)
    end)
    filters:AddChild(dZone)

    -- Dynamic Boss List
    local bossList = {["All"] = "All Bosses"}
    if self.log_filters.zone ~= "All" and self.BossDB[self.log_filters.zone] then
        local zData = self.BossDB[self.log_filters.zone]
        for npcID, bData in pairs(zData.bosses) do
            local bName = (type(bData) == "table") and bData.name or bData
            bossList[npcID] = bName
        end
    end
    local sortedBosses = self:GetSortedList(bossList)
    local dBoss = AceGUI:Create("Dropdown")
    dBoss:SetLabel("Boss")
    dBoss:SetList(bossList, sortedBosses)
    dBoss:SetValue(self.log_filters.boss)
    dBoss:SetRelativeWidth(0.22)
    dBoss:SetCallback("OnValueChanged", function(_,_,v) 
        self.log_filters.boss = v
        container:ReleaseChildren(); self:DrawBossKillsView(container)
    end)
    filters:AddChild(dBoss)

    -- DATA LIST
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow"); scroll:SetFullWidth(true); scroll:SetHeight(380)
    container:AddChild(scroll)

    -- PROCESS DATA
    local targetBoss = self.log_filters.boss
    local kills = {}
    
    if self.db.global.run_history then
        for _, run in ipairs(self.db.global.run_history) do
            local sizeMatch = (self.log_filters.size == "All") or (tostring(run.size or 0) == self.log_filters.size)
            local runDiff = run.difficulty or "Normal"
            local diffMatch = (self.log_filters.difficulty == "All") or (runDiff == self.log_filters.difficulty)
            local zoneMatch = (self.log_filters.zone == "All") or (run.zone_id == self.log_filters.zone)
            
            if self.log_filters.zone == "All" and run.zone_id and self.BossDB[run.zone_id] then
                local dbZ = self.BossDB[run.zone_id]
                if self.log_filters.exp ~= "All" and dbZ.tier ~= self.log_filters.exp then zoneMatch = false end
                if self.log_filters.type ~= "All" and dbZ.type ~= self.log_filters.type then zoneMatch = false end
            end

            if sizeMatch and diffMatch and zoneMatch and run.boss_kills then
                for bID, kData in pairs(run.boss_kills) do
                    local bIDNum = tonumber(bID)
                    if targetBoss == "All" or bIDNum == targetBoss then
                        -- FIX: Strict check for > 0.1 to avoid 0s
                        if kData.duration and kData.duration > 0.1 then
                            table.insert(kills, {
                                duration = kData.duration, 
                                date = run.date, 
                                bossName = kData.name or "Unknown",
                                run_ref = run
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(kills, function(a,b) return a.duration < b.duration end)

    if #kills == 0 then
        local lbl = AceGUI:Create("Label"); lbl:SetText("\nNo kills found matching filters."); lbl:SetJustifyH("CENTER"); lbl:SetFullWidth(true)
        scroll:AddChild(lbl)
    else
        for i = 1, math.min(#kills, 20) do
            local k = kills[i]
            local grp = AceGUI:Create("SimpleGroup")
            grp:SetLayout("Flow"); grp:SetFullWidth(true)
            
            local lblRank = AceGUI:Create("Label"); lblRank:SetText(i.."."); lblRank:SetWidth(30); lblRank:SetColor(1, 0.8, 0)
            grp:AddChild(lblRank)
            
            local lblTime = AceGUI:Create("Label"); lblTime:SetText(self:FormatTime(k.duration, true)); lblTime:SetWidth(60); lblTime:SetColor(0, 1, 0)
            grp:AddChild(lblTime)
            
            local infoText = k.date
            if targetBoss == "All" then infoText = k.bossName .. "  |cff888888(" .. k.date .. ")|r" end

            local lblInfo = AceGUI:Create("InteractiveLabel")
            lblInfo:SetText(infoText)
            lblInfo:SetWidth(300)
            
            lblInfo:SetCallback("OnEnter", function(widget)
            local run = k.run_ref
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:AddLine(k.bossName, 1, 1, 1)
            GameTooltip:AddDoubleLine("Kill Time:", "|cff00ff00"..self:FormatTime(k.duration, true))
            GameTooltip:AddDoubleLine("Run Total:", "|cffffffff"..self:FormatTime(run.total_time, true))
            GameTooltip:AddDoubleLine("Date:", "|cffaaaaaa"..k.date)
            
            -- Squad Info
            if run.roster then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Squad:", 1, 0.82, 0)
                for _, p in ipairs(run.roster) do
                    local c = self:SafeGetClassColor(p.class)
                    GameTooltip:AddLine(p.name .. (p.level and " ("..p.level..")" or ""), c.r, c.g, c.b)
                end
            end

            -- Other Bosses in this specific run
            if run.boss_kills then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Run Splits:", 1, 0.82, 0)
                local sortedB = {}
                for id, bData in pairs(run.boss_kills) do table.insert(sortedB, bData) end
                table.sort(sortedB, function(a,b) return (a.split_time or 0) < (b.split_time or 0) end)
                
                for _, b in ipairs(sortedB) do
                    local color = (b.name == k.bossName) and "|cff00ff00" or "|cffffffff"
                    GameTooltip:AddDoubleLine(color..b.name, "|cffffffff"..self:FormatTime(b.split_time))
                end
            end
            GameTooltip:Show()
        end)
            lblInfo:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            
            grp:AddChild(lblInfo)
            scroll:AddChild(grp)
        end
    end
end







-- ============================================================================
-- SETUP WIZARD
-- ============================================================================
function Stautist:RunSetupWizard()
    if StautistSetupFrame then StautistSetupFrame:Show(); return end

    local f = CreateFrame("Frame", "StautistSetupFrame", UIParent)
    f:SetSize(400, 300)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.95)
    f:SetBackdropBorderColor(1, 0.2, 0.2, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Stautist Setup")
    title:SetTextColor(1, 0.2, 0.2)

    local desc = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -20)
    desc:SetWidth(360)
    desc:SetJustifyH("CENTER")
    desc:SetFont("Fonts\\FRIZQT__.TTF", 12)

    local container = CreateFrame("Frame", nil, f)
    container:SetSize(360, 150)
    container:SetPoint("TOP", desc, "BOTTOM", 0, -10)

    local step = 1
    local maxSteps = 6
    
    local btnNext = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnNext:SetSize(100, 25)
    btnNext:SetPoint("BOTTOMRIGHT", -20, 20)
    btnNext:SetText("Next")

    local btnSkip = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSkip:SetSize(100, 25)
    btnSkip:SetPoint("BOTTOMLEFT", 20, 20)
    btnSkip:SetText("Skip Setup")
    btnSkip:SetScript("OnClick", function() 
        f:Hide()
        Stautist:StopFakeSimulation()
    end)

    local function ShowStep()
        for _, child in ipairs({container:GetChildren()}) do child:Hide() end
        
        -- Start Simulation on Scale steps
        if step == 2 or step == 3 then
            Stautist:StartFakeSimulation()
        else
            Stautist:StopFakeSimulation()
        end

        if step == 1 then
            desc:SetText("Welcome to Stautist!\n\nWould you take a moment to go through |cffff0000Stautist|r setup?")
            btnNext:SetText("Start")
            
        elseif step == 2 then
            desc:SetText("Step 1: HUD Scale\n(See preview on screen)")
            
            local s = CreateFrame("Slider", "StautistSetupHudScale", container, "OptionsSliderTemplate")
            s:SetPoint("CENTER", 0, 10)
            s:SetMinMaxValues(0.5, 2.0)
            s:SetValue(Stautist.db.profile.timer_scale)
            s:SetValueStep(0.1)
            getglobal(s:GetName()..'Low'):SetText('0.5')
            getglobal(s:GetName()..'High'):SetText('2.0')
            getglobal(s:GetName()..'Text'):SetText(string.format('Scale: %.1f', Stautist.db.profile.timer_scale))
            
            -- FIX: Separate Logic
            s:SetScript("OnValueChanged", function(selfS, value)
                value = math.floor(value * 10 + 0.5) / 10
                getglobal(selfS:GetName()..'Text'):SetText(string.format('Scale: %.1f', value))
            end)
            
            s:SetScript("OnMouseUp", function(selfS)
                local value = selfS:GetValue()
                value = math.floor(value * 10 + 0.5) / 10
                Stautist.db.profile.timer_scale = value
                if Stautist.hudFrame then Stautist.hudFrame:SetScale(value) end
            end)
            s:Show()

        elseif step == 3 then
            desc:SetText("Step 2: Menu/Config Scale\n(Adjust this window size)")
            
            local s = CreateFrame("Slider", "StautistSetupMenuScale", container, "OptionsSliderTemplate")
            s:SetPoint("CENTER", 0, 10)
            s:SetMinMaxValues(0.5, 2.0)
            s:SetValue(Stautist.db.profile.config_scale)
            s:SetValueStep(0.1)
            getglobal(s:GetName()..'Low'):SetText('0.5')
            getglobal(s:GetName()..'High'):SetText('2.0')
            getglobal(s:GetName()..'Text'):SetText(string.format('Scale: %.1f', Stautist.db.profile.config_scale))
            
            s:SetScript("OnValueChanged", function(selfS, value)
                value = math.floor(value * 10 + 0.5) / 10
                getglobal(selfS:GetName()..'Text'):SetText(string.format('Scale: %.1f', value))
            end)
            
            s:SetScript("OnMouseUp", function(selfS)
                local value = selfS:GetValue()
                value = math.floor(value * 10 + 0.5) / 10
                Stautist.db.profile.config_scale = value
                if Stautist.ConfigFrame then Stautist.ConfigFrame:SetScale(value) end
                f:SetScale(value) 
            end)
            s:Show()

        elseif step == 4 then
            desc:SetText("Step 3: HUD Visibility Behavior")
            
            local function ResetButtons(btns)
                for _, b in ipairs(btns) do 
                    b:GetFontString():SetTextColor(1, 0.82, 0) -- Default Gold
                    b:Enable()
                end
            end
            
            local b1 = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
            local b2 = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
            local b3 = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
            local btns = {b1, b2, b3}

            local function SetSelected(btn, val)
                ResetButtons(btns)
                Stautist.db.profile.hud_behavior = val
                btn:GetFontString():SetTextColor(0, 1, 0) -- Green when selected
                Stautist:Print("HUD Behavior set to: " .. val)
            end

            b1:SetSize(100, 25); b1:SetPoint("LEFT", 10, 0); b1:SetText("Always Show")
            b1:SetScript("OnClick", function() SetSelected(b1, "Show") end)
            
            b2:SetSize(100, 25); b2:SetPoint("CENTER", 0, 0); b2:SetText("Ask on Enter")
            b2:SetScript("OnClick", function() SetSelected(b2, "Ask") end)

            b3:SetSize(100, 25); b3:SetPoint("RIGHT", -10, 0); b3:SetText("Always Hide")
            b3:SetScript("OnClick", function() SetSelected(b3, "Hide") end)
            
            -- Highlight current setting
            local cur = Stautist.db.profile.hud_behavior
            if cur == "Show" then SetSelected(b1, "Show")
            elseif cur == "Ask" then SetSelected(b2, "Ask")
            elseif cur == "Hide" then SetSelected(b3, "Hide") end
            
            b1:Show(); b2:Show(); b3:Show()
        
        elseif step == 5 then
            desc:SetText("Step 4: Announcements & Automation")
            
            local function CreateCheck(name, var, y)
                local c = CreateFrame("CheckButton", name, container, "UICheckButtonTemplate")
                c:SetPoint("TOPLEFT", 40, y)
                getglobal(c:GetName().."Text"):SetText(var)
                return c
            end

            local c1 = CreateCheck("StautistSetupC1", "Announce Resets", 0)
            c1:SetChecked(Stautist.db.profile.announce_resets)
            c1:SetScript("OnClick", function(s) Stautist.db.profile.announce_resets = s:GetChecked() end)
            c1:Show()

            local c2 = CreateCheck("StautistSetupC2", "Announce 5/Hour Limit", -30)
            c2:SetChecked(Stautist.db.profile.announce_lockouts)
            c2:SetScript("OnClick", function(s) Stautist.db.profile.announce_lockouts = s:GetChecked() end)
            c2:Show()

            local c3 = CreateCheck("StautistSetupC3", "Announce Run Completion", -60)
            c3:SetChecked(Stautist.db.profile.announce_completion)
            c3:SetScript("OnClick", function(s) Stautist.db.profile.announce_completion = s:GetChecked() end)
            c3:Show()

            local c4 = CreateCheck("StautistSetupC4", "Announce Fastest Kills (PB)", -90)
            c4:SetChecked(Stautist.db.profile.announce_fastest_kill)
            c4:SetScript("OnClick", function(s) Stautist.db.profile.announce_fastest_kill = s:GetChecked() end)
            c4:Show()
            
        elseif step == 6 then
            desc:SetText("Setup Complete!\n\nType /stau to open settings anytime.")
            btnNext:SetText("Finish")
        end
    end

    btnNext:SetScript("OnClick", function()
        step = step + 1
        if step > maxSteps then
            f:Hide()
            Stautist:StopFakeSimulation()
        else
            ShowStep()
        end
    end)

    ShowStep()
end


-- ============================================================================
-- FULL LEDGER
-- ============================================================================

function Stautist:GetTimestampFromDate(dateStr)
    if not dateStr then return 0 end
    local d, m, y, H, M = dateStr:match("(%d+)/(%d+)/(%d+) (%d+):(%d+)")
    if d and m and y then
        -- Assume 20xx for year
        return time({year=2000+tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(H), min=tonumber(M)})
    end
    return 0
end

function Stautist:OpenFullLedgerWindow()
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- Create Frame
    local f = AceGUI:Create("Frame")
    f:SetTitle("Stautist - Full Run Ledger")
    f:SetLayout("Flow")
    f:SetWidth(650)
    f:SetHeight(550)
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    -- 1. CALCULATE STATS
    local now = time()
    local stats = {
        dungeon = { today=0, week=0, month=0, total=0 },
        raid = { today=0, week=0, month=0, total=0 }
    }
    
    local history = self.db.global.run_history or {}
    
    -- Sort by date descending (Newest first)
    table.sort(history, function(a,b)
        local tA = a.timestamp or self:GetTimestampFromDate(a.date)
        local tB = b.timestamp or self:GetTimestampFromDate(b.date)
        return tA > tB
    end)

    for _, run in ipairs(history) do
        local ts = run.timestamp or self:GetTimestampFromDate(run.date)
        local diff = now - ts
        
        -- Determine Type
        local rType = "dungeon"
        if run.zone_id and self.BossDB[run.zone_id] then
            rType = self.BossDB[run.zone_id].type or "dungeon"
        end
        
        if stats[rType] then
            stats[rType].total = stats[rType].total + 1
            
            -- Today (24h rolling or calendar? Using 24h rolling for simplicity)
            if diff < 86400 then stats[rType].today = stats[rType].today + 1 end
            -- Week (7 days rolling)
            if diff < 604800 then stats[rType].week = stats[rType].week + 1 end
            -- Month (30 days rolling)
            if diff < 2592000 then stats[rType].month = stats[rType].month + 1 end
        end
    end

    -- 2. DRAW STATS HEADER
    local grpStats = AceGUI:Create("InlineGroup")
    grpStats:SetTitle("Statistics")
    grpStats:SetLayout("Flow")
    grpStats:SetFullWidth(true)
    f:AddChild(grpStats)

    local function CreateStatColumn(title, data)
        local g = AceGUI:Create("SimpleGroup")
        g:SetLayout("List")
        g:SetRelativeWidth(0.45) 
        
        local lTitle = AceGUI:Create("Label")
        lTitle:SetText(title)
        
        -- FIX: Use FONT_MAIN (PTSans) explicitly
        lTitle:SetFont(FONT_MAIN, 16, "OUTLINE") 
        
        lTitle:SetColor(1, 0.8, 0)
        lTitle:SetJustifyH("CENTER")
        lTitle:SetFullWidth(true)
        g:AddChild(lTitle)
        
        -- SPACER
        local sp = AceGUI:Create("Label"); sp:SetText(" "); sp:SetHeight(10); g:AddChild(sp)
        
        local function AddStat(txt, color)
            local l = AceGUI:Create("Label")
            l:SetText(txt)
            l:SetFullWidth(true)
            l:SetJustifyH("CENTER")
            if color then l:SetColor(unpack(color)) end
            
            -- FIX: Apply PTSans to stats
            l:SetFont(FONT_MAIN, 12)
            
            g:AddChild(l)
        end

        AddStat("Today: " .. data.today)
        AddStat("This Week: " .. data.week)
        AddStat("This Month: " .. data.month)
        AddStat("Total Tracked: " .. data.total, {0.6, 0.6, 0.6})
        
        return g
    end

    -- Spacer Left
    local spL = AceGUI:Create("Label"); spL:SetText(" "); spL:SetRelativeWidth(0.05); grpStats:AddChild(spL)
    
    grpStats:AddChild(CreateStatColumn("DUNGEONS", stats.dungeon))
    grpStats:AddChild(CreateStatColumn("RAIDS", stats.raid))

    -- 3. DRAW SCROLLABLE LIST
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetHeight(380)
    f:AddChild(scroll)

    for i, run in ipairs(history) do
        local grp = AceGUI:Create("SimpleGroup")
        grp:SetLayout("Flow")
        grp:SetFullWidth(true)
        
        -- Background for alternate rows
        if i % 2 == 0 then
            local bg = AceGUI:Create("Heading")
            bg:SetFullWidth(true); bg:SetHeight(0) -- Hacky separator
            -- AceGUI SimpleGroup doesn't support BG easily without custom frame, 
            -- so we stick to clean text or simple spacers.
        end

        local zName = "Unknown"
        if run.zone_id and self.BossDB[run.zone_id] then zName = self.BossDB[run.zone_id].name end
        if run.partial then zName = zName .. " (Partial)" end
        
        -- Format: [Date] Zone (Diff) - Time [Success/Fail]
        local dateColor = "|cffaaaaaa"
        local zoneColor = "|cffffffff"
        local timeColor = "|cff00ff00"
        
        if not run.success then timeColor = "|cffff0000" end -- Red time if failed
        
        local line = string.format("%s%s|r  %s%s (%s)|r  -  %s%s|r", 
            dateColor, run.date, 
            zoneColor, zName, run.difficulty,
            timeColor, self:FormatTime(run.total_time)
        )
        
        local lbl = AceGUI:Create("InteractiveLabel")
        lbl:SetText(line)
        lbl:SetFullWidth(true)
        lbl:SetFont(self.FONT or "Fonts\\ARIALN.TTF", 12)
        
        -- Tooltip for details
        lbl:SetCallback("OnEnter", function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:AddLine(zName, 1, 1, 1)
            GameTooltip:AddLine("Date: " .. run.date)
            GameTooltip:AddLine("Time: " .. self:FormatTime(run.total_time))
            GameTooltip:AddLine("Wipes: " .. (run.wipes or 0))
            if run.roster then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Group Members:", 1, 0.8, 0)
                for _, p in ipairs(run.roster) do
                    local c = RAID_CLASS_COLORS[p.class:upper()] or {r=0.7,g=0.7,b=0.7}
                    GameTooltip:AddLine(p.name, c.r, c.g, c.b)
                end
            end
            GameTooltip:Show()
        end)
        lbl:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        
        grp:AddChild(lbl)
        scroll:AddChild(grp)
    end
end

function Stautist:DrawPlaceholderContent(container, text)
    local AceGUI = LibStub("AceGUI-3.0")
    
    -- Use Fill layout to force children to fill the space
    container:SetLayout("Fill") 
    
    -- Create a wrapper group for alignment if needed, or just add the label directly
    -- Adding directly to a Fill container is the most reliable way to center a label
    
    local lbl = AceGUI:Create("Label")
    lbl:SetText("\n\n" .. (text or "soon. i think. maybe. we'll see"))
    
    -- Apply Font
    lbl:SetFont(FONT_MAIN, 24, "OUTLINE") 
    
    lbl:SetColor(0.5, 0.5, 0.5)
    lbl:SetJustifyH("CENTER") -- Center Horizontally
    lbl:SetJustifyV("MIDDLE") -- Try vertical center (some AceGUI versions support this on Label)
    
    container:AddChild(lbl)
end



-- ============================================================================
-- DATA IMPORT / EXPORT (PHASE 3)
-- ============================================================================

-- Base64 Encoder/Decoder for 3.3.5
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function Stautist:Base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function Stautist:Base64Decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',b64chars:find(x)-1
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function Stautist:ShowExportImportWindow(mode)
    local AceGUI = LibStub("AceGUI-3.0")
    local f = AceGUI:Create("Frame")
    f:SetTitle("Stautist - " .. mode)
    f:SetLayout("Flow")
    f:SetWidth(500)
    f:SetHeight(400)
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    local ml = AceGUI:Create("MultiLineEditBox")
    ml:SetLabel(mode == "EXPORT" and "Copy this text to save your data:" or "Paste data string here:")
    ml:SetRelativeWidth(1.0)
    ml:SetNumLines(20)
    ml:DisableButton(true) -- No 'Enter' button needed
    f:AddChild(ml)

    if mode == "EXPORT" then
        -- Serialize Run History
        local Serializer = LibStub("AceSerializer-3.0")
        if Serializer then
            local data = {
                version = "1.0",
                history = self.db.global.run_history
            }
            local serialized = Serializer:Serialize(data)
            local encoded = self:Base64Encode(serialized)
            ml:SetText(encoded)
            ml:SetFocus()
            ml:HighlightText()
        else
            self:Print("Error: AceSerializer not found.")
        end
    else
        -- IMPORT MODE
        local btnImport = AceGUI:Create("Button")
        btnImport:SetText("Process Import")
        btnImport:SetRelativeWidth(1.0)
        btnImport:SetCallback("OnClick", function()
            local text = ml:GetText()
            if not text or text == "" then return end
            
            local decoded = self:Base64Decode(text)
            local Serializer = LibStub("AceSerializer-3.0")
            local success, data = Serializer:Deserialize(decoded)
            
            if success and data and data.history then
                -- Merge Logic
                local count = 0
                for _, newRun in ipairs(data.history) do
                    -- Check for duplicates (simple check by timestamp + zone)
                    local exists = false
                    for _, oldRun in ipairs(self.db.global.run_history) do
                        if oldRun.timestamp == newRun.timestamp and oldRun.zone_id == newRun.zone_id then
                            exists = true; break
                        end
                    end
                    if not exists then
                        table.insert(self.db.global.run_history, newRun)
                        count = count + 1
                    end
                end
                self:Print("Import Successful! Added " .. count .. " runs.")
                f:Hide()
                self:RefreshLeaderboard()
            else
                self:Print("|cffff0000Import Failed:|r Invalid data string.")
            end
        end)
        f:AddChild(btnImport)
    end
end



function Stautist:DrawGuildContent(container)
    self.guild_filters = self.guild_filters or { expansion = "All", type = "All", zone = "All", difficulty = "All" }
    
    container:SetLayout("Flow")
    local AceGUI = LibStub("AceGUI-3.0")

    -- 1. SYNC CONTROLS
    local grpControls = AceGUI:Create("SimpleGroup")
    grpControls:SetLayout("Flow")
    grpControls:SetFullWidth(true)
    container:AddChild(grpControls)

    local btnSync = AceGUI:Create("Button")
    btnSync:SetText("SYNC GUILD DATA")
    btnSync:SetWidth(150)
    btnSync:SetCallback("OnClick", function() 
        if self.StartGuildSync then self:StartGuildSync() else print("Comm module missing.") end
    end)
    if ApplyFont then ApplyFont(btnSync) end
    grpControls:AddChild(btnSync)
    
    local lblWarn = AceGUI:Create("Label")
    lblWarn:SetText(" (Must be out of combat)")
    lblWarn:SetColor(0.5, 0.5, 0.5)
    lblWarn:SetWidth(150)
    grpControls:AddChild(lblWarn)

    -- 2. FILTERS
    local headerGrp = AceGUI:Create("SimpleGroup")
    headerGrp:SetLayout("Flow")
    headerGrp:SetFullWidth(true)
    container:AddChild(headerGrp)

    local dropExp = AceGUI:Create("Dropdown")
    dropExp:SetLabel("Expansion")
    dropExp:SetList({ ["All"]="All", ["Classic"]="Classic", ["TBC"]="TBC", ["WotLK"]="WotLK" })
    dropExp:SetValue(self.guild_filters.expansion)
    dropExp:SetRelativeWidth(0.24)
    dropExp:SetCallback("OnValueChanged", function(_, _, val) self.guild_filters.expansion = val; self:RefreshGuildLeaderboard() end)
    headerGrp:AddChild(dropExp)

    local dropType = AceGUI:Create("Dropdown")
    dropType:SetLabel("Type")
    dropType:SetList({ ["All"]="All", ["dungeon"]="Dungeon", ["raid"]="Raid" })
    dropType:SetValue(self.guild_filters.type)
    dropType:SetRelativeWidth(0.24)
    dropType:SetCallback("OnValueChanged", function(_, _, val) self.guild_filters.type = val; self:RefreshGuildLeaderboard() end)
    headerGrp:AddChild(dropType)

    local dropDiff = AceGUI:Create("Dropdown")
    dropDiff:SetLabel("Difficulty")
    dropDiff:SetList({ ["All"]="All", ["Normal"]="Normal", ["Heroic"]="Heroic" })
    dropDiff:SetValue(self.guild_filters.difficulty)
    dropDiff:SetRelativeWidth(0.24)
    dropDiff:SetCallback("OnValueChanged", function(_, _, val) self.guild_filters.difficulty = val; self:RefreshGuildLeaderboard() end)
    headerGrp:AddChild(dropDiff)

    local zoneList = {["All"] = "All Zones"}
    if self.BossDB then
        for id, data in pairs(self.BossDB) do zoneList[id] = data.name end
    end
    local dropZone = AceGUI:Create("Dropdown")
    dropZone:SetLabel("Zone")
    local sortedGuildZones = self:GetSortedList(zoneList)
    dropZone:SetList(zoneList, sortedGuildZones)
    dropZone:SetValue(self.guild_filters.zone)
    dropZone:SetRelativeWidth(0.24)
    dropZone:SetCallback("OnValueChanged", function(_, _, val) self.guild_filters.zone = val; self:RefreshGuildLeaderboard() end)
    headerGrp:AddChild(dropZone)

    -- 3. SCROLL LIST
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetHeight(400) -- Increased height since log is gone
    container:AddChild(scroll)
    self.guildScroll = scroll

    self:RefreshGuildLeaderboard()
end

function Stautist:RefreshGuildLeaderboard()
    if not self.guildScroll then return end
    self.guildScroll:ReleaseChildren()
    local AceGUI = LibStub("AceGUI-3.0")

    -- 1. AGGREGATE RUNS (The Grouper)
     local groupedRuns = {} 
    local function AddToGroup(playerName, run)
    if type(run) ~= "table" or not run or not run.z then return end
        
        -- 1. Correct Filter Logic
        local zData = self.BossDB[run.z]
        if not zData then return end -- Skip if zone not in DB

        if self.guild_filters.expansion ~= "All" and zData.tier ~= self.guild_filters.expansion then return end
        if self.guild_filters.type ~= "All" and zData.type ~= self.guild_filters.type then return end
        if self.guild_filters.difficulty ~= "All" and run.d ~= self.guild_filters.difficulty then return end
        if self.guild_filters.zone ~= "All" and run.z ~= self.guild_filters.zone then return end

        -- 2. Grouping Signature
        local sig = run.z .. "_" .. run.d .. "_" .. math.floor(run.t) .. "_" .. (run.dt or "N/A")
        
        if not groupedRuns[sig] then
            groupedRuns[sig] = {
                zone_name = zData.name,
                time = run.t,
                date = run.dt,
                diff = run.d,
                level = run.l or 80,
                size = run.s or 5,
                players = {} 
            }
        end
        table.insert(groupedRuns[sig].players, { name = playerName, class = run.c })
    end

    -- A. Add Guildmates
    local cache = self.db.global.guild_cache or {}
    for pName, zones in pairs(cache) do
        for _, run in pairs(zones) do AddToGroup(pName, run) end
    end

    -- B. Add YOURSELF (The User)
    local _, myClass = UnitClass("player")
    local myName = UnitName("player")
    if self.db.global.run_history then
        for _, run in ipairs(self.db.global.run_history) do
            if run.success and run.total_time and run.zone_id then
                local myRunFormatted = {
                    z = run.zone_id,
                    d = run.difficulty or "Normal",
                    t = run.total_time,
                    dt = run.date,
                    l = self:GetMaxLevel(run.roster),
                    s = run.size or 5,
                    c = myClass
                }
                AddToGroup(myName, myRunFormatted)
            end
        end
    end

    -- 2. CONVERT TO LIST & SORT
    local displayList = {}
    for _, group in pairs(groupedRuns) do
        table.insert(displayList, group)
    end

    table.sort(displayList, function(a,b) 
        return a.time < b.time 
    end)

    -- 3. RENDER
    if #displayList == 0 then
        local lbl = AceGUI:Create("Label")
        lbl:SetText("\nNo guild records found matching filters.")
        lbl:SetColor(0.5, 0.5, 0.5)
        lbl:SetFullWidth(true)
        lbl:SetJustifyH("CENTER")
        self.guildScroll:AddChild(lbl)
    else
        local RENDER_CAP = 50
        if #displayList > RENDER_CAP then
            local warn = AceGUI:Create("Label")
            warn:SetText("Showing top " .. RENDER_CAP .. " results (Capped)")
            warn:SetColor(1, 0.5, 0)
            warn:SetFullWidth(true)
            warn:SetJustifyH("CENTER")
            self.guildScroll:AddChild(warn)
        end

        local guildName, _, _ = GetGuildInfo("player")
        if not guildName then guildName = "Guild" end

        for i = 1, math.min(#displayList, RENDER_CAP) do
            local run = displayList[i]
            local grp = AceGUI:Create("SimpleGroup")
            grp:SetLayout("Flow")
            grp:SetFullWidth(true)

            -- RANK
            local lblRank = AceGUI:Create("Label")
            lblRank:SetText(i..".")
            lblRank:SetWidth(30)
            lblRank:SetColor(1, 0.8, 0)
            grp:AddChild(lblRank)

            -- PLAYER / GROUP DISPLAY LOGIC
            local count = #run.players
            local max = run.size or 5
            local displayNameText = ""

            -- FULL GUILD RUN
            if count >= max then
                displayNameText = "|cff40ff40<" .. guildName .. "> Run|r"
            
            -- PARTIAL LARGE GROUP (4+)
            elseif count >= 4 then
                displayNameText = "|cffffffffGuild Group (" .. count .. ")|r"
            
            -- SMALL GROUP (List Names)
            else
                -- Sort by Name for consistency
                table.sort(run.players, function(a,b) return a.name < b.name end)
                
                local names = ""
                for k, p in ipairs(run.players) do
                    local cColor = RAID_CLASS_COLORS[p.class] or {r=0,g=1,b=0} -- Default Green if missing
                    local hex = string.format("|cff%02x%02x%02x", cColor.r*255, cColor.g*255, cColor.b*255)
                    names = names .. hex .. p.name .. "|r" .. (k < count and ", " or "")
                end
                displayNameText = names
            end

            local lblName = AceGUI:Create("InteractiveLabel")
            lblName:SetText(displayNameText)
            lblName:SetWidth(150)
            
            -- TOOLTIP: Show exactly who was in the run (WITH COLORS)
            lblName:SetCallback("OnEnter", function(widget)
                GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
                GameTooltip:AddLine("Run Participants ("..count..")", 1, 0.82, 0)
                
                table.sort(run.players, function(a,b) return a.name < b.name end)
                
                for _, p in ipairs(run.players) do
                    local c = RAID_CLASS_COLORS[p.class] or {r=1,g=1,b=1}
                    GameTooltip:AddLine(p.name, c.r, c.g, c.b)
                end
                GameTooltip:Show()
            end)
            lblName:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            
            grp:AddChild(lblName)

            -- ZONE & DIFF
            local lblZone = AceGUI:Create("Label")
            local diffShort = (run.diff == "Heroic") and "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12|t" or ""
            lblZone:SetText(run.zone_name .. " " .. diffShort)
            lblZone:SetWidth(180)
            grp:AddChild(lblZone)

            -- TIME
            local lblTime = AceGUI:Create("Label")
            lblTime:SetText(self:FormatTime(run.time))
            lblTime:SetColor(0, 1, 0)
            lblTime:SetWidth(60)
            grp:AddChild(lblTime)

            self.guildScroll:AddChild(grp)
        end
    end
end

function Stautist:CreateSyncWindow()
    if self.syncWindow and self.syncWindow:IsShown() then return end
    
    local AceGUI = LibStub("AceGUI-3.0")
    local f = AceGUI:Create("Window")
    f:SetTitle("Stautist Sync Status")
    f:SetLayout("Fill")
    f:SetWidth(400)
    f:SetHeight(300)
    f:EnableResize(false)
    f:SetCallback("OnClose", function(widget) 
        AceGUI:Release(widget)
        self.syncWindow = nil
        self.syncLogBox = nil
    end)
    
    local edit = AceGUI:Create("MultiLineEditBox")
    edit:SetLabel("")
    edit:SetFullWidth(true)
    edit:SetFullHeight(true)
    edit:DisableButton(true)
    edit:SetText("Initializing Sync...")
    f:AddChild(edit)
    
    self.syncWindow = f
    self.syncLogBox = edit
    f:Show()
end