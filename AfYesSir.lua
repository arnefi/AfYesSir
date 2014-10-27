-----------------------------------------------------------------------------------------------
-- Client Lua Script for AfYesSir
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "Window"
require "CSIsLib" 


-----------------------------------------------------------------------------------------------
-- AfYesSir Module Definition
-----------------------------------------------------------------------------------------------

-- local AfYesSir = {} 
AfYesSir = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("AfYesSir", false, {}, "Gemini:Hook-1.0")
-- local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("AfYesSir", true)

 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local tTravel = {
	-- travel.*\?$
	254998, -- Celestion
	374347, -- Whitevale
	374355, -- Malgrave
	374356, -- Grimvault
	374357, -- Halon Ring
	374358, -- Virtue's Landing
	374359, -- Northern Wastes
	374360, -- Crimson Badlands
	374361, -- Coralus (?)
	374369, -- Illium
	374385, -- Eternity Isles (?)
	412461, -- Walker's Landing
	412462, -- Virtue's Landing
	412463, -- Thayd
	412464, -- Illium
	415311, -- Everstar Grove (?)
	415314, -- Celestion
	415451, -- Levian Bay
	423303, -- Space Station Venture
	424935, -- Halon Ring
	424937, -- Illium
	424938, -- Thayd
	425940, -- Whitevale
	435622, -- Wilderrun
	447312, -- Galactic Observer
	452812, -- Mayday Expedition
	467064, -- Malgrave
	494148, -- Sylan Glade by Kurg
	529591, -- Northern Wastes
	530362, -- Thayd
	530730, -- Northern Wastes
	530731, -- Illium
	537969, -- Crimson Badlands
	537970, -- Travel to Illium?
	537971, -- Travel to Crimson Badlands?
	537972, -- Travel to Thayd?	
	573453, -- Travel to Grimveil Enclave?
	
	-- teleport.*\?$
	314866, -- Teleport to Palerock Post in Northwest Whitevale?
	314867, -- Teleport to Thermock Hold in Northeast Whitevale?
	314868, -- Teleport to Wigwalli Village in Central Whitevale?
	314869, -- Teleport to Prosperity Junction in Southern Whitevale?
	315490, -- Teleport to Algoroc?
	315532, -- Teleport to Celestion?	
	315572, -- Teleport to Ellevar?
	315573, -- Teleport to Deradune?
	315604, -- Home in the sky
	378815, -- Would you like to teleport to Luminous Gardens in Illium?
	378816, -- Would you like to teleport to Legion's Way in Illium?
	378817, -- Would you like to teleport to Spaceport Alpha in Illium?
	378818, -- Would you like to teleport to Fate's Landing in Illium?
	411611, -- Would you like to teleport to Thermock Hold?
	411615, -- Would you like to teleport to Snowfade Grounds?
	411620, -- Would you like to teleport to Locus Dawn?
	427337, -- Would you like to teleport to Graylight?
	488459, -- Would you like to teleport to Academy Corner in Thayd?
	488463, -- Would you like to teleport to Traverse Tunnels in Thayd?
	488464, -- Would you like to teleport to Fortune's Ground in Thayd?
	488465, -- Would you like to teleport to Arborian Gardens in Thayd?
	508668, -- Teleport to Deradune?
	508669, -- Teleport to Algoroc?
	508737, -- Teleport to Illium?
	508739, -- Teleport to Thayd?
	511342, -- Teleport to Bind Location?
	511774, -- Teleport to Housing?
	561886, -- Teleport to Thayd?
	561887, -- Teleport to Illium?
	618450, -- Teleport to the Halls of the Infinite Mind?
	618451, -- Teleport to Halls of the Infinite Mind
	
	-- head to.*\?$
	405288, -- Head to Virtue's Landing?
	405289, -- Head to Virtue's Landing
	405294, -- Head to Sovereign's Landing?
	406285, -- Head to Walker's Landing?
	406286, -- Head to Touchdown Site Bravo?
	406287, -- Head to Walker's Landing
	406288, -- Head to Touchdown Site Bravo
	
	-- Enigma Chamber
	582459, -- Enter the Enigma Chamber?
	582460, -- Leave the Enigma Chamber?
	582461, -- Take the elevator to the Enigma Chamber?
	582462, -- Take the elevator to the Reception Room?
}

local strVersion = "@project-version@"


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function AfYesSir:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.topress = 0
	
	-- category defaults
	o.doTravel = true

    return o
end


function AfYesSir:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"CSI",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- AfYesSir OnLoad
-----------------------------------------------------------------------------------------------

