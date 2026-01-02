print("|cff00ff00[Stautist DEBUG]|r HUD.lua loading...")

-- ============================================================================
-- HUD (Heads-Up Display) - Rev 6: Consolidated & Fixed
-- ============================================================================
local Stautist = LibStub("AceAddon-3.0"):GetAddon("Stautist")
local FONT = "Fonts\\FRIZQT__.TTF"

-- ============================================================================
-- 1. UTILITIES
-- ============================================================================

local function ShakeFrame(obj)
    if not obj then return end
    if obj.isShaking then return end
    obj.isShaking = true
    
    local duration = 0.5
    local intensity = 5
    local elapsed = 0
    
    -- Capture original position
    local point, relTo, relPoint, xOfs, yOfs = obj:GetPoint()
    if not point then 
        obj.isShaking = false
        return 
    end
    
    if not obj.shakeHandler then
        obj.shakeHandler = CreateFrame("Frame", nil, obj:GetParent() or UIParent)
    end
    
    obj.shakeHandler:SetScript("OnUpdate", function(self, el)
        elapsed = elapsed + el
        if elapsed >= duration then
            obj:SetPoint(point, relTo, relPoint, xOfs, yOfs)
            obj.isShaking = false
            self:SetScript("OnUpdate", nil)
            return
        end
        
        local offset = math.sin(elapsed * 30) * intensity * (1 - (elapsed/duration))
        obj:SetPoint(point, relTo, relPoint, xOfs + offset, yOfs)
    end)
end

