print("|cff00ff00[Stautist DEBUG]|r HUD.lua loading...")

-- ============================================================================
-- HUD (Heads-Up Display) - Rev 4: Mythic Redesign
-- ============================================================================
local Stautist = LibStub("AceAddon-3.0"):GetAddon("Stautist")
local FONT = "Fonts\\FRIZQT__.TTF"

-- ANIMATION UTILITIES
-- ANIMATION UTILITIES
local function ShakeFrame(obj)
    if not obj then return end
    if obj.isShaking then return end
    obj.isShaking = true
    
    local duration = 0.5
    local elapsed = 0
    local intensity = 5
    
    -- Capture original position
    local point, relTo, relPoint, xOfs, yOfs = obj:GetPoint()
    if not point then 
        obj.isShaking = false
        return 
    end
    
    -- FIX: FontStrings cannot be parents. Attach to the parent frame (the row) instead.
    local animParent = obj
    if obj:IsObjectType("FontString") or obj:IsObjectType("Texture") then
        animParent = obj:GetParent() or UIParent
    end
    
    local anim = CreateFrame("Frame", nil, animParent)
    anim:SetScript("OnUpdate", function(self, el)
        elapsed = elapsed + el
        if elapsed >= duration then
            -- Reset to original
            obj:SetPoint(point, relTo, relPoint, xOfs, yOfs)
            obj.isShaking = false
            self:SetScript("OnUpdate", nil)
            return
        end
        
        -- Apply Offset
        local offset = math.sin(elapsed * 30) * intensity * (1 - (elapsed/duration))
        obj:SetPoint(point, relTo, relPoint, xOfs + offset, yOfs)
    end)
end

local function FlashFrame(frame, duration)
    if not frame then return end
    if frame:IsShown() and frame:GetAlpha() == 1 then return end 
    
    UIFrameFadeIn(frame, 0.3, 0, 1)
    
    -- FIX: Use Stautist:ScheduleTimer instead of C_Timer.After
    Stautist:ScheduleTimer(function()
        UIFrameFadeOut(frame, 0.5, 1, 0)
    end, duration or 2)
end

local function FlashFrame(frame, duration)
    if not frame then return end
    if frame:IsShown() and frame:GetAlpha() == 1 then return end 
    
    -- Standard UIFrameFade works on FontStrings in 3.3.5
    if UIFrameFadeIn then
        UIFrameFadeIn(frame, 0.3, 0, 1)
    else
        frame:Show()
        frame:SetAlpha(1)
    end
    
    -- Schedule Fade Out
    if C_Timer and C_Timer.After then
        C_Timer.After(duration or 2, function()
            if UIFrameFadeOut then
                UIFrameFadeOut(frame, 0.5, 1, 0)
            else
                frame:Hide()
            end
        end)
    else
        -- Fallback for very old clients without C_Timer (just in case)
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(self, el)
            t = t + el
            if t > (duration or 2) then
                if UIFrameFadeOut then UIFrameFadeOut(frame, 0.5, 1, 0) else frame:Hide() end
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

local function FlashFrame(frame, duration)
    if not frame then return end
    if frame:IsShown() and frame:GetAlpha() == 1 then return end -- Already visible
    
    UIFrameFadeIn(frame, 0.3, 0, 1)
    
    -- Schedule Fade Out
    C_Timer.After(duration or 2, function()
        UIFrameFadeOut(frame, 0.5, 1, 0)
    end)
end

