-- Stautist Comm Module
local addonName, addonTable = ...
local Stautist = LibStub("AceAddon-3.0"):GetAddon("Stautist")
local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")





Stautist.COMM_PREFIX = "StautistSync"

function Stautist:SetupComm()
    self:RegisterComm(self.COMM_PREFIX, "OnCommReceived")
    self.sync_status = {} -- Stores the status of the current sync operation
end

-- ============================================================================
-- SENDER LOGIC (The "Sync" Button)
-- ============================================================================

function Stautist:StartGuildSync()
    if UnitAffectingCombat("player") then 
        self:Print("Error: You are in combat. Sync aborted.")
        return 
    end
    if not IsInGuild() then
        self:Print("Error: You are not in a guild.")
        return
    end

    self:CreateSyncWindow() 
    self:LogSync("--- Starting Sync (v" .. self.VERSION .. ") ---")
    self.sync_status = {}
    
    local numMembers = GetNumGuildMembers()
    local onlineCount = 0
    for i = 1, numMembers do
        local name, _, _, _, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
        if online and name then
            -- Note: name in 3.3.5 might be "Name-Server", we strip it for the internal key
            local shortName = self:GetShortName(name)
            if shortName ~= UnitName("player") then
                self.sync_status[shortName] = { status = "Waiting...", class = class }
                onlineCount = onlineCount + 1
            end
        end
    end

    if onlineCount == 0 then
        self:LogSync("No other guild members online.")
        return
    end

    self:LogSync("Pinging " .. onlineCount .. " members...")
    -- Send PING with our version
    local payload = AceSerializer:Serialize("PING", self.VERSION)
    self:SendCommMessage(self.COMM_PREFIX, payload, "GUILD")
    self:UpdateSyncLogDisplay()
    self:ScheduleTimer("FinishGuildSync", 5)
end


function Stautist:FinishGuildSync()
    local countSuccess = 0
    local countNoAddon = 0
    
    for name, info in pairs(self.sync_status) do
        if info.status == "Waiting..." then
            info.status = "|cff888888No Addon|r"
            countNoAddon = countNoAddon + 1
        elseif info.status == "Success" then
            countSuccess = countSuccess + 1
        end
    end
    
    self:LogSync("--- Sync Complete ---")
    self:LogSync(string.format("Updated: %d | No Addon: %d", countSuccess, countNoAddon))
    self:UpdateSyncLogDisplay()
    
    -- Refresh the Guild Tab List
    self:RefreshGuildLeaderboard()
end

-- ============================================================================
-- RECEIVER LOGIC (The Guildmates)
-- ============================================================================

function Stautist:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= self.COMM_PREFIX then return end
    sender = self:GetShortName(sender)
    if sender == UnitName("player") then return end 

    -- We now expect success, type, remoteVersion, and then the data
    local success, type, remoteVersion, data = AceSerializer:Deserialize(message)
    if not success then return end

    -- Handle Version Check
    if self.sync_status[sender] then
        if remoteVersion ~= self.VERSION then
            self.sync_status[sender].status = "|cffff0000Outdated (v" .. (remoteVersion or "???") .. ")|r"
            self:UpdateSyncLogDisplay()
            -- If they pinged us with an old version, don't reply to avoid crashing them
            if type == "PING" then return end 
        end
    end

    if type == "PING" then
    if UnitAffectingCombat("player") then
        -- FIX: Added self.VERSION to the BUSY reply
        local reply = AceSerializer:Serialize("BUSY", self.VERSION)
        self:SendCommMessage(self.COMM_PREFIX, reply, "WHISPER", sender)
    else
            self:ScheduleTimer(function() self:SendMyData(sender) end, math.random(0.1, 1.5))
        end
    elseif type == "BUSY" then
        if self.sync_status[sender] then
            self.sync_status[sender].status = "|cffffaa00In Combat|r"
            self:UpdateSyncLogDisplay()
        end
    elseif type == "DATA" then
        if self.sync_status[sender] then
            self.sync_status[sender].status = "|cff00ff00Success|r"
            -- Data is the 4th return from Deserialize now
            self:ProcessIncomingData(sender, data)
            self:UpdateSyncLogDisplay()
        end
    end
end

function Stautist:SendMyData(target)
    local dataToSend = {}
    local _, myClass = UnitClass("player")
    local myName = UnitName("player")

    -- 1. Package MY PBs
    if self.db.global.run_history then
        for _, run in ipairs(self.db.global.run_history) do
            if run.success and run.total_time and run.total_time > 0 and run.zone_id then
                local key = run.zone_id .. "_" .. (run.difficulty or "Normal")
                if not dataToSend[myName] then dataToSend[myName] = {} end
                if not dataToSend[myName][key] or run.total_time < dataToSend[myName][key].t then
                    dataToSend[myName][key] = {
                        z = run.zone_id, d = run.difficulty or "Normal",
                        t = run.total_time, dt = run.date,
                        l = self:GetMaxLevel(run.roster), s = run.size or 5, c = myClass
                    }
                end
            end
        end
    end

    -- 2. Package EVERYTHING I know about the guild (Chain Sync)
    if self.db.global.guild_cache then
        for guildieName, pbs in pairs(self.db.global.guild_cache) do
            if guildieName ~= myName and guildieName ~= target then
                dataToSend[guildieName] = pbs
            end
        end
    end

    local payload = AceSerializer:Serialize("DATA", self.VERSION, dataToSend)
    self:SendCommMessage(self.COMM_PREFIX, payload, "WHISPER", target)
end




function Stautist:GetMaxLevel(roster)
    if not roster then return 80 end
    local maxLvl = 0
    for _, p in ipairs(roster) do
        if p.level and p.level > maxLvl then maxLvl = p.level end
    end
    return (maxLvl > 0) and maxLvl or 80
end

-- ============================================================================
-- DATA PROCESSING
-- ============================================================================

function Stautist:ProcessIncomingData(sender, data)
    if not data or type(data) ~= "table" then return end
    if not self.db.global.guild_cache then self.db.global.guild_cache = {} end
    
    for playerName, pbs in pairs(data) do
        if playerName ~= UnitName("player") then -- Don't let others overwrite my own local data
            if not self.db.global.guild_cache[playerName] then self.db.global.guild_cache[playerName] = {} end
            for key, runInfo in pairs(pbs) do
                -- Only save if it's a better time than what we currently have for that player
                local current = self.db.global.guild_cache[playerName][key]
                if not current or runInfo.t < current.t then
                    self.db.global.guild_cache[playerName][key] = runInfo
                end
            end
        end
    end
end

-- ============================================================================
-- UI HELPERS
-- ============================================================================

function Stautist:LogSync(msg)
    if self.syncLogBox then
        local current = self.syncLogBox:GetText() or ""
        self.syncLogBox:SetText(current .. msg .. "\n")
        -- Scroll to bottom hack
        self.syncLogBox:SetCursorPosition(string.len(self.syncLogBox:GetText()))
    end
end

function Stautist:UpdateSyncLogDisplay()
    if not self.syncLogBox then return end
    
    local txt = "--- Sync Status ---\n"
    for name, info in pairs(self.sync_status) do
        local color = "|cffffffff" -- White
        -- Add Class Color to name
        local cObj = RAID_CLASS_COLORS[info.class]
        if cObj then 
            name = string.format("|cff%02x%02x%02x%s|r", cObj.r*255, cObj.g*255, cObj.b*255, name)
        end
        
        txt = txt .. name .. ": " .. info.status .. "\n"
    end
    self.syncLogBox:SetText(txt)
end