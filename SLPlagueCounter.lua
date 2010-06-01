SLPlagueCounter = LibStub("AceAddon-3.0"):NewAddon("SLPlagueCounter", "AceTimer-3.0", "AceEvent-3.0", "AceConsole-3.0","AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local AceEvent = LibStub("AceEvent-3.0")

-- Unbound Plague 10man ID 72855
--                25man ID 72856

function SLPlagueCounter:OnEnable()
	self.TimeSinceLastUpdate=0
	self.updateInterval=1.0
	self.enabled=false
	self:UnregisterAllEvents()
	self:RegisterEvent("ZONE_CHANGED_INDOORS","ZoneChanged")
end

function SLPlagueCounter:OnInitialize()
	self:RegisterChatCommand("slplague", "Command")
end

function SLPlagueCounter:Command()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "SpellApplied")
end

function SLPlagueCounter:ZoneChanged()
	local current_zone = GetSubZoneText()
	if (current_zone=="Putricide's Laboratory of Alchemical Horrors and Fun") then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "SpellApplied")
		self.enabled=true
		print("SLPlagueCounter is now enabled!")
	else
		if (self.enabled==true) then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self.enabled=false
			print("SLPlagueCounter is now disabled!")
		end
	end
end

function SLPlagueCounter:SpellApplied(event, timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, ... )
	-- Something got applied, check if it was on us !
	if (dstName==UnitName("player")) then
		if (eventType=="SPELL_AURA_APPLIED") then
			local spellID, spellName, spellSchool = select (1, ...)
			if (spellID==72856) then -- 25man Heroic Version
				-- Check if we already have sickness debuff
				local name, _, _, count = UnitDebuff("player","Plague Sickness")
				local maxTime = 0
				if not name then
					maxTime = 12
				else
					maxTime = 12/(count+1)
				end
				-- Create the Frame :)
				self:CreatePlagueFrame(maxTime)
			end
		end
	end
end

function SLPlagueCounter:CreatePlagueFrame(maxTime)
	local timerFrame = CreateFrame("FRAME","PlagueFrame",UIParent)
	local background = timerFrame:CreateTexture("PlagueFrameBG", "BACKGROUND")
	local tfontString = timerFrame:CreateFontString("$parentText", "ARTWORK", "GameFontNormal")
	
	background:SetTexture("Interface\\Icons\\Spell_Shadow_CorpseExplode")
	background:SetAllPoints()

	timerFrame.value = maxTime
	timerFrame.elapsedTime = 0
	timerFrame:SetWidth(80)
	timerFrame:SetHeight(80)
	timerFrame:SetPoint("CENTER",UIParent,0,200)
	
	tfontString:SetAllPoints()
	tfontString:SetFont("Fonts\\FRIZQT__.TTF",40,"MONOCHROME")
	tfontString:SetTextColor(1,1,1,1)
	timerFrame.tfontString = tfontString
	timerFrame:Show()
	self:HookScript(timerFrame, "OnUpdate", "UpdatePlagueFrame")
end

function SLPlagueCounter:UpdatePlagueFrame(timerFrame, elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
	while ( self.TimeSinceLastUpdate > self.updateInterval ) do
		timerFrame.tfontString:SetText(timerFrame.elapsedTime+1)
		timerFrame.elapsedTime = timerFrame.elapsedTime+1
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate - self.updateInterval
		-- Check if we still have the plague on us
		local name = UnitDebuff("player","Unbound Plague")
		if not name then
			-- Plague is gone
			timerFrame:Hide()
			timerFrame:SetParent(nil)
		end
	end
	-- Change Color of Text to Red 2 Seconds before we have to pass it off
	if ((timerFrame.value-timerFrame.elapsedTime)<=2) then
		timerFrame.tfontString:SetTextColor(1,0,0,1)
	end
end
