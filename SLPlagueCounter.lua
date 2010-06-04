SLPlagueCounter = LibStub("AceAddon-3.0"):NewAddon("SLPlagueCounter", "AceTimer-3.0", "AceEvent-3.0", "AceConsole-3.0","AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local AceEvent = LibStub("AceEvent-3.0")

-- Unbound Plague 10man ID 72855
--                25man ID 72856

SLPlagueCounter.options = {
	name = "Slap Plague Counter",
	handler = SLPlagueCounter,
	type = "group",
	get = "OptionsGet",
	set = "OptionsSet",
	args = {
		locked = {
			type = "toggle",
			get = "GetLock",
			set = "SetLock",
			name = "Locked",
			desc = "Locked",
			order = 1,
		},
		width = {
			type = "range",
			min = 20,
			max = 100,
			step = 10,
			name = "Width",
			desc = "Icon Width",
			order = 3,
		},
		height = {
			type = "range",
			min = 20,
			max = 100,
			step = 10,
			name = "Height",
			desc = "Icon Height",
			order = 4,
		},
	}
}

local defaults = {
	profile = {
		xOffset = 0,
		yOffset = 0,
		width = 80,
		height = 80,
		locked = true,
	}
}

function SLPlagueCounter:OnEnable()
	self.TimeSinceLastUpdate=0
	self.updateInterval=1.0
	self.enabled=false
	self:UnregisterAllEvents()
	self:RegisterEvent("ZONE_CHANGED_INDOORS","ZoneChanged")
	SLPlagueCounter:CreateAnchorFrame()
end

function SLPlagueCounter:OnInitialize()
	self:RegisterChatCommand("slplague", "Command")
	self.db = LibStub("AceDB-3.0"):New("SLPlagueCounterDB", defaults, "Default")
	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("SLPlagueCounter", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SLPlagueCounter", "SLPlagueCounter")
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

function SLPlagueCounter:CreateAnchorFrame()
	local anchorFrame = CreateFrame("Frame", "AnchorFrame", UIParent)
	self.anchorFrame = anchorFrame
	anchorFrame:SetWidth(self.db.profile.width)
	anchorFrame:SetHeight(self.db.profile.height)
	anchorFrame:SetPoint("CENTER",UIParent,"CENTER",self.db.profile.xOffset,self.db.profile.yOffset)
	anchorFrame:SetMovable(true)
	anchorFrame:EnableMouse(true)
	anchorFrame:RegisterForDrag("LeftButton")
	anchorFrame:SetScript("OnDragStart", function(this)
		anchorFrame.oldxOffset = this:GetLeft()
		anchorFrame.oldyOffset = this:GetTop()
		this:StartMoving()
	end)
	anchorFrame:SetScript("OnDragStop", function(this)
		this:StopMovingOrSizing()
		SLPlagueCounter:SaveAnchorPos(anchorFrame, this:GetLeft(), this:GetTop())
	end)
	if (self.db.profile.locked) then
		anchorFrame:Hide()
	else
		anchorFrame:Show()
	end
	local background = anchorFrame:CreateTexture("AnchorFrameBG", "BACKGROUND")
	background:SetTexture("Interface\\Icons\\Spell_Shadow_CorpseExplode")
	background:SetAllPoints()
end

function SLPlagueCounter:SaveAnchorPos(anchorFrame, xOffset, yOffset)
	self.db.profile.xOffset = self.db.profile.xOffset + xOffset - anchorFrame.oldxOffset 
	self.db.profile.yOffset = self.db.profile.yOffset + yOffset - anchorFrame.oldyOffset
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
			if (spellID==72855) then -- 10man Heroic Version
				-- Check if we already have sickness debuff
				local name, _, _, count = UnitDebuff("player","Plague Sickness")
				local maxTime = 0
				if not name then
					maxTime = 16
				else
					maxTime = 16/(count+1)
				end
				-- Create the Frame :)
				self:CreatePlagueFrame(maxTime)
			end
		end
	end
end

function SLPlagueCounter:CreatePlagueFrame(maxTime)
	local timerFrame = CreateFrame("FRAME","PlagueFrame",self.anchorFrame)
	local background = timerFrame:CreateTexture("PlagueFrameBG", "BACKGROUND")
	local tfontString = timerFrame:CreateFontString("$parentText", "ARTWORK", "GameFontNormal")
	
	background:SetTexture("Interface\\Icons\\Spell_Shadow_CorpseExplode")
	background:SetAllPoints()

	timerFrame.value = maxTime
	timerFrame.elapsedTime = 0
	timerFrame:SetWidth(self.db.profile.width)
	timerFrame:SetHeight(self.db.profile.height)
	timerFrame:SetPoint("CENTER",UIParent,"CENTER",self.db.profile.xOffset,self.db.profile.yOffset)
	
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

function SLPlagueCounter:OptionsGet(info)
	return self.db.profile[info[#info]]
end

function SLPlagueCounter:OptionsSet(info,value)
	self.db.profile[info[#info]] = value
end

function SLPlagueCounter:GetLock(info)
	return self.db.profile.locked
end

function SLPlagueCounter:SetLock(info,value)
	self.db.profile.locked = value
	if (value) then
		self.anchorFrame:Hide()
	else
		self.anchorFrame:Show()
	end
end