local function FlashFrame(frame, duration)
    if not frame then return end
    if frame:IsShown() and frame:GetAlpha() == 1 then return end 
    
    if UIFrameFadeIn then
        UIFrameFadeIn(frame, 0.3, 0, 1)
    else
        frame:Show()
        frame:SetAlpha(1)
    end
    
    local t = 0
    local limit = duration or 2
    local f = frame.flashHandler or CreateFrame("Frame", nil, frame)
    frame.flashHandler = f
    
    f:SetScript("OnUpdate", function(self, el)
        t = t + el
        if t > limit then
            if UIFrameFadeOut then UIFrameFadeOut(frame, 0.5, 1, 0) else frame:Hide() end
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- ============================================================================
-- 2. HUD CREATION
-- ============================================================================

function Stautist:CreateHUD()
    if self.hudFrame then return end

    local TITLE_FONT = self.db.profile.font_title or "Fonts\\FRIZQT__.TTF"
    local MAIN_FONT = "Interface\\AddOns\\Stautist\\Fonts\\PTSans.ttf"
    local SCALE = self.db.profile.timer_scale or 1.0

    local frame = CreateFrame("Frame", "StautistHUD", UIParent)
    local baseWidth = self.db.profile.hud_width or 240
    frame:SetSize(baseWidth, 200)
    local pos = self.db.profile.timer_pos
    frame:SetPoint(pos.a, pos.p, pos.a, pos.x, pos.y)
    frame:SetScale(SCALE)
    frame:SetClampedToScreen(true)

    -- BACKDROP
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    frame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not Stautist.db.profile.timer_locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); Stautist:SaveHUDPosition(self) end)
    
    -- Animation Logic
    frame.currentWidth = baseWidth
    frame.targetWidth = baseWidth
    frame.glowTimer = 0
    frame.glowState = 0
    frame.nextGlowTime = math.random(5, 15)
    
    frame:SetScript("OnUpdate", function(self, elapsed)
        -- Width Smooth
        if math.abs(self.currentWidth - self.targetWidth) > 0.1 then
            local speed = 10 * elapsed 
            self.currentWidth = self.currentWidth + (self.targetWidth - self.currentWidth) * speed
            self:SetWidth(self.currentWidth)
        end
        -- Glow
        if self.dungeonNameGlow then
            if self.glowState == 1 then 
                self.glowTimer = self.glowTimer + elapsed
                local alpha = self.glowTimer / 1.5
                if alpha >= 1 then alpha = 1; self.glowState = 2; self.glowTimer = 0 end
                self.dungeonNameGlow:SetAlpha(alpha)
            elseif self.glowState == 2 then 
                self.glowTimer = self.glowTimer + elapsed
                local alpha = 1 - (self.glowTimer / 1.5)
                if alpha <= 0 then alpha = 0; self.glowState = 0; self.glowTimer = 0; self.nextGlowTime = math.random(5, 15) end
                self.dungeonNameGlow:SetAlpha(alpha)
            else 
                self.glowTimer = self.glowTimer + elapsed
                if self.glowTimer >= self.nextGlowTime then self.glowState = 1; self.glowTimer = 0 end
            end
        end
    end)

    -- Elements
    frame.header = frame:CreateTexture(nil, "ARTWORK")
    frame.header:SetPoint("TOPLEFT", 3, -3)
    frame.header:SetPoint("TOPRIGHT", -3, -3)
    frame.header:SetHeight(60) 
    frame.header:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.header:SetVertexColor(0.2, 0.2, 0.2, 0.8) 

    frame.gearBtn = CreateFrame("Button", nil, frame)
    frame.gearBtn:SetSize(16, 16)
    frame.gearBtn:SetPoint("TOPLEFT", 8, -8)
    frame.gearBtn:SetNormalTexture("Interface\\WorldMap\\Gear_64")
    frame.gearBtn:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
    frame.gearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    frame.gearBtn:SetScript("OnClick", function() Stautist:OpenConfigWindow() end)

    frame.dungeonName = frame:CreateFontString(nil, "OVERLAY")
    frame.dungeonName:SetFont(TITLE_FONT, 28, "OUTLINE") 
    frame.dungeonName:SetPoint("TOP", 0, -25)
    frame.dungeonName:SetTextColor(1, 1, 1)

    frame.dungeonNameGlow = frame:CreateFontString(nil, "OVERLAY")
    frame.dungeonNameGlow:SetFont(TITLE_FONT, 28, "THICKOUTLINE") 
    frame.dungeonNameGlow:SetPoint("CENTER", frame.dungeonName, "CENTER", 0, 0)
    frame.dungeonNameGlow:SetTextColor(1, 1, 1)
    frame.dungeonNameGlow:SetAlpha(0) 

    frame.heroicIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.heroicIcon:SetSize(24, 24)
    frame.heroicIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    frame.heroicIcon:Hide()

    frame.mainTimer = frame:CreateFontString(nil, "OVERLAY")
    frame.mainTimer:SetFont(MAIN_FONT, 20, "OUTLINE")

    frame.starIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.starIcon:SetSize(32, 32)
    frame.starIcon:SetTexture("Interface\\Cooldown\\star4")
    frame.starIcon:SetBlendMode("ADD")
    frame.starIcon:Hide()

    frame.percentText = frame:CreateFontString(nil, "OVERLAY")
    frame.percentText:SetFont(MAIN_FONT, 30, "OUTLINE") 
    
    frame.wipeText = frame:CreateFontString(nil, "OVERLAY")
    frame.wipeText:SetFont(MAIN_FONT, 12, "OUTLINE")
    frame.wipeText:SetTextColor(1, 0.2, 0.2)

    -- Container for Boss List
    frame.bossContainer = CreateFrame("Frame", nil, frame)
    frame.bossContainer:SetWidth(baseWidth)
    frame.bossContainer:SetHeight(1)

    frame.timeToBeat = frame:CreateFontString(nil, "OVERLAY")
    frame.timeToBeat:SetFont(MAIN_FONT, 10, "OUTLINE")
    frame.timeToBeat:SetTextColor(0.6, 0.6, 0.6)
    frame.timeToBeat:SetPoint("BOTTOM", 0, 8)

    frame.bossLines = {} 
    self.hudFrame = frame
    
    self:UpdateHUDLayout()
    
    -- Failsafe: Ensure HideHUD exists before calling
    if self.HideHUD then self:HideHUD() else frame:Hide() end
end

-- ============================================================================
-- 3. LAYOUT & SORTING
-- ============================================================================

function Stautist:UpdateHUDLayout()
    if not self.hudFrame then return end
    
    local showWipes = self.db.profile.show_wipes
    local width = self.db.profile.hud_width or 240
    
    -- Width Update
    self.hudFrame.targetWidth = width
    if self.hudFrame.bossContainer then self.hudFrame.bossContainer:SetWidth(width) end

    -- Stacking Calculation
    local currentY = -70 -- Below header padding
    
    -- Timer
    self.hudFrame.mainTimer:ClearAllPoints()
    self.hudFrame.mainTimer:SetPoint("TOP", 0, currentY)
    self.hudFrame.starIcon:ClearAllPoints()
    self.hudFrame.starIcon:SetPoint("LEFT", self.hudFrame.mainTimer, "RIGHT", 5, 0)
    currentY = currentY - 25

    -- Percent
    self.hudFrame.percentText:ClearAllPoints()
    self.hudFrame.percentText:SetPoint("TOP", 0, currentY)
    currentY = currentY - 35

    -- Wipes
    if showWipes then
        self.hudFrame.wipeText:Show()
        self.hudFrame.wipeText:ClearAllPoints()
        self.hudFrame.wipeText:SetPoint("TOP", 0, currentY)
        currentY = currentY - 18
    else
        self.hudFrame.wipeText:Hide()
    end

    -- Boss Container Anchor
    self.hudFrame.bossContainer:ClearAllPoints()
    self.hudFrame.bossContainer:SetPoint("TOP", self.hudFrame, "TOP", 0, currentY - 10)
    
    -- Update Row Widths
    if self.hudFrame.bossLines then
        for _, row in pairs(self.hudFrame.bossLines) do
            row:SetWidth(width - 20)
            if row.name then row.name:SetWidth(width - 70) end
            if self.db.profile.show_splits then row.split:Show() else row.split:Hide() end
        end
    end

    self:SortBossRows()