function Stautist:CreateHUD()
    if self.hudFrame then return end

    -- FONT DEFINITIONS
    local TITLE_FONT = self.db.profile.font_title or "Fonts\\FRIZQT__.TTF"
    local PT_SANS = "Interface\\AddOns\\Stautist\\Fonts\\PTSans.ttf"
    local MAIN_FONT = PT_SANS 
    
    local SCALE = self.db.profile.timer_scale or 1.0

    local frame = CreateFrame("Frame", "StautistHUD", UIParent)
    local baseWidth = self.db.profile.hud_width or 240
    frame:SetSize(baseWidth, 320)
    local pos = self.db.profile.timer_pos
    frame:SetPoint(pos.a, pos.p, pos.a, pos.x, pos.y)
    frame:SetScale(SCALE)
    
    -- STATE VARIABLES
    frame.currentWidth = 240
    frame.targetWidth = 240
    
    -- GLOW STATE VARIABLES
    frame.glowTimer = 0
    frame.glowState = 0
    frame.nextGlowTime = math.random(5, 15)
    
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
    
    -- ANIMATION SCRIPT
    frame:SetScript("OnUpdate", function(self, elapsed)
        -- 1. Width Smooth Animation
        if math.abs(self.currentWidth - self.targetWidth) > 0.1 then
            local speed = 10 * elapsed 
            self.currentWidth = self.currentWidth + (self.targetWidth - self.currentWidth) * speed
            self:SetWidth(self.currentWidth)
        end

        -- 2. Dungeon Title White Glow Animation
        if self.dungeonNameGlow then
            if self.glowState == 0 then -- Idle
                self.glowTimer = self.glowTimer + elapsed
                if self.glowTimer >= self.nextGlowTime then
                    self.glowState = 1 -- Start Fade In
                    self.glowTimer = 0
                end
            elseif self.glowState == 1 then -- Fading In (1.5s)
                self.glowTimer = self.glowTimer + elapsed
                local alpha = self.glowTimer / 1.5
                if alpha >= 1 then alpha = 1; self.glowState = 2; self.glowTimer = 0 end
                self.dungeonNameGlow:SetAlpha(alpha)
            elseif self.glowState == 2 then -- Fading Out (1.5s)
                self.glowTimer = self.glowTimer + elapsed
                local alpha = 1 - (self.glowTimer / 1.5)
                if alpha <= 0 then 
                    alpha = 0; self.glowState = 0; self.glowTimer = 0 
                    self.nextGlowTime = math.random(5, 15) 
                end
                self.dungeonNameGlow:SetAlpha(alpha)
            end
        end
    end)

    -- HEADER IMAGE
    -- CHANGE: "BACKGROUND" -> "ARTWORK" to sit above the black backdrop
    frame.header = frame:CreateTexture(nil, "ARTWORK")
    frame.header:SetPoint("TOPLEFT", 3, -3)
    frame.header:SetPoint("TOPRIGHT", -3, -3)
    frame.header:SetHeight(60) 
    frame.header:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.header:SetVertexColor(0.2, 0.2, 0.2, 0.8) 

    -- CONFIG BUTTON
    frame.gearBtn = CreateFrame("Button", nil, frame)
    frame.gearBtn:SetSize(16, 16)
    frame.gearBtn:SetPoint("TOPLEFT", 8, -8)
    frame.gearBtn:SetNormalTexture("Interface\\WorldMap\\Gear_64")
    frame.gearBtn:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
    frame.gearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    frame.gearBtn:SetScript("OnClick", function() Stautist:OpenConfigWindow() end)

    -- DUNGEON NAME (Main)
    frame.dungeonName = frame:CreateFontString(nil, "OVERLAY")
    frame.dungeonName:SetFont(TITLE_FONT, 28, "OUTLINE") 
    frame.dungeonName:SetPoint("TOP", 0, -8)
    frame.dungeonName:SetTextColor(1, 1, 1)

    -- DUNGEON NAME (Glow Layer)
    frame.dungeonNameGlow = frame:CreateFontString(nil, "OVERLAY")
    frame.dungeonNameGlow:SetFont(TITLE_FONT, 28, "THICKOUTLINE") 
    frame.dungeonNameGlow:SetPoint("CENTER", frame.dungeonName, "CENTER", 0, 0)
    frame.dungeonNameGlow:SetTextColor(1, 1, 1)
    frame.dungeonNameGlow:SetAlpha(0) 

    -- MAIN TIMER
    frame.mainTimer = frame:CreateFontString(nil, "OVERLAY")
    frame.mainTimer:SetFont(MAIN_FONT, 20, "OUTLINE")
    frame.mainTimer:SetPoint("TOP", frame.header, "BOTTOM", 0, -10)

    -- RUN COUNT
    frame.runCount = frame:CreateFontString(nil, "OVERLAY")
    frame.runCount:SetFont(MAIN_FONT, 11, "OUTLINE")
    frame.runCount:SetPoint("TOP", frame.mainTimer, "BOTTOM", 0, -2)
    frame.runCount:SetTextColor(0.7, 0.7, 0.7)

    -- PERCENTAGE
    frame.percentText = frame:CreateFontString(nil, "OVERLAY")
    frame.percentText:SetFont(MAIN_FONT, 30, "OUTLINE") 
    frame.percentText:SetPoint("TOP", frame.runCount, "BOTTOM", 0, -5)

    -- WIPE TEXT
    frame.wipeText = frame:CreateFontString(nil, "OVERLAY")
    frame.wipeText:SetFont(MAIN_FONT, 12, "OUTLINE")
    frame.wipeText:SetPoint("TOP", frame.percentText, "BOTTOM", 0, -2)
    frame.wipeText:SetTextColor(1, 0.2, 0.2)
    frame.wipeText:Hide()

    -- PB TEXT
    frame.timeToBeat = frame:CreateFontString(nil, "OVERLAY")
    frame.timeToBeat:SetFont(MAIN_FONT, 10, "OUTLINE")
    frame.timeToBeat:SetPoint("BOTTOM", 0, 8)
    frame.timeToBeat:SetTextColor(0.6, 0.6, 0.6)

    -- ICONS
    frame.heroicIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.heroicIcon:SetSize(24, 24)
    frame.heroicIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    frame.heroicIcon:Hide()

    frame.starIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.starIcon:SetSize(32, 32)
    frame.starIcon:SetPoint("LEFT", frame.mainTimer, "RIGHT", 5, 0)
    frame.starIcon:SetTexture("Interface\\Cooldown\\star4")
    frame.starIcon:SetBlendMode("ADD")
    frame.starIcon:Hide()

    frame.bossLines = {} 
    self.hudFrame = frame
    
    self:UpdateHUDLayout()
    self:HideHUD()
