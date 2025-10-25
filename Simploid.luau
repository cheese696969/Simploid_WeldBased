--!optimize 2
--[[SIMPLOID CLASS=================================================================================================================
	By @cheesyhuman2
	10/26/2025
	
	Simploids aim to create a much more lightweight and more performant alternative to Humanoids when you need NPCs.
	Your npc rigs must have a HumanoidRootPart as its PrimaryPart.		
	
	Features:
	-No need for a humanoid
	-Almost does not rely on physics 						(Only uses physics when falling is detected)
	-No smooth movement on server, only on client 			(Helps heavily in network efficiency)
	-Uses raycasting to simulate collisions
	-Built in pathfinding system with pathfinding service
	-Update server movement position whenever you want
	
	Drawbacks:
	-Only the most basic methods of humanoids are reproduced
	-NPC characters may go through walls
	-Does not implement any of the humanoid events
	-Does not implement most of the humanoid properties
	-Does not implement any of the humanoid functions
	-Does not implement any of the humanoid's other features
	
	If you do want to implement specific humanoid features, you can easily do so by forking this module, the ServerHelper
	and ClientHelper modules which are childrens of this module.
	
	To start using Simploids, simply require this module in the SERVER AND CLIENT (Using a script and a local script)
	and use the .new() constructor ON THE SERVER to create a Simploid.
	
	EXAMPLE USAGE:
	In local script:
		require(game.ReplicatedStorage.Simploid)
		
	In server script:
		local Simploid = require(game.ReplicatedStorage.Simploid)
		local character = workspace.Dummy 							--Have your own dummy rig character to use.
		local storage = workspace.NpcFolder							--Make sure the folder exists as a descendant of workspace, but not a descendant of a basepart.
		local new_simploid = Simploid.new(character, storage)
		new_simploid:PathfindTo(Vector3.new(10,0,10))				--Moves npc dummy to the given position
		
	Simploid's Usable Attributes and Methods in the github readme documentation:		
	https://github.com/cheese696969/Simploid
	
]]

--Services
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game.Players

--[[
Module Dependencies: Change path if wanted
Make sure you have the module dependencies installed/created as an instance as a child of this module.
To get the latest version of these module dependencies, go to:
https://github.com/cheese696969/Simploid
]]
local Janitor = require(script.Janitor)
local ReplicatedTween = require(script.ReplicatedTween)
local GoodSignal = require(script.GoodSignal)
local Config = require(script.Config)


--GENERAL SETUP====================================================================================================================
--MODULE TABLE (For Client and Server)-----------------------------------------------------------
local Simploid = {}
Simploid.__index = Simploid

--Put ActiveSimploids in the module--------------------------------------------------------------
--This is a table of all initialized simploids that are still not cleaned by :Destroy()
local ActiveSimploids = {}
Simploid.ActiveSimploids = ActiveSimploids



--GETTERS----------------------------------------------------------------------------------------
--[[
These are for manipulation of simploids on client or server if you need it for 
other scripts other than the script that constructed the simploid

Note In Local Scripts and client usage:
A character's simploid or basically the whole rig may not be streamed in the client yet.
Therefore, the ActiveSimploids Table only contains streamed in rigs.
]]

--Gets an active simploid.
function Simploid.GetSimploidFromCharacter(character:Model) : Model?
	return ActiveSimploids[character]
end
--Gets all active simploids.
function Simploid.GetAllSimploids(character:Model) : { [Model]: Simploid }
	return table.clone(ActiveSimploids)
end
--------------------------------------------------------------------------------------------------