end

function Stautist:UpdateHUDHeight()
    if not self.hudFrame then return end

    local headerUsed = 135 
    if self.db.profile.show_wipes then headerUsed = headerUsed + 18 end

    local listHeight = 0
    if self.hudFrame.bossLines then
        for _, row in pairs(self.hudFrame.bossLines) do
            if row:IsShown() then
                listHeight = listHeight + row:GetHeight() + 2
            end
        end
    end
    
    local footerHeight = 30 
    self.hudFrame:SetHeight(headerUsed + listHeight + footerHeight)
end

function Stautist:SortBossRows()
    if not self.hudFrame or not self.hudFrame.bossLines then return end

    local rows = {}
    for _, row in pairs(self.hudFrame.bossLines) do
        if row:IsShown() then table.insert(rows, row) end
    end

    -- DYNAMIC SORT LOGIC
    table.sort(rows, function(a, b)
        local aKilled = (a.killTime and a.killTime > 0)
        local bKilled = (b.killTime and b.killTime > 0)

        -- 1. If both killed, sort by TIME (Earliest kill first)
        if aKilled and bKilled then
            return a.killTime < b.killTime
        end

        -- 2. Killed always above Alive
        if aKilled and not bKilled then return true end
        if not aKilled and bKilled then return false end

        -- 3. Alive Bosses: End Boss Logic
        local zData = Stautist.BossDB and Stautist.BossDB[Stautist.currentZoneID]
        local endID = zData and zData.end_boss_id
        local aIsEnd = (endID and a.npcID == endID)
        local bIsEnd = (endID and b.npcID == endID)
        
        if aIsEnd and not bIsEnd then return false end 
        if not aIsEnd and bIsEnd then return true end

        -- 4. Default: DB Order
        return (a.order or 99) < (b.order or 99)
    end)

    -- Stack Layout
    local currentY = 0
    for i, row in ipairs(rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.hudFrame.bossContainer, "TOPLEFT", 10, currentY)
        currentY = currentY - (row:GetHeight() + 2)
    end
    
    self:UpdateHUDHeight()
end

-- ============================================================================
-- 4. BOSS ROW MANAGEMENT
-- ============================================================================

function Stautist:AddBossToList(npcID, bossName, order)
    if not self.hudFrame then return end
    if not self.hudFrame.bossLines then self.hudFrame.bossLines = {} end

    local key = npcID
    local isEndBoss = false
    if self.BossDB and self.currentZoneID then
        local zoneData = self.BossDB[self.currentZoneID]
        if zoneData then
            if zoneData.end_boss_id and npcID == zoneData.end_boss_id then isEndBoss = true end
            local b = zoneData.bosses[npcID]
            if type(b) == "table" and b.encounter then key = b.encounter end
        end
    end

    local row = self.hudFrame.bossLines[key]
    if not row then
        row = CreateFrame("Frame", nil, self.hudFrame.bossContainer)
        local w = (self.db.profile.hud_width or 240) - 20
        row:SetSize(w, 20) 

        row.name = row:CreateFontString(nil, "ARTWORK")
        row.name:SetPoint("TOPLEFT", 0, 0)
        row.name:SetWidth(w - 50) 
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(true)
        row.name:SetNonSpaceWrap(true)

        row.split = row:CreateFontString(nil, "ARTWORK")
        row.split:SetPoint("TOPRIGHT", 0, 0)
        row.split:SetJustifyH("RIGHT")
        
        self.hudFrame.bossLines[key] = row
    end

    row:Show()
    row.npcID = npcID 
    row.order = order or 50
    row.encounterKey = key
    row.killTime = nil -- Reset kill time on add

    local fontPath = "Interface\\AddOns\\Stautist\\Fonts\\PTSans.ttf"
    if isEndBoss then
        row.name:SetFont(fontPath, 16, "THICKOUTLINE")
        row.name:SetTextColor(1, 0.2, 0.2)
    else
        row.name:SetFont(fontPath, 15, "OUTLINE")
        row.name:SetTextColor(0.9, 0.3, 0.3)
    end
    row.split:SetFont(fontPath, 15, "OUTLINE")

    local displayName = bossName or "Unknown"
    if #displayName > 18 and string.find(displayName, " the ") then
        displayName = displayName:gsub(" the ", "\nthe ")
    end
    row.name:SetText(displayName)
    
    local textHeight = row.name:GetStringHeight()
    local newHeight = math.max(20, textHeight + 2)
    row:SetHeight(newHeight)

    row.split:SetText("")
    
    if self.db.profile.show_splits then row.split:Show() else row.split:Hide() end
    
    self:SortBossRows()
