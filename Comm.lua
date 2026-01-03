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

    -- 1. SHOW POPUP
    self:CreateSyncWindow() 
    
    -- 2. INITIALIZE
    self:LogSync("--- Starting Sync ---")
    self.sync_status = {}
    
    -- 3. Snapshot Online Guild Members
    local numMembers = GetNumGuildMembers()
    local onlineCount = 0
    for i = 1, numMembers do
        local name, rank, _, level, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
        if online and name ~= UnitName("player") then
            self.sync_status[name] = { status = "Waiting...", class = class }
            onlineCount = onlineCount + 1
        end
    end

    if onlineCount == 0 then
        self:LogSync("No other guild members online.")
        return
    end

    self:LogSync("Pinging " .. onlineCount .. " online members...")
    
    -- 4. Send Ping
    local payload = AceSerializer:Serialize("PING", "1.0")
    self:SendCommMessage(self.COMM_PREFIX, payload, "GUILD")

    -- 5. Update Log Window immediately
    self:UpdateSyncLogDisplay()

    -- 6. Schedule Timeout (5 Seconds)
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
    if sender == UnitName("player") then return end -- Ignore self

    local success, type, data = AceSerializer:Deserialize(message)
    if not success then return end

    -- CASE 1: WE RECEIVED A PING (Someone wants our data)
    if type == "PING" then
    if UnitAffectingCombat("player") then
            -- Tell them we are busy
            local reply = AceSerializer:Serialize("BUSY")
            self:SendCommMessage(self.COMM_PREFIX, reply, "WHISPER", sender)
        else
            -- Send our PBs
            -- Wait a random tiny bit to prevent flooding the sender
            local delay = math.random() * 2.0 -- 0 to 2 seconds
            self:ScheduleTimer(function() 
                self:SendMyData(sender)
            end, delay)
        end
        return
    end

    -- CASE 2: WE RECEIVED A BUSY SIGNAL
    if type == "BUSY" then
        if self.sync_status[sender] then
            self.sync_status[sender].status = "|cffff0000In Combat|r"
            self:UpdateSyncLogDisplay()
        end
        return
    end

    -- CASE 3: WE RECEIVED DATA
    if type == "DATA" then
        if self.sync_status[sender] then
            self.sync_status[sender].status = "|cff00ff00Success|r"
            self:ProcessIncomingData(sender, data)
            self:UpdateSyncLogDisplay()
        end
        return
    end
end

function Stautist:SendMyData(target)
    local pbs = {}
    local _, myClass = UnitClass("player") -- GET MY CLASS

    if self.db.global.run_history then
        for _, run in ipairs(self.db.global.run_history) do
            if run.success and run.total_time and run.zone_id then
                local key = run.zone_id .. "_" .. (run.difficulty or "Normal")
                
                if not pbs[key] or run.total_time < pbs[key].time then
                    pbs[key] = {
                        z = run.zone_id,
                        d = run.difficulty or "Normal",
                        t = run.total_time,
                        dt = run.date,
                        l = self:GetMaxLevel(run.roster),
                        s = run.size or 5,
                        c = myClass -- SEND CLASS
                    }
                end
            end
        end
    end
    local payload = AceSerializer:Serialize("DATA", pbs)
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
    
    -- Ensure sender entry exists
    if not self.db.global.guild_cache[sender] then 
        self.db.global.guild_cache[sender] = {} 
    end
    
    -- Merge Data
    -- data is { ["604_Heroic"] = {z=604, d="Heroic", t=900, dt="..", l=80} }
    for key, runInfo in pairs(data) do
        -- We just overwrite local cache with their reported PBs
        self.db.global.guild_cache[sender][key] = runInfo
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