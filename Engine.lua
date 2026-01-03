local Stautist = LibStub("AceAddon-3.0"):GetAddon("Stautist")

-- State Variables
local currentZoneID = nil
local timerFrame = CreateFrame("Frame")
local activeRun = { isLive = false, startTime = 0, mapID = 0 }

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function IsICCBossHeroic()
    for i = 1, GetNumSavedInstances() do
        local name, _, _, _, locked, _, _, _, _, diffName = GetSavedInstanceInfo(i)
        if name == "Icecrown Citadel" and locked then
            return diffName == "Heroic"
        end
    end
    return false
end

function Stautist:DetermineRunTier(roster)
    local maxLevel = 0
    for _, p in ipairs(roster) do
        if p.level and p.level > maxLevel then maxLevel = p.level end
    end
    
    if maxLevel > 71 then return "WotLK"
    elseif maxLevel > 61 then return "TBC"
    else return "Classic" end
end

function Stautist:IsGroupWiped()
    local num = GetNumRaidMembers()
    local prefix = "raid"
    if num == 0 then 
        num = GetNumPartyMembers() 
        prefix = "party" 
    end
    if num == 0 then return UnitIsDeadOrGhost("player") end 

    local deadCount = 0
    for i = 1, num do
        if UnitIsDeadOrGhost(prefix..i) then deadCount = deadCount + 1 end
    end
    if prefix == "party" and UnitIsDeadOrGhost("player") then deadCount = deadCount + 1 end
    
    local total = (prefix == "party") and (num + 1) or num
    return deadCount >= total
end

function Stautist:GetGroupSize()
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then return numRaid end
    local numParty = GetNumPartyMembers()
    if numParty > 0 then return numParty + 1 end 
    return 1 
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function Stautist:SetupEngine()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterInstance")
    self:RegisterEvent("UPDATE_INSTANCE_INFO", "CheckZoneStatus") 
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChange") 
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckCombatDrop")
    self:RegisterEvent("LFG_COMPLETION_REWARD", "OnLFGComplete")
    
    -- Name Map
    self.NAME_TO_ID = {} 
    if self.BossDB then
        for id, data in pairs(self.BossDB) do
            if data.name then self.NAME_TO_ID[data.name] = id end
        end
    end
    
    self.timerFrame = CreateFrame("Frame")
    self.timerFrame:SetScript("OnUpdate", function(_, elapsed) self:OnTimerUpdate(elapsed) end)

    -- Failsafe: Check for stale runs
    local state = self.db.char.active_run_state
    if state and state.is_running then
        local now = GetTime()
        if now < (state.start_time or 0) then
            self:Print("|cffff0000[Failsafe]|r System restart detected. Aborting previous run.")
            state.is_running = false
            state.hud_forced = nil
        elseif (now - (state.start_time or 0)) > 14400 then 
            self:Print("|cffff0000[Failsafe]|r Run active for > 4 hours. Auto-stopping.")
            state.is_running = false
            state.hud_forced = nil
        end
    end
    
    -- New Variable to prevent auto-restart logic
    self.suppress_auto_start_zone = nil

    print("|cff00ff00[Stautist]|r Engine Online.")
end

-- ============================================================================
-- EVENTS & LOGIC
-- ============================================================================

function Stautist:OnLFGComplete()
    local state = self.db.char.active_run_state
    if state.is_running then
        self:Print("Dungeon Finder Completion Detected.")
        self:ScheduleTimer(function()
             if self.db.char.active_run_state.is_running then
                 self:StopRun(true, "LFG Complete")
             end
        end, 2)
    end
end

function Stautist:OnZoneChange()
    -- Clear restart suppression when changing zones
    self.suppress_auto_start_zone = nil

    local state = self.db.char.active_run_state
    if not state or not state.is_running then return end
    
    if state.start_time and (GetTime() - state.start_time) < 5 then return end

    local currentZone = GetRealZoneText()
    if state.zone_name and currentZone and currentZone ~= "" and not string.find(currentZone, state.zone_name, 1, true) then
        self:ShowHUD()
        self:ScheduleTimer(function() 
            local newZone = GetRealZoneText()
            if newZone and state.zone_name and not string.find(newZone, state.zone_name, 1, true) then
                if self.ShowRunOngoingPopup and not StaticPopup_Visible("STAUTIST_RUN_ONGOING") then 
                    self:ShowRunOngoingPopup() 
                end 
            end
        end, 2)
    end
end