end

function Stautist:ClearBossList()
    if not self.hudFrame then return end
    if self.hudFrame.bossLines then
        for _, line in pairs(self.hudFrame.bossLines) do
            line:Hide()
            line:ClearAllPoints()
            line.killTime = nil
            line.name:SetTextColor(0.9, 0.3, 0.3)
            line.split:SetText("")
        end
    end
    self:UpdateHUDHeight()
end

function Stautist:SetBossCheckmark(npcID, isKilled)
    if not self.hudFrame or not self.hudFrame.bossLines then return end

    local key = npcID
    if type(npcID) == "string" then key = npcID
    elseif self.currentZoneID and self.BossDB[self.currentZoneID] then
        local b = self.BossDB[self.currentZoneID].bosses[npcID]
        if type(b) == "table" and b.encounter then key = b.encounter end
    end

    local row = self.hudFrame.bossLines[key]
    if row and isKilled then
        row.name:SetTextColor(0.2, 1, 0.2)
        
        -- IMPORTANT: Set timestamp for sorting
        if not row.killTime then row.killTime = GetTime() end
        
        -- Force re-sort immediately
        self:SortBossRows()
    end
end

function Stautist:UpdateRowName(encounterKey, newName)
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    local row = self.hudFrame.bossLines[encounterKey]
    if row then
        local displayName = newName
        if #displayName > 18 and string.find(displayName, " the ") then
            displayName = displayName:gsub(" the ", "\nthe ")
        end
        row.name:SetText(displayName)
        
        local textHeight = row.name:GetStringHeight()
        local newHeight = math.max(20, textHeight + 2)
        row:SetHeight(newHeight)
        
        self:SortBossRows()
    end
end

-- ============================================================================
-- 5. CONTROLS & VISUALS
-- ============================================================================

function Stautist:ShowHUD()
    if not self.hudFrame then self:CreateHUD() end
    if self.hudFrame:IsShown() and self.hudFrame:GetAlpha() == 1 then return end
    
    if UIFrameFadeIn then
        UIFrameFadeIn(self.hudFrame, 0.5, 0, 1)
    else
        self.hudFrame:SetAlpha(1)
        self.hudFrame:Show()
    end
end

function Stautist:HideHUD()
    if self.hudFrame and self.hudFrame:IsShown() then
        if UIFrameFadeOut then
            local fadeInfo = {}
            fadeInfo.mode = "OUT"
            fadeInfo.timeToFade = 0.5
            fadeInfo.startAlpha = self.hudFrame:GetAlpha()
            fadeInfo.endAlpha = 0
            fadeInfo.finishedFunc = function() self.hudFrame:Hide() end
            UIFrameFade(self.hudFrame, fadeInfo)
        else
            self.hudFrame:Hide()
        end
    end
end

function Stautist:UpdateHUDText(text)
    if self.hudFrame and self.hudFrame.mainTimer then
        self.hudFrame.mainTimer:SetText(text)
    end
end

function Stautist:SaveHUDPosition(frame)
    local point, _, _, xOfs, yOfs = frame:GetPoint()
    if not point then return end
    self.db.profile.timer_pos = { a=point, p="UIParent", x=xOfs, y=yOfs }
end