end

function Stautist:ClearBossList()
    if not self.hudFrame then return end
    
    -- CRITICAL FIX: Reset the anchor point (lastRow) so sorting starts fresh
    self.hudFrame.lastRow = nil 
    
    if self.hudFrame.bossLines then
        for _, line in pairs(self.hudFrame.bossLines) do
            line:Hide()
            line:ClearAllPoints() -- Detach so they can be re-ordered
        end
    end
    -- We do NOT wipe the table; we reuse the frames to prevent memory leaks
end

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
        row = CreateFrame("Frame", nil, self.hudFrame)
        -- Set row width dynamically based on HUD width
        local w = (self.db.profile.hud_width or 240) - 20
        row:SetSize(w, 20) 

        -- 1. NAME (Left Aligned)
        row.name = row:CreateFontString(nil, "ARTWORK")
        row.name:SetPoint("TOPLEFT", 5, 0)
        row.name:SetWidth(w - 50) -- Leave space for split timer on right
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(true)
        row.name:SetNonSpaceWrap(true)

        -- 2. ICON REMOVED (Deleted code block here)

        -- 3. SPLIT TIMER (Right Aligned)
        row.split = row:CreateFontString(nil, "ARTWORK")
        -- Anchored to the far right of the row
        row.split:SetPoint("TOPRIGHT", -5, 0) 
        row.split:SetJustifyH("RIGHT")
        
        self.hudFrame.bossLines[key] = row
    end

    row:Show()
    row.npcID = npcID 
    row.order = order or 50
    row.encounterKey = key

    -- FONT LOGIC
    local fontPath = "Interface\\AddOns\\Stautist\\Fonts\\PTSans.ttf"
    
    if isEndBoss then
        row.name:SetFont(fontPath, 16, "THICKOUTLINE")
        row.name:SetTextColor(1, 0.2, 0.2)
    else
        row.name:SetFont(fontPath, 15, "OUTLINE")
        row.name:SetTextColor(0.9, 0.3, 0.3)
    end
    
    row.split:SetFont(fontPath, 15, "OUTLINE")

    -- NAME WRAPPING LOGIC
    local displayName = bossName or "Unknown"
    if #displayName > 15 and string.find(displayName, " the ") then
        displayName = displayName:gsub(" the ", "\nthe ")
    end
    row.name:SetText(displayName)
    
    -- HEIGHT ADJUSTMENT
    local textHeight = row.name:GetStringHeight()
    local newHeight = math.max(20, textHeight + 4)
    row:SetHeight(newHeight)

    row.split:SetText("")
    
    -- Default Color (Not Killed = Reddish)
    row.name:SetTextColor(0.9, 0.3, 0.3)

    -- POSITIONING
    if row:GetNumPoints() == 0 then
        local anchor = self.hudFrame.percentText
        if self.db.profile.show_wipes then anchor = self.hudFrame.wipeText end

        if self.hudFrame.lastRow then
            row:SetPoint("TOP", self.hudFrame.lastRow, "BOTTOM", 0, -2)
        else
            row:SetPoint("TOP", anchor, "BOTTOM", 0, -12)
        end
        self.hudFrame.lastRow = row
    end
    
    local showSplits = self.db.profile.show_splits
    if showSplits then row.split:Show() else row.split:Hide() end
