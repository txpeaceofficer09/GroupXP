GroupXPDB = {
	["pos_a"] = "CENTER",
	["pos_c"] = "CENTER",
	["pos_x"] = "-200",
	["pos_y"] = "200",
}

local Settings = {
	["scale"] = 1,
	["barsize"] = 16,
	["texture"] = "",
	["background"] = "Interface\\DialogFrame\\UI-DialogBox-BackGround-Dark",
	["border"] = "Interface\\Tooltips\\UI-Tooltip-Border",
	["refresh_rate"] = 2,
}

local groupxpTbl = {}

local function ShortNumber(number)
	if number >= 1000000000 then
		return ("%.2fB"):format(number/1000000000)
	elseif number >= 1000000 then
		return ("%.2fM"):format(number/1000000)
	elseif number >= 1000 then
		return ("%.2fK"):format(number/1000)
	else
		return number
	end
end

local function DecimalToHexColor(r, g, b, a)
	return ("|c%02x%02x%02x%02x"):format(a*255, r*255, g*255, b*255)
end

local function TableSum(table)
	local retVal = 0

	for _, n in ipairs(table) do
		retVal = retVal + n
	end

	return retVal
end

local function unitIndex(name)
	for k,v in pairs(groupxpTbl) do
		if v["name"] == name then
			return k
		end
	end
	return false
end

local function AddUnit(name, class, percent)
	local index = false

	for k,v in pairs(groupxpTbl) do
		if v.name == name then
			index = k
			break
		end
	end

	if index == false then
		table.insert(groupxpTbl, { ["name"] = name, ["class"] = class, ["percent"] = percent })
	else
		groupxpTbl[index].percent = percent
	end
end

local function IsInParty(name)
	if strfind(name, UnitName("player"), 1) then
		return true
	end

	if IsInRaid() then
		for i=1,GetNumGroupMembers(),1 do
			if strfind(name, UnitName("raid"..i), 1) then
				return "raid"..i
			end
		end
	elseif GetNumGroupMembers() > 0 then
		for i=1,GetNumGroupMembers(),1 do
			if strfind(name, UnitName("party"..i), 1) then
				return "party"..i
			end
		end
	end

	return false
end

local function UnitFromName(name)
	if strfind(name, UnitName("player"), 1) then
		return true
	end

	if IsInRaid() then
		for i=1,GetNumGroupMembers(),1 do
			if strfind(name, UnitName("raid"..i), 1) then
				return "raid"..i
			end
		end
	elseif GetNumGroupMembers() > 0 then
		for i=1,GetNumGroupMembers(),1 do
			if strfind(name, UnitName("party"..i), 1) then
				return "party"..i
			end
		end
	end

	return false
end

local function GroupXP_Refresh()
	local sortTbl = {}
	for k,v in ipairs(groupxpTbl) do table.insert(sortTbl, k) end
	table.sort(sortTbl, function(a,b) return groupxpTbl[a].percent > groupxpTbl[b].percent end)

	local index = 1
	for k,v in ipairs(sortTbl) do
		local bar = _G["GroupXPFrameBar"..index] or GroupXP_AddBar(index)
		local name = groupxpTbl[v].name
		local percent = groupxpTbl[v].percent

		_G["GroupXPFrameBar"..index.."Name"]:SetText(name)
		_G["GroupXPFrameBar"..index.."Percent"]:SetText(percent.."%")	

		if groupxpTbl[v].class ~= nil then
			bar:SetStatusBarColor(RAID_CLASS_COLORS[groupxpTbl[v].class].r, RAID_CLASS_COLORS[groupxpTbl[v].class].g, RAID_CLASS_COLORS[groupxpTbl[v].class].b, 1)
		else
			bar:SetStatusBarColor(0, 1, 0, 1)
		end
		bar:SetValue(groupxpTbl[v].percent)

		if IsInParty(groupxpTbl[v].name) ~= false then
			bar:Show()
			index = index + 1
		end
	end
end

local f = CreateFrame("Frame", "GroupXPFrame", UIParent)

local maxScroll = 0
local numBars = 0