function Stautist:CheckCombatDrop()
    local state = self.db.char.active_run_state
    if not state.is_running then return end

    -- Wipe Detection Logic
    if state.combat_boss_id then
        local groupSize = self:GetGroupSize()
        local deaths = state.combat_deaths or 0
        
        if self:IsGroupWiped() or (deaths > 0 and deaths >= (groupSize - 1)) then
            state.wipes = (state.wipes or 0) + 1
            self:Print("|cffff0000WIPE DETECTED!|r (Count: " .. state.wipes .. ")")
            if self.UpdateHUDWipes then self:UpdateHUDWipes(state.wipes) end 
        end
        
        -- AGGRESSIVE RESET: 
        -- If we dropped combat, and this function runs, it means the player is Regen Enabled (out of combat).
        -- If the boss was actually killed, OnBossKill would have already cleared 'combat_boss_id'.
        -- Therefore, if 'combat_boss_id' is still set here, it means the boss is ALIVE and we are OUT OF COMBAT.
        -- We must reset the timer immediately.
        
        state.current_fight_start = nil
        state.combat_boss_id = nil
        state.combat_deaths = 0
    end
end

function Stautist:StopRun(isComplete, reason)
    local state = self.db.char.active_run_state
    if not state.is_running then return end
    
    -- 1. Lockout Logic (Prevent immediate restart in same zone)
    if state.zone_id then
        self.suppress_auto_start_zone = state.zone_id
    end
    
    state.is_running = false
    self.debug_mode = false 
    
    local startTime = state.start_time or GetTime()
    local finalTime = GetTime() - startTime
    local zID = state.zone_id or 0
    local zoneName = state.zone_name or "Unknown Zone"
    if zID == 0 and self.currentZoneID then zID = self.currentZoneID end
    
    local roster = self:GetRosterSnapshot()
    local runTier = self:DetermineRunTier(roster)
    
    local bossesKilled = 0
    local totalBosses = 0
    if self.BossDB[zID] then
        for _ in pairs(self.BossDB[zID].bosses) do totalBosses = totalBosses + 1 end
        for _ in pairs(state.boss_kills or {}) do bossesKilled = bossesKilled + 1 end
    end

    local _, _, _, _, maxPlayers = GetInstanceInfo()
    
    local runData = {
        zone_id = zID,
        difficulty = state.difficulty or "Normal",
        size = maxPlayers, 
        total_time = finalTime,
        date = date("%d/%m/%y %H:%M"),
        timestamp = time(),
        success = isComplete,
        partial = (not isComplete),
        progress = bossesKilled .. "/" .. totalBosses,
        reason = reason or (isComplete and "Clear" or "Abort"),
        wipes = state.wipes or 0,
        tier = runTier,
        roster = roster,
        boss_kills = state.boss_kills
    }
    
    if not self.db.global.run_history then self.db.global.run_history = {} end
    table.insert(self.db.global.run_history, runData)

    if isComplete then
        self:Print("|cff00ff00Run Complete!|r " .. zoneName .. " - " .. self:FormatTime(finalTime))
        
        if self.ShakeHUD then self:ShakeHUD() end 
        local rank = 1
        local history = self.db.global.run_history
        local myTime = runData.total_time
        
        for _, oldRun in ipairs(history) do
            if oldRun ~= runData and oldRun.success and oldRun.zone_id == zID and oldRun.difficulty == runData.difficulty then
                if oldRun.total_time < myTime then rank = rank + 1 end
            end
        end
        
        local isPB = (rank == 1)
        if self.ShowRunSummary then self:ShowRunSummary(self:FormatTime(finalTime), rank, isPB) end

        if self.db.profile.announce_completion then
            local rankText = isPB and " (New PB!)" or (" (Rank " .. rank .. ")")
            local msg = string.format("<Stautist> %s cleared in %s!%s Wipes: %d", zoneName, self:FormatTime(finalTime), rankText, runData.wipes)
            local channel = (GetNumRaidMembers() > 0) and "RAID" or (GetNumPartyMembers() > 0) and "PARTY" or "PRINT"
            if channel == "PRINT" then self:Print(msg) else SendChatMessage(msg, channel) end
        end
    else
        self:Print("|cffff0000Run Ends.|r (" .. reason .. ")")
        if self.UpdateHUDText then self:UpdateHUDText("STOPPED") end
    end
    
    state.hud_forced = nil 
end