end


function Stautist:SetBossCheckmark(npcID, isKilled)
    if not self.hudFrame or not self.hudFrame.bossLines then return end

    local zID = self.currentZoneID
    local key = npcID

    -- If npcID passed is actually an encounter string (like "vh_1"), use it directly
    if type(npcID) == "string" then
        key = npcID
    elseif zID and self.BossDB[zID] then
        local b = self.BossDB[zID].bosses[npcID]
        if type(b) == "table" and b.encounter then
            key = b.encounter
        end
    end

    local row = self.hudFrame.bossLines[key]
    
    if row and isKilled then
        row.name:SetTextColor(0.2, 1, 0.2) 
    end
end



-- ============================================================================
-- Control Functions (Crucial for Engine.lua)
-- ============================================================================
function Stautist:ShowHUD()
    if not self.hudFrame then self:CreateHUD() end
    
    -- Failsafe: If already fully visible, do nothing to prevent flickering
    if self.hudFrame:IsShown() and self.hudFrame:GetAlpha() == 1 then return end
    
    -- Use WoW's built-in fade library
    -- Syntax: UIFrameFadeIn(frame, timeToFade, startAlpha, endAlpha)
    if UIFrameFadeIn then
        UIFrameFadeIn(self.hudFrame, 0.5, 0, 1)
    else
        -- Fallback if UIFrameFadeIn is missing for some reason
        self.hudFrame:SetAlpha(1)
        self.hudFrame:Show()
    end
end

function Stautist:HideHUD()
    if self.hudFrame and self.hudFrame:IsShown() then
        -- Smooth Fade Out
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


function Stautist:UpdateHUDHeight()
    if not self.hudFrame then return end
    
    -- Base Header Height
    local headerHeight = 160 
    
    -- Add extra space if Wipe Text is visible
    if self.db.profile.show_wipes then
        headerHeight = headerHeight + 15
    end

    local bossCount = 0
    if self.hudFrame.bossLines then
        for _, line in pairs(self.hudFrame.bossLines) do
            if line:IsShown() then bossCount = bossCount + 1 end
        end
    end
    
    local totalHeight = headerHeight + (bossCount * 22) + 35
    self.hudFrame:SetHeight(totalHeight)
end

function Stautist:SetDungeonTitle(name, isHeroic, sizeTag)
    if not self.hudFrame then return end
    
    local cleanName = name or "Unknown"
    local prefixes = {
        "Auchindoun: ", "Caverns of Time: ", "Coilfang Reservoir: ", 
        "Hellfire Citadel: ", "Tempest Keep: ", "Scarlet Monastery: "
    }
    for _, p in ipairs(prefixes) do
        if string.find(cleanName, p) then
            cleanName = cleanName:gsub(p, "")
            break
        end
    end
    if cleanName == "Ahn'kahet: The Old Kingdom" then cleanName = "Ahn'kahet" end

    local title = self.hudFrame.dungeonName
    local glow = self.hudFrame.dungeonNameGlow
    local skull = self.hudFrame.heroicIcon
    local fullText = cleanName .. (sizeTag or "")
    
    local tFont = (self.db and self.db.profile and self.db.profile.font_title) or "Fonts\\FRIZQT__.TTF"
    
    -- 1. Set Base Size
    title:SetFont(tFont, 28, "OUTLINE")
    title:SetText(fullText)
    
    -- 2. Auto-shrink logic
    local width = title:GetStringWidth()
    if width > 190 then title:SetFont(tFont, 24, "OUTLINE") end
    if width > 220 then title:SetFont(tFont, 20, "OUTLINE") end
    
    -- 3. Sync Glow Text
    local fontFile, fontSize, fontFlags = title:GetFont()
    if glow then
        glow:SetFont(fontFile, fontSize, fontFlags)
        glow:SetText(fullText)
    end

    -- 4. Position
    if isHeroic then
        title:ClearAllPoints()
        title:SetPoint("TOP", -12, -25) 
        skull:ClearAllPoints()
        skull:SetPoint("LEFT", title, "RIGHT", 5, 0)
        skull:Show()
    else
        title:ClearAllPoints()
        title:SetPoint("TOP", 0, -25) 
        skull:Hide()
    end
    
    if glow then glow:SetPoint("CENTER", title, "CENTER", 0, 0) end

    -- 5. Load Header Image
    local texID = nil
    if self.BossDB and self.currentZoneID and self.BossDB[self.currentZoneID] then
        texID = self.BossDB[self.currentZoneID].textureID
    end

    if texID then
        self.hudFrame.header:SetTexture("Interface\\AddOns\\Stautist\\Textures\\" .. texID .. ".tga")
        self.hudFrame.header:SetVertexColor(1, 1, 1)
        
        -- Set to 80% opacity
        self.hudFrame.header:SetAlpha(0.8) 
        
        self.hudFrame.header:SetTexCoord(0, 1, 0, 0.75) 
    else
        self.hudFrame.header:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.hudFrame.header:SetVertexColor(0.2, 0.2, 0.2, 0.8)
        self.hudFrame.header:SetTexCoord(0, 1, 0, 1)
    end