function Stautist:SetDungeonTitle(name, isHeroic, sizeTag)
    if not self.hudFrame then return end
    local cleanName = name or "Unknown"
    local prefixes = { "Auchindoun: ", "Caverns of Time: ", "Coilfang Reservoir: ", "Hellfire Citadel: ", "Tempest Keep: ", "Scarlet Monastery: " }
    for _, p in ipairs(prefixes) do if string.find(cleanName, p) then cleanName = cleanName:gsub(p, "") break end end
    if cleanName == "Ahn'kahet: The Old Kingdom" then cleanName = "Ahn'kahet" end

    local fullText = cleanName .. (sizeTag or "")
    local tFont = self.db.profile.font_title or "Fonts\\FRIZQT__.TTF"
    
    self.hudFrame.dungeonName:SetFont(tFont, 28, "OUTLINE")
    self.hudFrame.dungeonName:SetText(fullText)
    if self.hudFrame.dungeonName:GetStringWidth() > 190 then self.hudFrame.dungeonName:SetFont(tFont, 22, "OUTLINE") end

    if self.hudFrame.dungeonNameGlow then
        local f, s, fl = self.hudFrame.dungeonName:GetFont()
        self.hudFrame.dungeonNameGlow:SetFont(f, s, "THICKOUTLINE")
        self.hudFrame.dungeonNameGlow:SetText(fullText)
    end

    if isHeroic then
        self.hudFrame.dungeonName:SetPoint("TOP", -12, -25)
        self.hudFrame.heroicIcon:SetPoint("LEFT", self.hudFrame.dungeonName, "RIGHT", 5, 0)
        self.hudFrame.heroicIcon:Show()
    else
        self.hudFrame.dungeonName:SetPoint("TOP", 0, -25)
        self.hudFrame.heroicIcon:Hide()
    end
    
    if self.hudFrame.dungeonNameGlow then self.hudFrame.dungeonNameGlow:SetPoint("CENTER", self.hudFrame.dungeonName, "CENTER", 0, 0) end
    
    local texPath = "Interface\\Buttons\\WHITE8X8"
    local texColor = {0.2, 0.2, 0.2}
    local texCoord = {0, 1, 0, 1}
    if self.BossDB and self.currentZoneID and self.BossDB[self.currentZoneID] then
        local texID = self.BossDB[self.currentZoneID].textureID
        if texID then
            texPath = "Interface\\AddOns\\Stautist\\Textures\\" .. texID .. ".tga"
            texColor = {1, 1, 1}
            texCoord = {0, 1, 0, 0.75}
        end
    end
    self.hudFrame.header:SetTexture(texPath)
    self.hudFrame.header:SetVertexColor(unpack(texColor))
    self.hudFrame.header:SetTexCoord(unpack(texCoord))
end

function Stautist:ShowRunSummary(timeStr, rank, isPB)
    if not self.hudFrame then return end
    self.hudFrame.mainTimer:SetText(timeStr)
    self.hudFrame.mainTimer:SetTextColor(1, 1, 1)
    if rank then
        self.hudFrame.percentText:SetText("Rank: " .. rank)
        if isPB then
            self.hudFrame.percentText:SetTextColor(1, 0.8, 0)
            self.hudFrame.starIcon:Show()
        else
            self.hudFrame.percentText:SetTextColor(0.7, 0.7, 0.7)
            self.hudFrame.starIcon:Hide()
        end
    else
        self.hudFrame.percentText:SetText("Stopped")
        self.hudFrame.percentText:SetTextColor(0.5, 0.5, 0.5)
        self.hudFrame.starIcon:Hide()
    end
end

function Stautist:UpdateHUDSplit(npcID, diffSeconds)
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    local key = npcID
    if not self.hudFrame.bossLines[key] and self.BossDB and self.currentZoneID then
         local b = self.BossDB[self.currentZoneID].bosses[npcID]
         if type(b) == "table" and b.encounter then key = b.encounter end
    end
    local row = self.hudFrame.bossLines[key]
    if row then
        local sign = (diffSeconds < 0) and "-" or "+"
        local absDiff = math.abs(diffSeconds)
        row.split:SetText(sign .. self:FormatTime(absDiff, true))
        if diffSeconds < 0 then row.split:SetTextColor(0, 1, 0) else row.split:SetTextColor(1, 0.2, 0.2) end
        if self.db.profile.show_splits then if self.ShakeHUD then ShakeFrame(row.split) end
        else row.split:Show(); row.split:SetAlpha(0); FlashFrame(row.split, 2) end
    end
end