function Stautist:OnTimerUpdate(elapsed)
    local state = self.db.char.active_run_state
    if not state or not state.is_running then return end
    
    -- WAITING FOR COMBAT STATE
    if state.waiting_for_combat then
        self:UpdateHUDText("READY")
        if self.hudFrame and self.hudFrame.percentText then
            self.hudFrame.percentText:SetText("Pull to Start")
            self.hudFrame.percentText:SetTextColor(0.5, 0.5, 0.5)
        end
        return
    end
    
    -- RUNNING STATE
    local currentTime = GetTime() - (state.start_time or GetTime())
    
    local seconds = math.floor(currentTime)
    local minutes = math.floor(seconds / 60)
    local tenths = math.floor((currentTime - seconds) * 10)
    seconds = seconds - (minutes * 60)
    local formattedTime = string.format("%d:%02d.%d", minutes, seconds, tenths)
    
    self:UpdateHUDText(formattedTime)

    if self.hudFrame and self.hudFrame.percentText then
        local best = state.best_time_cache
        if best and best > 0 then
            local rawPct = (currentTime / best) * 100
            self.hudFrame.percentText:SetText(string.format("%.2f%%", rawPct))
            
            local stepPct = math.floor(rawPct / 5) * 5
            local r, g, b = 0, 1, 0
            if stepPct <= 50 then r = (stepPct / 50); g = 1
            elseif stepPct <= 100 then r = 1; g = 1 - ((stepPct - 50) / 50)
            else r = 1; g = 0 end
            self.hudFrame.percentText:SetTextColor(r, g, 0)
        else
            self.hudFrame.percentText:SetText("Running")
            self.hudFrame.percentText:SetTextColor(0, 1, 0)
        end
    end
    
    if state.pb_run_data and not state.splits_invalid then
        if self.UpdateLiveSplits then
            self:UpdateLiveSplits(currentTime, state.pb_run_data, state.boss_kills)
        end
    end
end

function Stautist:GetOrdinal(n)
    local suffix = "th"
    local last = n % 10
    local lastTwo = n % 100
    if lastTwo < 11 or lastTwo > 13 then
        if last == 1 then suffix = "st"
        elseif last == 2 then suffix = "nd"
        elseif last == 3 then suffix = "rd" end
    end
    return n .. suffix
end

function Stautist:FormatTime(seconds, precision)
    if not seconds then return "0:00" end
    local s = math.floor(seconds)
    local ms = math.floor((seconds - s) * 100) 
    local m = math.floor(s / 60)
    local h = math.floor(m / 60)
    s = s % 60
    m = m % 60
    
    local timeStr = ""
    if h > 0 then timeStr = string.format("%d:%02d:%02d", h, m, s)
    else timeStr = string.format("%d:%02d", m, s) end
    
    if precision then return string.format("%s.%02d", timeStr, ms)
    else return timeStr end
end

function Stautist:CHAT_MSG_SYSTEM(event, msg)
    if not msg then return end

    if string.find(msg, "has been reset") then
        self.db.char.reset_detected = true
        self.suppress_auto_start_zone = nil -- Allow starting again
    end

    if string.find(msg, "reset") then
        local state = self.db.char.active_run_state
        if state and state.is_running then
            self:StopRun(false, "Reset")
        end

        if self.db.profile.announce_resets ~= false then
            local outMsg = "<Stautist> Instance has been reset!"
            if GetNumRaidMembers() > 0 then SendChatMessage(outMsg, "RAID")
            elseif GetNumPartyMembers() > 0 then SendChatMessage(outMsg, "PARTY")
            else self:Print("Instance Reset Detected.") end
        end
    end
end