end

function Stautist:ShowRunSummary(timeStr, rank, isPB)
    if not self.hudFrame then return end
    
    -- 1. Set Time
    self.hudFrame.mainTimer:SetText(timeStr)
    self.hudFrame.mainTimer:SetTextColor(1, 1, 1) -- White
    
    -- 2. Set Rank text in the "Percent" slot
    if rank then
        self.hudFrame.percentText:SetText("Rank: " .. rank)
        
        if isPB then
            self.hudFrame.percentText:SetTextColor(1, 0.8, 0) -- Gold
            self.hudFrame.starIcon:Show()
        else
            self.hudFrame.percentText:SetTextColor(0.7, 0.7, 0.7) -- Grey
            self.hudFrame.starIcon:Hide()
        end
    else
        self.hudFrame.percentText:SetText("Stopped")
        self.hudFrame.percentText:SetTextColor(0.5, 0.5, 0.5)
        self.hudFrame.starIcon:Hide()
    end
end

function Stautist:UpdateHUDLayout()
    if not self.hudFrame then return end
    
    local showSplits = self.db.profile.show_splits
    local showWipes = self.db.profile.show_wipes
    local baseWidth = self.db.profile.hud_width or 240
    
    -- 1. Width Logic (Fixed)
    -- We no longer add +60. The width stays constant based on your slider.
    self.hudFrame.targetWidth = baseWidth
    
    -- Toggle split text visibility on existing rows
    if self.hudFrame.bossLines then
        for _, row in pairs(self.hudFrame.bossLines) do
            if showSplits then row.split:Show() else row.split:Hide() end
            
            -- Update Row Widths to match new HUD width
            row:SetWidth(baseWidth - 20)
        end
    end

    -- 2. Handle Wipes
    if showWipes then
        self.hudFrame.wipeText:Show()
    else
        self.hudFrame.wipeText:Hide()
    end
    
    self:UpdateHUDHeight()
end

function Stautist:UpdateHUDSplit(npcID, diffSeconds)
    if not self.hudFrame or not self.hudFrame.bossLines then return end

    local key = npcID
    -- Key lookup logic...
    if not self.hudFrame.bossLines[key] and self.BossDB and self.currentZoneID then
         local b = self.BossDB[self.currentZoneID].bosses[npcID]
         if type(b) == "table" and b.encounter then key = b.encounter end
    end
    
    local row = self.hudFrame.bossLines[key]
    if row then
        local sign = (diffSeconds < 0) and "-" or "+"
        local absDiff = math.abs(diffSeconds)
        local timeStr = self:FormatTime(absDiff, true) -- Use precision
        
        row.split:SetText(sign .. timeStr)
        
        if diffSeconds < 0 then
            row.split:SetTextColor(0, 1, 0)
        else
            row.split:SetTextColor(1, 0.2, 0.2)
        end

        -- ANIMATION
        if self.db.profile.show_splits then
            -- Visible -> Shake Timer
            ShakeFrame(row.split)
        else
            -- Hidden -> Flash
            row.split:Show()
            row.split:SetAlpha(0)
            FlashFrame(row.split, 2)
        end
    end