function Stautist:UpdateHUDWipes(count)
    if not self.hudFrame then return end
    self.hudFrame.wipeText:SetText("Wipes: " .. count)
    if count > 0 then
        self.hudFrame.wipeText:SetTextColor(1, 0.2, 0.2)
        if self.db.profile.show_wipes then ShakeFrame(self.hudFrame.wipeText)
        else self.hudFrame.wipeText:Show(); self.hudFrame.wipeText:SetAlpha(0); FlashFrame(self.hudFrame.wipeText, 2) end
    else
        self.hudFrame.wipeText:SetTextColor(0.5, 0.5, 0.5)
    end
end

function Stautist:UpdateLiveSplits(runTime, pbData, currentKills)
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    if not self.db.profile.show_splits then return end
    local pbKills = pbData.boss_kills
    if not pbKills then return end

    local activeRows = {}
    for key, row in pairs(self.hudFrame.bossLines) do
        local npcID = row.npcID
        local isKilled = currentKills[npcID] or currentKills[tostring(npcID)]
        if not isKilled then table.insert(activeRows, row)
        else if row.split:GetText() and string.find(row.split:GetText(), "%.") then row.split:SetText("") end end
    end
    table.sort(activeRows, function(a,b) return (a.order or 99) < (b.order or 99) end)

    for i, row in ipairs(activeRows) do
        if i == 1 then
            local npcID = row.npcID
            local pbBossData = pbKills[npcID] or pbKills[tostring(npcID)]
            if pbBossData and pbBossData.split_time and pbBossData.split_time > 0 then
                local diff = runTime - pbBossData.split_time
                local sign = (diff < 0) and "-" or "+"
                local absDiff = math.abs(diff)
                row.split:SetText(sign .. self:FormatTime(absDiff))
                local percent = runTime / pbBossData.split_time
                local r, g, b = self:GetSplitColor(percent)
                row.split:SetTextColor(r, g, b)
            else row.split:SetText("..."); row.split:SetTextColor(0.5, 0.5, 0.5) end
        else row.split:SetText("") end
    end
end

function Stautist:ClearSplits()
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    for _, row in pairs(self.hudFrame.bossLines) do row.split:SetText("") end
end

function Stautist:GetSplitColor(percent)
    if percent <= 0.9 then return 0, 1, 0
    elseif percent <= 1.0 then return (percent - 0.9) / 0.1, 1, 0
    elseif percent <= 1.1 then return 1, 1 - ((percent - 1.0) / 0.1), 0
    else return 1, 0.2, 0.2 end
end

-- ============================================================================
-- 6. DEBUG SIMULATION
-- ============================================================================

function Stautist:StartFakeSimulation()
    self.currentZoneID = 568 
    self:ShowHUD()
    self:SetDungeonTitle("Zul'Aman", false, " (10)")
    self:ClearBossList()
    self:AddBossToList(1, "Akil'zon", 1)
    self:SetBossCheckmark(1, true)
    self:UpdateHUDSplit(1, -45) 
    self:AddBossToList(2, "Nalorakk", 2)
    self:SetBossCheckmark(2, true)
    self:UpdateHUDSplit(2, 12) 
    self:AddBossToList(3, "Jan'alai", 3)
    self:AddBossToList(4, "Halazzi", 4)
    self:AddBossToList(5, "Hex Lord Malacrass", 5)
    self:AddBossToList(6, "Zul'jin", 6)
    self:UpdateHUDLayout()
    
    local simStartTime = GetTime()
    local fakeRunStart = 937 
    local fakePB = 2100      
    if self.fakeTimerHandle then self:CancelTimer(self.fakeTimerHandle) end
    self.fakeTimerHandle = self:ScheduleRepeatingTimer(function()
        local elapsed = GetTime() - simStartTime
        local currentFakeTime = fakeRunStart + elapsed
        local min = math.floor(currentFakeTime / 60)
        local sec = math.floor(currentFakeTime % 60)
        local ms = math.floor((currentFakeTime - math.floor(currentFakeTime)) * 10)
        self:UpdateHUDText(string.format("%d:%02d.%d", min, sec, ms))
        if self.hudFrame.percentText then
            local pct = (currentFakeTime / fakePB) * 100
            self.hudFrame.percentText:SetText(string.format("%.2f%%", pct))
        end
    end, 0.1)
end

function Stautist:StopFakeSimulation()
    if self.fakeTimerHandle then self:CancelTimer(self.fakeTimerHandle); self.fakeTimerHandle = nil end
    self.currentZoneID = nil 
    self:HideHUD()
    self:ClearBossList()
    self:UpdateHUDText("0:00")
end

function Stautist:ShakeHUD()
    if self.hudFrame then ShakeFrame(self.hudFrame) end
end