--IF MODULE IS REQUIRED ON SERVER==================================================================================================
if RunService:IsServer() then
	--Remote Events----------------------------------------------------------------------------------
	local FallEvent:RemoteEvent = Instance.new("RemoteEvent")
	FallEvent.Name = "FallEvent"
	FallEvent.Parent = script
	
	--Default Simploid Storage-----------------------------------------------------------------------
	local SimploidStorage:Folder = Instance.new("Folder")
	SimploidStorage.Name = "__SimploidStorage"
	SimploidStorage.Parent = workspace
	
	--To Update NPCs when it is falling--------------------------------------------------------------
	FallEvent.OnServerEvent:Connect(function(_, character)
		local self = ActiveSimploids[character]
		if self then
			self:CancelMoveTo_FallConstrained()
		end
	end)
	
	--Server Typecasting-----------------------------------------------------------------------------
	type Simploid = {
		--Attributes
		RayDownParams: RaycastParams,
		--Methods
		SetAttribute: (self:Simploid, attributeName:string, attributeValue:any) -> nil,
		GetAttribute: (self:Simploid, attributeName:string) -> any,
		MoveTo: (self:Simploid, position:Vector3) -> nil,
		CancelMoveTo: (self:Simploid) -> nil,
		PathfindTo: (self: Simploid, position:Vector3) -> nil,
		SetTimedPosition: (self:Simploid) -> nil,
		Wander: (self:Simploid) -> nil,
		Death: (self:Simploid) -> nil,
		Destroy: (self:Simploid) -> nil
	}
	require(script.Server)(Simploid)