end

function Stautist:UpdateHUDWipes(count)
    if not self.hudFrame then return end
    
    local oldText = self.hudFrame.wipeText:GetText()
    self.hudFrame.wipeText:SetText("Wipes: " .. count)
    
    -- Determine Color
    if count > 0 then
        self.hudFrame.wipeText:SetTextColor(1, 0.2, 0.2)
    else
        self.hudFrame.wipeText:SetTextColor(0.5, 0.5, 0.5)
    end

    -- ANIMATION LOGIC
    if count > 0 then
        if self.db.profile.show_wipes then
            -- Scenario: Visible -> Shake
            ShakeFrame(self.hudFrame.wipeText)
        else
            -- Scenario: Hidden -> Flash
            self.hudFrame.wipeText:Show()
            self.hudFrame.wipeText:SetAlpha(0)
            FlashFrame(self.hudFrame.wipeText, 2) -- Show for 2s
        end
    end
end

function Stautist:UpdateLiveSplits(runTime, pbData, currentKills)
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    if not self.db.profile.show_splits then return end
    
    local pbKills = pbData.boss_kills
    if not pbKills then return end

    -- 1. Collect Active (Unkilled) Rows
    local activeRows = {}
    for key, row in pairs(self.hudFrame.bossLines) do
        local npcID = row.npcID
        local isKilled = currentKills[npcID] or currentKills[tostring(npcID)]
        
        if not isKilled then
            table.insert(activeRows, row)
        else
            -- Ensure killed bosses don't show live text
             if row.split:GetText() and string.find(row.split:GetText(), "%.") then
                 row.split:SetText("") 
             end
        end
    end

    -- 2. Sort by Boss Order
    table.sort(activeRows, function(a,b) return (a.order or 99) < (b.order or 99) end)

    -- 3. Update ONLY the first unkilled boss
    for i, row in ipairs(activeRows) do
        if i == 1 then
            local npcID = row.npcID
            local pbBossData = pbKills[npcID] or pbKills[tostring(npcID)]
            
            if pbBossData and pbBossData.split_time and pbBossData.split_time > 0 then
                local diff = runTime - pbBossData.split_time
                local sign = (diff < 0) and "-" or "+"
                local absDiff = math.abs(diff)
                
                row.split:SetText(sign .. self:FormatTime(absDiff))
                
                -- COLOR LOGIC
                local percent = runTime / pbBossData.split_time
                local r, g, b = self:GetSplitColor(percent)
                row.split:SetTextColor(r, g, b)
            else
                row.split:SetText("...") 
                row.split:SetTextColor(0.5, 0.5, 0.5)
            end
        else
            row.split:SetText("")
        end
    end
end

function Stautist:ClearSplits()
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    for _, row in pairs(self.hudFrame.bossLines) do
        row.split:SetText("")
    end
end


function Stautist:GetSplitColor(percent)
    -- 0% to 90%: Green
    -- 90% to 100%: Fade Green to Yellow
    -- 100% to 110%: Fade Yellow to Red
    -- > 110%: Red
    
    if percent <= 0.9 then
        return 0, 1, 0 -- Pure Green
    elseif percent <= 1.0 then
        -- 0.9 -> 1.0 (Green to Yellow)
        local n = (percent - 0.9) / 0.1
        return n, 1, 0 -- R goes 0->1, G stays 1
    elseif percent <= 1.1 then
        -- 1.0 -> 1.1 (Yellow to Red)
        local n = (percent - 1.0) / 0.1
        return 1, 1 - n, 0 -- R stays 1, G goes 1->0
    else
        return 1, 0.2, 0.2 -- Pure Red
    end
end