function AfYesSir:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("AfYesSir.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("AfYesSirSprite.xml", "AfYesSirSprite")
end


-----------------------------------------------------------------------------------------------
-- AfYesSir OnDocLoaded
-----------------------------------------------------------------------------------------------

function AfYesSir:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AfYesSirForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndMain:Show(false, true)
		
		-- localize window
		local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("AfYesSir", true)
		self.wndMain:FindChild("lblDescription"):SetText(L["lblDescription"])
		self.wndMain:FindChild("chkTransport"):SetText(L["chkTransport"])
		self.wndMain:FindChild("lblVersion"):SetText(strVersion)
			
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		
		Apollo.RegisterSlashCommand("afyes", "Configure", self)
		Apollo.RegisterEventHandler("AfYesSir_Configure", "Configure", self)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

		self.timer = ApolloTimer.Create(10.0, false, "DelayHook", self)
		self.presstimer = ApolloTimer.Create(0.1, true, "Press", self)
		
		-- Do additional Addon initialization here
	end
end


-----------------------------------------------------------------------------------------------
-- AfYesSir OnInterfaceMenuListHasLoaded: create start menu entry
-----------------------------------------------------------------------------------------------

function AfYesSir:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "afYesSir", {"AfYesSir_Configure", "", "AfYesSirSprite:afyesmenuicon"})
end


-----------------------------------------------------------------------------------------------
-- AfYesSir OnSave: save settings
-----------------------------------------------------------------------------------------------

function AfYesSir:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local tSavedData = {}
		tSavedData.doTravel = self.doTravel
		return tSavedData
	end
	return
end


-----------------------------------------------------------------------------------------------
-- AfYesSir OnRestore: load settings
-----------------------------------------------------------------------------------------------

function AfYesSir:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		if tSavedData.doTravel ~= nil then self.doTravel = tSavedData.doTravel end
	end
end


-----------------------------------------------------------------------------------------------
-- AfYesSir DelayHook: let other great addons grab a hook first
-----------------------------------------------------------------------------------------------

function AfYesSir:DelayHook()
	self:RawHook(Apollo.GetAddon("CSI"), "BuildYesNo")
	self.timer = nil
end


-----------------------------------------------------------------------------------------------
-- AfYesSir BuildYesNo: test whether to react on window, otherwise call original function
-----------------------------------------------------------------------------------------------

function AfYesSir:BuildYesNo(something, tActiveCSI)
	-- print question to sytem chat. To be removed in later versions.
	self:log(tActiveCSI.strContext)
	if self:ShoudIPress(tActiveCSI.strContext) then
		self.topress = 20
		self.presstimer:Start()			
	else
		self.topress = 0
		self.hooks[Apollo.GetAddon("CSI")].BuildYesNo(something, tActiveCSI, bShow)
	end
end


-----------------------------------------------------------------------------------------------
-- AfYesSir ShouldIPress: check for strMessage in our category tables
-----------------------------------------------------------------------------------------------

function AfYesSir:ShoudIPress(strMessage)
	-- Category Transportation
	if self.doTravel then
		for _, id in pairs(tTravel) do
			if strMessage == Apollo.GetString(id) then return true end
		end
	end
	return false
end


-----------------------------------------------------------------------------------------------
-- AfYesSir Press: waiting for CSI to be ready, checking every 0.1 sec, 2 sec max
-----------------------------------------------------------------------------------------------

function AfYesSir:Press()
	if self.topress == 0 then
		self.presstimer:Stop()
		return
	end
	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI and CSIsLib.IsCSIRunning() then
        CSIsLib.CSIProcessInteraction(true)
		self.topress = 0
		return
    end	
	self.topress = self.topress - 1
end


-----------------------------------------------------------------------------------------------
-- AfYesSir log: print strMeldung to system chat
-----------------------------------------------------------------------------------------------

function AfYesSir:log(strMeldung)
	if strMeldung == nil then strMeldung = "nil" end
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strMeldung, "afYesSir")
end


-----------------------------------------------------------------------------------------------
-- AfYesSirForm Functions
-----------------------------------------------------------------------------------------------

-- when the OK button is clicked
function AfYesSir:OnOK()
	self.doTravel = self.wndMain:FindChild("chkTransport"):IsChecked()
	self.wndMain:Close()
end

-- when the Cancel button is clicked
function AfYesSir:OnCancel()
	self.wndMain:Close()
end

-- when "start menu" button is pressed or slash command was entered
function AfYesSir:Configure()
	if self.wndMain:IsShown() then 
		self.wndMain:Close() 
		return
	end
	self.wndMain:Invoke()
	
	self.wndMain:FindChild("chkTransport"):SetCheck(self.doTravel)
end


-----------------------------------------------------------------------------------------------
-- AfYesSir Instance
-----------------------------------------------------------------------------------------------
local AfYesSirInst = AfYesSir:new()
AfYesSirInst:Init()