f:SetPoint("CENTER")
--f:SetSize(410, 150)
f:SetSize(300, 150)
f:SetClampedToScreen(true)
f:SetMovable(true)
f:SetUserPlaced(true)
f:SetBackdrop( { bgFile = "Interface\\DialogFrame\\UI-DialogBox-BackGround-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32, edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } } )

f:SetScript("OnMouseDown", function(self, button)
	f:StartMoving()
end)

f:SetScript("OnMouseUp", function(self, button)
	GroupXPDB.pos_a, _, GroupXPDB.pos_c, GroupXPDB.pos_x, GroupXPDB.pos_y = GroupXPFrame:GetPoint(1)

	f:StopMovingOrSizing()
end)

local titlebar = CreateFrame("Frame", "GroupXPFrameTitleBar", GroupXPFrame)
titlebar:SetPoint("TOPLEFT", GroupXPFrame, "TOPLEFT", 4, -4)
--titlebar:SetPoint("TOPRIGHT", GroupXPFame, "TOPRIGHT", -4, -4)
titlebar:SetSize(GroupXPFrame:GetWidth() - 8, 18)
titlebar:SetBackdrop( { bgFile = "Interface\\BUTTONS\\GRADBLUE", edgeFile = nil, tile = false, tileSize = titlebar:GetWidth(), edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
titlebar:SetBackdropColor(1, 0.5, 0.5, 1)
titlebar:Show()
local title = titlebar:CreateFontString(titlebar:GetName().."Text", "OVERLAY")
title:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
title:SetAllPoints(titlebar)
title:SetJustifyH("LEFT")
title:SetText("GroupXP")
title:Show()

local scp = CreateFrame("ScrollFrame", "GroupXPFrameSCParent", GroupXPFrame)
scp:SetPoint("TOPLEFT", GroupXPFrame, "TOPLEFT", 4, -24)
scp:SetPoint("BOTTOMRIGHT", GroupXPFrame, "BOTTOMRIGHT", -4, 4)

local sc = CreateFrame("Frame", "GroupXPFrameSC", GroupXPFrameSCParent)
sc:EnableMouse(true)
sc:EnableMouseWheel(true)

sc:SetWidth(GroupXPFrameSCParent:GetWidth())
sc:SetHeight(((Settings.barsize + 2)*25)-2)

GroupXPFrameSCParent:SetScrollChild(sc)

function GroupXP_AddBar(i)
	if _G["GroupXPFrameBar"..i] then return end

	local sb = CreateFrame("StatusBar", "GroupXPFrameBar"..i, GroupXPFrameSC)
	sb:SetMinMaxValues(0, 100)
	sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	sb:GetStatusBarTexture():SetHorizTile(false)
	sb:SetStatusBarColor(0, 1, 0)
	sb:SetValue(0)
	sb:SetHeight(Settings.barsize)

	sb:SetPoint("TOPLEFT", GroupXPFrameSC, "TOPLEFT", 0, (-2-(i*(Settings.barsize + 2)))+(Settings.barsize + 2))

	local t = sb:CreateFontString("GroupXPFrameBar"..i.."Name", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("LEFT")
	t:SetPoint("LEFT", sb, "LEFT", 2, 0)

	local t = sb:CreateFontString("GroupXPFrameBar"..i.."Percent", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("RIGHT")
	t:SetPoint("RIGHT", sb, "RIGHT", -2, 0)

	_G["GroupXPFrameBar"..i]:SetWidth(GroupXPFrameSC:GetWidth())
	_G["GroupXPFrameBar"..i.."Name"]:SetSize((_G["GroupXPFrameBar"..i]:GetWidth()/2), Settings.barsize)
	_G["GroupXPFrameBar"..i.."Percent"]:SetSize((_G["GroupXPFrameBar"..i]:GetWidth()/2), Settings.barsize)

	GroupXPFrameSC:SetHeight(i*(Settings.barsize + 2))
	maxScroll = GroupXPFrameSC:GetHeight()-128
	numBars = i
	return _G["GroupXPFrameBar"..i]
end

local function SendXP()
	local xp = ("%.0f"):format((UnitXP("player") / UnitXPMax("player"))*100)
	if GetNumGroupMembers() > 0 then
		GroupXPFrame:Show()
		SendAddonMessage("GROUPXP", xp, "PARTY")
	else
		GroupXPFrame:Hide()
		SendAddonMessage("GROUPXP", xp, "GUILD")
	end
end

local function SendRefresh()
		if IsInRaid() then
			SendAddonMessage("GROUPXP", "REFRESH", "RAID")
		elseif GetNumGroupMembers() > 0 then
			SendAddonMessage("GROUPXP", "REFRESH", "PARTY")
		end
end

local function OnEvent(self, event, ...)
	if event == "VARIABLES_LOADED" then
		self:SetPoint(GroupXPDB.pos_a, UIParent, GroupXPDB.pos_c, GroupXPDB.pos_x, GroupXPDB.pos_y)
		self:UnregisterEvent("VARIABLES_LOADED")
	elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
		if event == "PLAYER_ENTERING_WORLD" then
			SendRefresh()
		end
		SendXP()

		GroupXP_Refresh()
	elseif event == "PLAYER_LEVEL_UP" then
		local level = ...
		local _, GroupType = IsInInstance()

		if IsInRaid() then
			SendChatMessage("DING! Level "..level.."!", "RAID")
		elseif GetNumGroupMembers() > 0 then
			SendChatMessage("DING! Level "..level.."!", "PARTY")
		end
		SendChatMessage("DING! Level "..level.."!", "GUILD")
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...

		if prefix == "GROUPXP" then
			local class
			if GetNumGroupMembers() > 0 then
				for i=1,GetNumGroupMembers(),1 do
					if strfind(sender, (UnitName("raid"..i) or "Unknown"), 1) then
						class = select(2, UnitClass("raid"..i))
					elseif strfind(sender, (UnitName("party"..i) or "Unknown"), 1) then
						class = select(2, UnitClass("party"..i))
					end
				end
			end
			if strfind(sender, (UnitName("player") or "Unknown"), 1) then
				class = select(2, UnitClass("player"))
			end

			if message == "REFRESH" then
				if not strfind(sender, UnitName("player"), 1) then
					SendXP()
				end
			else
				AddUnit(sender, class, message)
				GroupXP_Refresh()
			end
		end
	end
end

f:SetScript("OnEvent", OnEvent)

f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_LEVEL_UP")

RegisterAddonMessagePrefix("GROUPXP")

f:SetScript("OnMouseWheel", function(self, delta)
	local scp = GroupXPFrameSCParent

	if delta > 0 then
		if scp:GetVerticalScroll() > 20 then
			scp:SetVerticalScroll(scp:GetVerticalScroll()-20)
		else
			scp:SetVerticalScroll(0)
		end
	else
		if scp:GetVerticalScroll() < maxScroll then
			scp:SetVerticalScroll(scp:GetVerticalScroll()+20)
		else
			scp:SetVerticalScroll(maxScroll)
		end
	end
end)