function Stautist:OnEnterInstance()
    self:CheckZoneStatus()
    self:ScheduleTimer("CheckZoneStatus", 1)
    self:ScheduleTimer("CheckZoneStatus", 3)
    self:ScheduleTimer("CheckZoneStatus", 6)

    local zoneName, instanceType = GetInstanceInfo()
    if instanceType == "party" or instanceType == "raid" then
        local now = time()
        local isReEntry = false
        local lastZone = self.db.char.last_instance_name
        local resetHappened = self.db.char.reset_detected
        
        if lastZone and zoneName == lastZone and not resetHappened then isReEntry = true end
        
        local logDB = self.db.char.instance_log or {}
        local lastEntry = logDB[#logDB]
        if lastEntry and (now - lastEntry.time) < 60 and lastEntry.name == zoneName then isReEntry = true end

        if not isReEntry then
            local entryData = { time = now, name = zoneName or GetZoneText() or "Unknown Zone", type = instanceType }
            if not self.db.char.instance_log then self.db.char.instance_log = {} end
            table.insert(self.db.char.instance_log, entryData)
            
            self.db.char.last_instance_name = zoneName
            self.db.char.reset_detected = false
            
            if self.CleanupInstanceLog then self:CleanupInstanceLog() end
            
            local count = #self.db.char.instance_log
            if count >= 4 then
                local oldest = self.db.char.instance_log[1]
                local timeLeft = 0
                if oldest then timeLeft = (oldest.time + 3600) - now end
                local m = math.floor(timeLeft / 60)
                local timeStr = string.format("%d min", m)
                local msg = ""
                if count == 4 then msg = string.format("<Stautist> Warning: 4/5 instances entered! Next slot opens in %s.", timeStr)
                elseif count >= 5 then msg = string.format("<Stautist> CRITICAL: 5/5 instances entered (LOCKED). Next slot opens in %s.", timeStr) end
                
                if GetNumRaidMembers() > 0 then SendChatMessage(msg, "RAID")
                elseif GetNumPartyMembers() > 0 then SendChatMessage(msg, "PARTY")
                else self:Print("|cffff0000" .. msg .. "|r") end
            end
        end
    end
end

function Stautist:CheckZoneStatus()
    if self.debug_mode then return end

    local zoneName, instanceType, difficultyIndex, difficultyName, maxPlayers = GetInstanceInfo()
    local state = self.db.char.active_run_state
    if not zoneName or zoneName == "" then return end

    -- 1. Lag Protection
    if state.is_running then
        if (not instanceType) or (instanceType == "none") then
            local currentZone = GetRealZoneText()
            if state.zone_name and currentZone and string.find(currentZone, state.zone_name, 1, true) then
                instanceType = "party"; zoneName = state.zone_name
            end
        end
    end

    -- 2. Outside Logic
    if instanceType ~= "party" and instanceType ~= "raid" then
        if state.is_running then
            -- Only hide if we actually left the instance area
            local currentZone = GetRealZoneText()
            if state.zone_name and currentZone and not string.find(currentZone, state.zone_name, 1, true) then
                 if not state.user_hidden_hud then self:ShowHUD() end
                 self:ScheduleTimer(function()
                     local z = GetRealZoneText()
                     local _, typeCheck = GetInstanceInfo()
                     if self.db.char.active_run_state.is_running and (typeCheck ~= "party" and typeCheck ~= "raid") and (z ~= state.zone_name) then
                         if self.ShowRunOngoingPopup and not StaticPopup_Visible("STAUTIST_RUN_ONGOING") then 
                             self:ShowRunOngoingPopup() 
                         end
                     end
                 end, 2)
            end
        else
            self.currentZoneID = nil
            self:HideHUD()
        end
        return
    end

    -- 3. ID Matching
    local dbID = nil
    
    -- A. Check Saved Run State (Resuming)
    if state.is_running and state.zone_id then
        local currentZone = GetRealZoneText()
        if (zoneName == state.zone_name) or (currentZone and state.zone_name and string.find(currentZone, state.zone_name, 1, true)) then
            dbID = state.zone_id
        end
    end

    -- B. Check Aliases (Exact Match Priority)
    -- This fixes CoT/Magisters if server uses alternate names
    if not dbID and self.ZoneAliases then
        if self.ZoneAliases[zoneName] then dbID = self.ZoneAliases[zoneName] end
        if not dbID then
            local realZ = GetRealZoneText()
            if realZ and self.ZoneAliases[realZ] then dbID = self.ZoneAliases[realZ] end
        end
    end

    -- C. Standard DB Name Match (zoneName)
    if not dbID and self.BossDB then
        for id, data in pairs(self.BossDB) do
            if data.name and zoneName and string.find(zoneName, data.name, 1, true) then
                dbID = id; break
            end
        end
    end
    
    -- D. Failsafe DB Match (GetRealZoneText)
    -- This fixes CoT where zoneName is "Caverns of Time" but RealZone is "Old Hillsbrad Foothills"
    if not dbID and self.BossDB then
        local realZ = GetRealZoneText()
        if realZ and realZ ~= zoneName then
            for id, data in pairs(self.BossDB) do
                if data.name and string.find(realZ, data.name, 1, true) then
                    dbID = id; break
                end
            end
        end
    end
    self.currentZoneID = dbID

    -- HEROIC CHECK (3.3.5a Logic: 2=5H, 5=10H, 6=25H)
    local isHeroic = (difficultyIndex == 2) or (difficultyIndex == 5) or (difficultyIndex == 6)
    if not isHeroic and difficultyName and string.find(difficultyName, "Heroic") then isHeroic = true end
    local diffString = isHeroic and "Heroic" or "Normal"

    local sameZone = (state.zone_id and state.zone_id == dbID)
    if state.is_running and sameZone and difficultyName and difficultyName ~= "" then
        if state.difficulty ~= diffString then self:HandleExternalReset("Inside Switch") end
    end

    -- 4. Start New Run (WAITING FOR COMBAT)
    if (not state.is_running or (dbID and state.zone_id ~= dbID)) and dbID then
        
        if self.suppress_auto_start_zone == dbID then return end

        state.is_running = true
        state.zone_id = dbID
        
        -- FORCE DB NAME (Fixes HUD Title for CoT instances)
        if self.BossDB[dbID] and self.BossDB[dbID].name then
            state.zone_name = self.BossDB[dbID].name
        else
            state.zone_name = zoneName
        end

        -- NEW: Do NOT set start_time yet.
        state.start_time = nil
        state.waiting_for_combat = true -- Flag to indicate we are waiting
        
        state.boss_kills = {} 
        state.difficulty = diffString
        state.gold_collected = 0
        state.wipes = 0
        state.current_fight_start = nil 
        state.splits_invalid = false
        state.hud_forced = nil
        state.user_hidden_hud = false 
        
        state.pb_run_data = nil
        local bestTimeFound = nil
        if self.db.global.run_history then
            local bestRun = nil
            for _, run in pairs(self.db.global.run_history) do
                if run.zone_id == dbID and run.difficulty == diffString and run.success then
                    if not bestRun or run.total_time < bestRun.total_time then bestRun = run end
                end
            end
            if bestRun then
                state.pb_run_data = bestRun
                bestTimeFound = bestRun.total_time
                self:Print("PB Loaded: " .. self:FormatTime(bestTimeFound))
            end
        end
        state.best_time_cache = bestTimeFound
        
        self:Print("Entered " .. zoneName .. ". Timer will start on COMBAT.")
        self:UpdateHUDText("READY") 
    end

    -- 5. HUD Logic & Building
    if state.is_running and (dbID or state.zone_id) then
        local activeID = dbID or state.zone_id
        
        if not self.hudFrame then self:CreateHUD() end
        if self.UpdateHUDLayout then self:UpdateHUDLayout() end
        if self.UpdateHUDWipes then self:UpdateHUDWipes(state.wipes or 0) end

        local needBuild = true
        local killCount = 0
        if state.boss_kills then for _ in pairs(state.boss_kills) do killCount = killCount + 1 end end
        
        if self.hudFrame.bossLines and next(self.hudFrame.bossLines) and killCount > 0 then
             local checkID = nil
             if self.BossDB[activeID] then for k,v in pairs(self.BossDB[activeID].bosses) do checkID = k; break end end
             if checkID and self.hudFrame.bossLines[checkID] then needBuild = false end
        end

        if needBuild and self.BossDB[activeID] then
            local bosses = {}
            local zoneData = self.BossDB[activeID]
            local seenEncounters = {} 
            local pbOrderMap = {}
            local usePBOrder = false
            
            if state.pb_run_data and state.pb_run_data.boss_kills then
                local sortedPB = {}
                for id, data in pairs(state.pb_run_data.boss_kills) do
                    table.insert(sortedPB, {id=tonumber(id), t=(data.split_time or 99999)})
                end
                table.sort(sortedPB, function(a,b) return a.t < b.t end)
                for i, v in ipairs(sortedPB) do pbOrderMap[v.id] = i end
                if #sortedPB > 0 then usePBOrder = true end
            end

            for npcID, data in pairs(zoneData.bosses) do
                local isHidden = (type(data)=="table" and data.hidden)
                
                -- HEROIC FILTER LOGIC
                local isHeroicOnly = (type(data)=="table" and data.heroicOnly)
                local skip = false
                if isHeroicOnly and (state.difficulty ~= "Heroic") then skip = true end

                if not isHidden and not skip then
                    local bName = (type(data)=="table" and data.name or data)
                    local bEncounter = (type(data)=="table" and data.encounter) or npcID
                    local bOrder = (type(data)=="table" and data.order) or 50
                    
                    if not seenEncounters[bEncounter] then
                        seenEncounters[bEncounter] = true
                        if usePBOrder and pbOrderMap[npcID] then bOrder = pbOrderMap[npcID]
                        elseif zoneData.end_boss_id and npcID == zoneData.end_boss_id then bOrder = 500 
                        elseif type(data) ~= "table" then bOrder = 200 end
                        table.insert(bosses, { id = npcID, name = bName, order = bOrder, encounter = bEncounter })
                    end
                end
            end
            
            table.sort(bosses, function(a,b) 
                if a.order ~= b.order then return a.order < b.order end
                return a.id < b.id 
            end)
            
            if self.ClearBossList then self:ClearBossList() end 
            for _, b in ipairs(bosses) do self:AddBossToList(b.id, b.name, b.order) end
            
            -- Restore checkmarks if UI reloaded during run
            if state.boss_kills then
                for killID, killData in pairs(state.boss_kills) do
                    if self.SetBossCheckmark then self:SetBossCheckmark(killID, true) end
                    local key = killID
                    local zID = self.currentZoneID or state.zone_id
                    if zID and self.BossDB[zID] then
                        local b = self.BossDB[zID].bosses[killID]
                        if type(b) == "table" and b.encounter then key = b.encounter end
                    end
                    local row = self.hudFrame.bossLines[key]
                    if row then row.killTime = killData.time end
                end
            end
            if self.SortBossRows then self:SortBossRows() end
        end
        
        if self.SetDungeonTitle then
            local _, _, _, _, maxPlayers = GetInstanceInfo()
            local sizeTag = ""
            if instanceType == "raid" and maxPlayers then sizeTag = " (" .. maxPlayers .. ")" end
            local isHC = (state.difficulty == "Heroic")
            self:SetDungeonTitle(state.zone_name or zoneName, isHC, sizeTag)
        end
        
        local behavior = self.db.profile.hud_behavior or "Show"
        local forced = state.hud_forced
        
        if state.user_hidden_hud then
            self:HideHUD()
        else
            if behavior == "Show" then self:ShowHUD()
            elseif behavior == "Hide" then self:HideHUD()
            elseif behavior == "Ask" then
                if forced == nil then
                    StaticPopup_Show("STAUTIST_SHOW_HUD")
                    state.hud_forced = false 
                elseif forced == true then self:ShowHUD()
                else self:HideHUD() end
            end
        end
    end
end

function Stautist:HandleExternalReset(source)
    self:StopRun(false, "Reset")
    if self.db.profile.announce_resets ~= false then
        local msg = "<Stautist> Instance has been reset!"
        if GetNumRaidMembers() > 0 then SendChatMessage(msg, "RAID")
        elseif GetNumPartyMembers() > 0 then SendChatMessage(msg, "PARTY")
        else self:Print("Instance Reset Detected ("..source..").") end
    end
    self.db.char.active_run_state.is_running = false
end

function Stautist:GetRosterSnapshot()
    local roster = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    if numRaid == 0 and numParty == 0 then
        local name = UnitName("player")
        local _, class = UnitClass("player") 
        if name and class then table.insert(roster, { name = name, class = class, level = UnitLevel("player") }) end
        return roster
    end
    local prefix = (numRaid > 0) and "raid" or "party"
    local count = (numRaid > 0) and numRaid or numParty
    for i = 1, count do
        local unit = prefix .. i
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            table.insert(roster, { name = name, class = class or "UNKNOWN", level = UnitLevel(unit) or 0 })
        end
    end
    if prefix == "party" then
        local _, class = UnitClass("player")
        table.insert(roster, { name = UnitName("player"), class = class, level = UnitLevel("player") })
    end
    return roster
end

-- ============================================================================
-- COMBAT LOGIC
-- ============================================================================

function Stautist:OnBossKill(npcID, bossName, difficulty)
    local state = self.db.char.active_run_state
    
    if self.SetBossCheckmark then self:SetBossCheckmark(npcID, true) end
    
    local now = GetTime()
    local fightDuration = 0
    if state.current_fight_start then
        fightDuration = now - state.current_fight_start
        -- Failsafe: Ensure duration is never zero or negative (can happen due to GetTime() granularity)
        if fightDuration < 0.001 then fightDuration = 0.001 end
    else
        -- Fallback if current_fight_start was somehow missed for this boss
        self:Print(string.format("|cffffcc00[Stautist Warning]|r No combat start time for %s. Using 0s duration.", bossName or npcID))
        fightDuration = 0 -- Default to 0 if fight start wasn't recorded
    end
    local runSplit = 0
    if state.start_time then runSplit = now - state.start_time end

    local splitDiff = nil
    if not state.splits_invalid and state.pb_run_data and state.pb_run_data.boss_kills then
        local status, err = pcall(function()
            local pbKills = state.pb_run_data.boss_kills
            local pbBossData = pbKills[npcID] or pbKills[tostring(npcID)]
            if pbBossData then
                local currentOrder = {}
                for id, data in pairs(state.boss_kills) do 
                    if data and data.time then table.insert(currentOrder, {id=tonumber(id), val=data.time}) end
                end
                table.insert(currentOrder, {id=npcID, val=now}) 
                table.sort(currentOrder, function(a,b) return a.val < b.val end)
                
                local pbOrder = {}
                for id, data in pairs(pbKills) do 
                    if data then table.insert(pbOrder, {id=tonumber(id), val=(data.split_time or 0)}) end
                end
                table.sort(pbOrder, function(a,b) return a.val < b.val end)
                
                local currentIndex = #currentOrder
                if currentIndex <= #pbOrder then
                    local pbBoss = pbOrder[currentIndex]
                    local curBoss = currentOrder[currentIndex]
                    if pbBoss and curBoss and pbBoss.id ~= curBoss.id then
                        state.splits_invalid = true
                        if self.ClearSplits then self:ClearSplits() end
                    elseif pbBossData.split_time then
                        splitDiff = runSplit - pbBossData.split_time
                    end
                else state.splits_invalid = true end
            end
        end)
        if not status then state.splits_invalid = true end
    end

    if state.is_running then
        local isHC = false
        if difficulty then isHC = (difficulty >= 2) else
             local _, _, diffIndex = GetInstanceInfo()
             isHC = (diffIndex == 2 or diffIndex == 5 or diffIndex == 6)
        end

        state.boss_kills[npcID] = {
            time = now,
            name = bossName,
            heroic = isHC,
            duration = fightDuration,
            split_time = runSplit
        }
        
        if not state.splits_invalid and self.UpdateHUDSplit and splitDiff then
            self:UpdateHUDSplit(npcID, splitDiff)
        end
    end
    
    state.current_fight_start = nil
    state.combat_boss_id = nil
    state.combat_deaths = 0

    if self.db.profile.announce_fastest_kill and fightDuration > 0 then
        self:CheckFastestKill(npcID, fightDuration, bossName, state.difficulty)
    end

    local zID = self.currentZoneID or (self.NPC_TO_ZONE and self.NPC_TO_ZONE[npcID])
    if zID and self.BossDB[zID] then
        local zoneData = self.BossDB[zID]
        if zoneData.end_boss_id and npcID == zoneData.end_boss_id then
            self:Print("|cff00ff00VICTORY!|r " .. (bossName or "End Boss") .. " defeated.")
            self:StopRun(true)
        else
            local durStr = self:FormatTime(fightDuration)
            self:Print(string.format("Boss Defeated: %s (Combat: %s)", (bossName or npcID), durStr))
        end
    end
end

function Stautist:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
    -- Ace3 Event Shim
    if type(event) == "table" then 
        local _
        subEvent = timestamp
        sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = subEvent, sourceGUID, sourceName, destGUID, destName, destFlags
        -- Capture varargs for spell info
        -- Note: In Ace3 passed events, '...' contains the rest of the payload starting after destFlags
    end
    
    local state = self.db.char.active_run_state
    if not state.is_running then return end

    -- 1. START TIMER LOGIC (Trigger on Combat)
    if state.waiting_for_combat then
        local isHostile = false
        
        -- A. Damage Events (Swing, Range, Spell, Periodic)
        if subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE" or (subEvent and subEvent:find("_DAMAGE")) then
            isHostile = true
        
        -- B. Debuff Application (Strict Check)
        elseif subEvent == "SPELL_AURA_APPLIED" then
            -- For 3.3.5: arg9=spellId, arg10=spellName, arg11=spellSchool, arg12=auraType
            local _, _, _, auraType = ...
            if auraType == "DEBUFF" then
                isHostile = true
            end
        end
        
        if isHostile then
             -- Check if Player/Pet is involved (using BitMasks, safer than API calls)
             local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
             local COMBATLOG_OBJECT_TYPE_PET    = COMBATLOG_OBJECT_TYPE_PET or 0x00001000
             local COMBATLOG_OBJECT_TYPE_GUARDIAN = COMBATLOG_OBJECT_TYPE_GUARDIAN or 0x00002000

             local function IsFriendly(flags)
                if not flags then return false end
                return (bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0) or
                       (bit.band(flags, COMBATLOG_OBJECT_TYPE_PET) > 0) or
                       (bit.band(flags, COMBATLOG_OBJECT_TYPE_GUARDIAN) > 0)
             end

             if IsFriendly(sourceFlags) or IsFriendly(destFlags) then
                 state.waiting_for_combat = false
                 state.start_time = GetTime()
                 self:Print("|cff00ff00Combat Started! Timer Running.|r")
                 
                 if self.ShakeHUD then self:ShakeHUD() end
             end
        end
    end

    -- 2. BOSS LOGIC
    local bossID, bossName
    if self.BossDB and self.currentZoneID then
        local sID = tonumber(sourceGUID:sub(9, 12), 16)
        local dID = tonumber(destGUID:sub(9, 12), 16)
        local zoneBosses = self.BossDB[self.currentZoneID].bosses
        if sID and zoneBosses[sID] then bossID = sID; bossName = sourceName 
        elseif dID and zoneBosses[dID] then bossID = dID; bossName = destName end
    end

    if bossID then
        local bData = self.BossDB[self.currentZoneID].bosses[bossID]
        
        -- DYNAMIC RENAME
        if type(bData) == "table" then
            if bData.encounter then
                 if self.UpdateRowName then self:UpdateRowName(bData.encounter, bData.name) end
            elseif bData.hidden and self.currentZoneID == 608 then
                 if self.hudFrame and self.hudFrame.bossLines then
                     local row1 = self.hudFrame.bossLines["vh_1"]
                     local row2 = self.hudFrame.bossLines["vh_2"]
                     if row1 and row1.name:GetText() == "Portal Boss 1" then
                         self:UpdateRowName("vh_1", bData.name)
                     elseif row1 and row1.name:GetText() == bData.name then
                         -- Already assigned to 1
                     elseif row2 and row2.name:GetText() == "Portal Boss 2" then
                         self:UpdateRowName("vh_2", bData.name)
                     end
                 end
            end
        end

        -- BOSS FIGHT TIMER LOGIC
        -- Re-using isHostile check logic but simpler for Boss tracking
        local isAction = (subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE" or (subEvent and subEvent:find("_DAMAGE")) or subEvent == "SPELL_AURA_APPLIED")
        
        local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
        local sIsPlayer = sourceFlags and (bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0)
        local dIsPlayer = destFlags and (bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0)

        if isAction and (sIsPlayer or dIsPlayer) then
            if not state.current_fight_start or state.combat_boss_id ~= bossID then
                state.current_fight_start = GetTime()
                state.combat_boss_id = bossID 
                state.combat_deaths = 0
            end
        end
    end
    
    if subEvent == "UNIT_DIED" then
        if destName and UnitIsPlayer(destName) then
            if state.combat_boss_id then state.combat_deaths = (state.combat_deaths or 0) + 1 end
        else
            local npcID = tonumber(destGUID:sub(9, 12), 16)
            if self.currentZoneID and self.BossDB[self.currentZoneID].bosses[npcID] then
                self:OnBossKill(npcID, destName)
            end
        end
    end
end

function Stautist:CheckFastestKill(npcID, duration, name, difficulty)
    local bestDuration = 99999
    local hasHistory = false
    
    if self.db.global.run_history then
        for _, run in ipairs(self.db.global.run_history) do
            if run.boss_kills and run.difficulty == difficulty then
                local k = run.boss_kills[npcID]
                if k and k.duration and k.duration > 0 then
                    hasHistory = true
                    if k.duration < bestDuration then bestDuration = k.duration end
                end
            end
        end
    end

    if duration < bestDuration then
        local diff = bestDuration - duration
        local msg = ""
        -- If it's the first kill ever, we don't announce a "Record" unless you want to.
        -- Assuming we only want to compare against previous data:
        if hasHistory and bestDuration ~= 99999 then
             -- Added 'true' to FormatTime for precision
             msg = string.format("NEW RECORD! %s killed in %s (-%s)", name, self:FormatTime(duration, true), self:FormatTime(diff, true))
             
             local channel = (GetNumRaidMembers() > 0) and "RAID" or (GetNumPartyMembers() > 0) and "PARTY" or "PRINT"
             if channel == "PRINT" then self:Print(msg) else SendChatMessage("<Stautist> " .. msg, channel) end
        end
    end
end