--*************************************************************************************************************
--Simploid Server constructor
--*************************************************************************************************************
	function Simploid.new(character:Model?, storage:any) : Simploid
		assert(character, "A character model is required!")
		if not character:IsA("Model") then error("The character "..character.Name.." is not a model!") return end
		
		if storage then		
			--Check if storage is a descendant of a basepart
			local ancestor:BasePart? = storage:FindFirstAncestorWhichIsA("BasePart")
			if ancestor then
				error("Storage cannot have a basepart ancestor! | Ancestor Part: "..ancestor.Name)
			end
		else
			storage = SimploidStorage
		end
		
		local self = setmetatable({}, Simploid)
		self.Janitor = Janitor.new()

		--CHARACTER SETUP-------------------------------------------------------------------------
		self.Character = character
		self.HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 60)
		assert(self.HumanoidRootPart, "No HumanoidRootPart Found")
		
		--PARTS SETUP-----------------------------------------------------------------------------
		--Anchored Root
		local AnchoredRoot:BasePart = self.HumanoidRootPart:Clone()
		AnchoredRoot.Transparency = 0
		AnchoredRoot.Anchored = true
		AnchoredRoot.Name = "Simploid"
		AnchoredRoot:ClearAllChildren()
				
		--ATTRIBUTES:(Like a normal humanoid's properties ... Only some are implemented)----------
		--[[
		Setup Attributes 
		-> Let the anchored root act as the "Simploid" object	
		-> These act like instance properties 
		-> These are replicated from server to client
		-> Some are imitated from roblox humanoids, others are custom added (For updates)
		-> To trigger events on client
		]]
		
		--Humanoid imitated attributes
		AnchoredRoot:SetAttribute("MaxHealth", 	Config.DEFAULT_ATTRIBUTES.MaxHealth)
		AnchoredRoot:SetAttribute("Health", 	Config.DEFAULT_ATTRIBUTES.Health)
		AnchoredRoot:SetAttribute("WalkSpeed", 	Config.DEFAULT_ATTRIBUTES.WalkSpeed)
		AnchoredRoot:SetAttribute("RootHeight", Config.DEFAULT_ATTRIBUTES.RootHeight)
		
		--State Attributes
		AnchoredRoot:SetAttribute("State", "Running")
		
		--Custom Attributes
		AnchoredRoot:SetAttribute("CanFallUpdate", true)

		--Anchored Root Weld
		local AnchoredRootWeld:Weld = Instance.new("Weld")
		AnchoredRootWeld.Name = "AnchoredRootWeld"
		AnchoredRootWeld.Part0 = AnchoredRoot
		AnchoredRootWeld.Part1 = self.HumanoidRootPart
		AnchoredRootWeld.C0 = CFrame.identity
		AnchoredRootWeld.Enabled = true
		
		--Lagged Root
		local LaggedRoot:BasePart = AnchoredRoot:Clone()
		LaggedRoot.Name = "LaggedRoot"
		
		self.AnchoredRoot = AnchoredRoot
		self.AnchoredRootWeld = AnchoredRootWeld
		self.LaggedRoot = LaggedRoot
		
		AnchoredRoot.Parent = character
		AnchoredRootWeld.Parent = AnchoredRoot
		LaggedRoot.Parent = character
		
		--STATES----------------------------------------------------------------------------------
		self.NormalState = true 						--DO NOT CHANGE : script changeable only
		
		--HELPING ATTRIBUTES----------------------------------------------------------------------
		self.RayDirection = Vector3.new(0, -Config.RAY_DOWN_DIST, 0)
		self.WaypointHeight = AnchoredRoot:GetAttribute("RootHeight") - Config.WAYPOINT_Y_OFFSET
		self.HeightAdditive = Vector3.new(0, AnchoredRoot:GetAttribute("RootHeight"), 0)
		
		--EVENTS CONNECTION-----------------------------------------------------------------------
		self.Janitor:Add(AnchoredRoot:GetAttributeChangedSignal("RootHeight"):Connect(function()
			self.WaypointHeight = AnchoredRoot:GetAttribute("RootHeight") - Config.WAYPOINT_Y_OFFSET
			self.HeightAdditive = Vector3.new(0, AnchoredRoot:GetAttribute("RootHeight"), 0)
		end), "Disconnect")
		
		self.Janitor:Add(AnchoredRoot:GetAttributeChangedSignal("Health"):Connect(function()
			if AnchoredRoot:GetAttribute("Health") <= 0 then
				self:Death()
			end
		end), "Disconnect")

		self.Janitor:Add(AnchoredRoot:GetPropertyChangedSignal("Position"):Connect(function()
			self.LaggedRoot.Position = AnchoredRoot.Position
		end), "Disconnect")

		
		--RAY DOWN PARAMS-------------------------------------------------------------------------
		self.RayDownParams = RaycastParams.new()
		self.RayDownParams.FilterType = Enum.RaycastFilterType.Exclude
		self.RayDownParams.FilterDescendantsInstances = {character}
		self.RayDownParams.IgnoreWater = false
		
		--MOVEMENT TWEEN SETUP--------------------------------------------------------------------
		self.CurrentTween = nil
		self.CurrentNextPosition = nil
		self.CurrentPastPosition = nil
		self.CurrentPastTime = nil
		
		--PATH SETUP------------------------------------------------------------------------------
		self.Path = PathfindingService:CreatePath({
			AgentRadius = (self.HumanoidRootPart.Size.Z/2) + Config.SIMPLOID_RADIUS_ADDITIVE,
			AgentHeight = (self.HumanoidRootPart.Size.Y/2) + Config.SIMPLOID_HEIGHT_ADDITIVE,
			AgentCanJump = false,
			WaypointSpacing = Config.BASE_WAYPOINT_SPACING
		})
		
		character.Parent = storage
		return self
	end
	
--IF MODULE IS REQUIRED ON CLIENT==================================================================================================
else
	--Client Typecasting-----------------------------------------------------------------------------
	type Simploid = {
		--Attributes
		RayDownParams:RaycastParams,
		--Methods
		SetAttribute: (self:Simploid, attributeName:string, attributeValue:any) -> nil,
		GetAttribute: (self:Simploid, attributeName:string) -> any,
		LoadAnimation: (self:Simploid, animationTrack:Animation) -> AnimationTrack,
		Death: (self:Simploid) -> nil,
		Destroy: (self:Simploid) -> nil,
		
	}
	require(script:WaitForChild("Client"))(Simploid)
--*************************************************************************************************************
--Simploid Client Constructor
--*************************************************************************************************************
	function Simploid.new(character:Model?) : Simploid
		assert(character, "No Character Found")
		
		local self = setmetatable({}, Simploid)
		self.Janitor = Janitor.new()
		
		--CHARACTER SETUP-------------------------------------------------------------------------
		self.Character = character
		local AnchoredRoot = character:WaitForChild("Simploid")
		self.AnchoredRoot = AnchoredRoot
		self.AnchoredRootWeld = self.AnchoredRoot:WaitForChild("AnchoredRootWeld")	
		
		--Helping Properties
		self.RayDirection = Vector3.new(0, -Config.RAY_DOWN_DIST, 0)
		self.HeightAdditive = Vector3.new(0, AnchoredRoot:GetAttribute("RootHeight"), 0)
		
		--EVENTS CONNECTION-----------------------------------------------------------------------
		self.Janitor:Add(AnchoredRoot:GetAttributeChangedSignal("RootHeight"):Connect(function()
			self.HeightAdditive = Vector3.new(0, AnchoredRoot:GetAttribute("RootHeight"), 0)
		end), "Disconnect")
		
		self.Janitor:Add(AnchoredRoot:GetAttributeChangedSignal("State"):Connect(function()
			if AnchoredRoot:GetAttribute("State") == "Dead" then
				self:Death()
			end
		end), "Disconnect")
		
		--SIMPLOID UPDATE DEPENCDENCIES-----------------------------------------------------------
		self.CanFallUpdate = true
		
		--RAY DOWN PARAMS-------------------------------------------------------------------------
		self.RayDownParams = RaycastParams.new()
		self.RayDownParams.FilterType = Enum.RaycastFilterType.Exclude
		self.RayDownParams.FilterDescendantsInstances = {character}
		self.RayDownParams.IgnoreWater = false

		--ANIMATION DEPENDECIES-------------------------------------------------------------------
		local AnimationController = Instance.new("AnimationController")
		AnimationController.Parent = character
		self.Animator = Instance.new("Animator")

		return self
	end
	
	--Remote Events----------------------------------------------------------------------------------
	local FallEvent:RemoteEvent = script:WaitForChild("FallEvent")

	--Default Simploid Storage-----------------------------------------------------------------------
	local SimploidStorage = workspace:WaitForChild("__SimploidStorage")
	local SimploidStreamed = {}
	
	for _, character in SimploidStorage:GetChildren() do
		if not ActiveSimploids[character] then
			ActiveSimploids[character] = Simploid.new(character)
		end
		SimploidStreamed[character] = ActiveSimploids[character]
	end
	SimploidStorage.ChildAdded:Connect(function(character)
		if not ActiveSimploids[character] then
			ActiveSimploids[character] = Simploid.new(character)
		end
		SimploidStreamed[character] = ActiveSimploids[character] 
	end)
	SimploidStorage.ChildRemoved:Connect(function(character)
		SimploidStreamed[character] = nil
	end)
	
	--Root Updating-----------------------------------------------------------------------------------
	local player = Players.LocalPlayer
	local currentLocalRoot:BasePart? = nil
	if player.Character then currentLocalRoot = player.Character:FindFirstChild("HumanoidRootPart") end
	player.CharacterAdded:Connect(function(character)
		currentLocalRoot = character:FindFirstChild("HumanoidRootPart")
	end)
	player.CharacterRemoving:Connect(function()
		currentLocalRoot = nil
	end)
	
	--Config Helping Variables
	local ROOT_TO_SIMPLOID_UPDATE_DIST = Config.ROOT_TO_SIMPLOID_UPDATE_DIST
	local SIMPLOID_FALL_THROTTLE = Config.SIMPLOID_FALL_THROTTLE
	
	--Heartbeat Updating------------------------------------------------------------------------------
	RunService.Heartbeat:Connect(function()
		for character, self in SimploidStreamed do
			if not character:IsDescendantOf(workspace) then continue end

			local AnchoredRoot = self.AnchoredRoot
			
			if (AnchoredRoot.Position - currentLocalRoot.Position).Magnitude <= ROOT_TO_SIMPLOID_UPDATE_DIST then 
				local result = workspace:Raycast(self.AnchoredRoot.Position + self.HeightAdditive, self.RayDirection, self.RayDownParams)

				if result then
					local cf = self.AnchoredRoot.CFrame:ToObjectSpace(CFrame.new(result.Position + self.HeightAdditive))
					cf = CFrame.new(cf.Position)
					self.AnchoredRootWeld.C0  = cf
				else
					self.AnchoredRootWeld.C0  = CFrame.identity
					if not self.AnchoredRoot:GetAttribute("CanFallUpdate") then continue end
					if not self.CanFallUpdate then continue end
					self.CanFallUpdate = false
					FallEvent:FireServer(self.Character)
					task.wait(SIMPLOID_FALL_THROTTLE)
					self.CanFallUpdate = true
				end	
			else
				self.AnchoredRootWeld.C0  = CFrame.identity
			end
		end
	end)
end


return Simploid