local fakeTimerTicker
function Stautist:StartFakeSimulation()
    -- INJECT FAKE ZONE ID (Zul'Aman) so texture loads
    self.currentZoneID = 568 
    
    self:ShowHUD()
    self:SetDungeonTitle("Zul'Aman", false, " (10)")
    self:ClearBossList()
    
    -- Fake Bosses
    self:AddBossToList(1, "Akil'zon", 1)
    self:SetBossCheckmark(1, true)
    self:UpdateHUDSplit(1, -45) 
    
    self:AddBossToList(2, "Nalorakk", 2)
    self:SetBossCheckmark(2, true)
    self:UpdateHUDSplit(2, 12) 
    
    self:AddBossToList(3, "Jan'alai", 3) -- Active boss
    self:AddBossToList(4, "Halazzi", 4)
    self:AddBossToList(5, "Hex Lord Malacrass", 5)
    self:AddBossToList(6, "Zul'jin", 6)
    
    self:UpdateHUDHeight()
    self:UpdateHUDLayout()
    
    -- Simulation State
    local simStartTime = GetTime()
    local fakeRunStart = 937 
    local fakePB = 2100      
    local fakeBossPB = 940   
    
    -- FIX: Cancel existing AceTimer if running
    if self.fakeTimerHandle then self:CancelTimer(self.fakeTimerHandle) end

    -- FIX: Use AceTimer ScheduleRepeatingTimer instead of C_Timer.NewTicker
    self.fakeTimerHandle = self:ScheduleRepeatingTimer(function()
        -- Calculate Time
        local elapsed = GetTime() - simStartTime
        local currentFakeTime = fakeRunStart + elapsed
        
        -- 1. Update Main Timer
        local min = math.floor(currentFakeTime / 60)
        local sec = math.floor(currentFakeTime % 60)
        local ms = math.floor((currentFakeTime - math.floor(currentFakeTime)) * 10)
        self:UpdateHUDText(string.format("%d:%02d.%d", min, sec, ms))
        
        -- 2. Update Percentage
        if self.hudFrame.percentText then
            local pct = (currentFakeTime / fakePB) * 100
            self.hudFrame.percentText:SetText(string.format("%.2f%%", pct))
            
            local r, g, b = 0, 1, 0
            if pct > 90 then r = 1 end
            if pct > 100 then g = 0 end
            self.hudFrame.percentText:SetTextColor(r, g, b)
        end
        
        -- 3. Update Live Split for Jan'alai (ID 3)
        local activeRow = self.hudFrame.bossLines[3]
        if activeRow then
             local diff = currentFakeTime - fakeBossPB
             local absDiff = math.abs(diff)
             local sign = (diff < 0) and "-" or "+"
             
             local sTime = self:FormatTime(absDiff, true) 
             activeRow.split:SetText(sign .. sTime)
             
             if diff < 0 then
                 activeRow.split:SetTextColor(0, 1, 0)
             else
                 activeRow.split:SetTextColor(1, 0.2, 0.2)
             end
             activeRow.split:Show()
        end
    end, 0.1) -- Run every 0.1 seconds
end

function Stautist:StopFakeSimulation()
    -- FIX: Cancel AceTimer handle
    if self.fakeTimerHandle then 
        self:CancelTimer(self.fakeTimerHandle)
        self.fakeTimerHandle = nil
    end
    
    self.currentZoneID = nil 
    self:HideHUD()
    self:ClearBossList()
    self:UpdateHUDText("0:00")
end
function Stautist:StopFakeSimulation()
    if fakeTimerTicker then fakeTimerTicker:Cancel() end
    
    self.currentZoneID = nil -- CLEANUP FAKE ID
    
    self:HideHUD()
    -- Restore real state if needed, or just clear
    self:ClearBossList()
    self:UpdateHUDText("0:00")
end

function Stautist:ShakeHUD()
    if self.hudFrame then ShakeFrame(self.hudFrame) end
end



function Stautist:UpdateRowName(encounterKey, newName)
    if not self.hudFrame or not self.hudFrame.bossLines then return end
    
    local row = self.hudFrame.bossLines[encounterKey]
    if row then
        -- Handle wrapping logic again for the new name
        local displayName = newName
        if #displayName > 15 and string.find(displayName, " the ") then
            displayName = displayName:gsub(" the ", "\nthe ")
        end
        
        row.name:SetText(displayName)
        
        -- Recalculate height in case the new name is longer/shorter
        local textHeight = row.name:GetStringHeight()
        local newHeight = math.max(20, textHeight + 4)
        row:SetHeight(newHeight)
        
        -- Refresh layout to adjust spacing if height changed
        self:UpdateHUDHeight()
    end
end