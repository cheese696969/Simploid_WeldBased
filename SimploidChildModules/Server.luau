--!optimize 2
--SERVER SIMPLOID CLASS HELPER

--Services
local ReplicatedStorage = game.ReplicatedStorage
local PathfindingService = game:GetService("PathfindingService")

--Module Dependencies: Change path if wanted
local Simploid = script.Parent
local Janitor = require(Simploid.Janitor)
local ReplicatedTween = require(Simploid.ReplicatedTween)
local Config = require(Simploid.Config)

--Storage
local Terrain = workspace.Terrain

--Terain helping variables
local RESOLUTION = 4 					-- voxel resolution (4x4x4 studs)
local HALF = Vector3.new(1, 1, 1) 		--Initial terrain region check size

--********************************************************************************************************
--SERVER SIMPLOID HELPER METHODS
--********************************************************************************************************
return function(Simploid)
	--Wander Method for testing
	function Simploid:Wander(range: number) : nil
		range = range or 50
		task.defer(function()
			while true do
				-- get Simploid's current position
				local origin = self.HumanoidRootPart.Position
				-- pick a random point within the given range
				local randomX = origin.X + (math.random() - 0.5) * 2 * range
				local randomZ = origin.Z + (math.random() - 0.5) * 2 * range
				local point = Vector3.new(randomX, origin.Y, randomZ)

				-- pathfind to that point
				self:PathfindTo(point)

				task.wait(1)
			end
		end)
	end
	
	--Sets Simploid attribute
	function Simploid:SetAttribute(attributeName:string, value:any) : nil
		self.AnchoredRoot:SetAttribute(attributeName, value)
	end

	--Gets Simploid attribute
	function Simploid:GetAttribute(attributeName:string) : any
		return self.AnchoredRoot:GetAttribute(attributeName)
	end
	
	--Move an Simploid to a point
	function Simploid:MoveTo(point:Vector3) : boolean
		local AnchoredRoot = self.AnchoredRoot
		local speed = self:GetAttribute("WalkSpeed")

		local nextPosition =  point + Vector3.new(0, self.WaypointHeight, 0)
		local pastPosition = AnchoredRoot.Position
		local pastTime = time()
		local tweenTime = self:CalculateTime(speed, pastPosition, nextPosition)
		
		if Config.MOVEMENT_LOOK_MODE == "XZ" then
			AnchoredRoot.CFrame = CFrame.lookAt(pastPosition, Vector3.new(nextPosition.X, pastPosition.Y, nextPosition.Z))
		elseif Config.MOVEMENT_LOOK_MODE == "XYZ" then
			AnchoredRoot.CFrame = CFrame.lookAt(pastPosition, nextPosition)
		end
		
		local tween = ReplicatedTween:Construct(AnchoredRoot, tweenTime, nextPosition, speed)
		tween:Play(nil, Config.SERVER_PLAYER_TO_SIMPLOID_TWEEN_DISTANCE)

		self.CurrentTween = tween
		self.CurrentPastTime = pastTime
		self.CurrentPastPosition = pastPosition
		self.CurrentNextPosition = nextPosition

		local completed = false
		tween.Completed:Once(function(isCompleted)
			if isCompleted then
				completed = true
				self.CurrentTween = nil
				self:UpdatePosition(nextPosition)
			else	
				self.CurrentTween = nil
				self:UpdatePosition(self:GetTimedPosition(speed, time() - self.CurrentPastTime, self.CurrentPastPosition, nextPosition))
			end
		end)
		tween.Completed:Wait()
		task.wait()
		return completed
	end

	--Pathfind an Simploid along a path
	function Simploid:PathfindTo(targetPosition:Vector3) : nil
		if not self.NormalState then return end
		local waypoints : Path | Vector3? = self:ComputePath(targetPosition)

		if waypoints then
			if typeof(waypoints) == "Instance" and waypoints:IsA("Path") then

				for _, point in waypoints:GetWaypoints() do
					self:ShowPoint(point.Position, Color3.new(1, 0, 0))
				end

				for i, point in ipairs(waypoints:GetWaypoints()) do
					if i > 1 then --Skip point 1 (Starting point)
						if self.NormalState then
							local completed = self:MoveTo(point.Position)
							if not completed then break end
						else
							break
						end
					end
				end

			elseif typeof(waypoints) == "Vector3" then
				if self.NormalState then
					self:MoveTo(waypoints)
					task.wait()
				end
			end
		end
	end
	
	--Updates the position of the Simploid based on the time of movement
	function Simploid:SetTimedPosition() : nil
		if not self.CurrentTween then return end
		self:UpdatePosition(self:GetTimedPosition(self.WalkSpeed, time() - self.CurrentPastTime, self.CurrentPastPosition, self.CurrentNextPosition))
	end
	
	--Method on death
	function Simploid:Death() : nil
		self:SetAttribute("State", "Dead")
		self:CancelMoveTo()

		self.Janitor:Cleanup()
		
		task.wait(Config.SIMPLOID_RAGDOLL_TIME + 1)
		self:Destroy()
	end

	--Cleanup method
	function Simploid:Destroy() : nil
		self.Janitor:Destroy()
		self.Character:Destroy()
		self = nil
	end
	
	
	
	
	
--****************************************************************************************************************************	
--PROTECTED METHODS : RECOMMENDED TO NOT MESS WITH THESE METHODS UNLESS YOU KNOW WHAT YOU'RE DOING--
--****************************************************************************************************************************
	
	--Gets position at current tween time
	function Simploid:GetTimedPosition(speed:number, elapsed:number, pastPos:Vector3, nextPos:Vector3) : Vector3
		local direction = (nextPos - pastPos).Unit
		local distance = speed * elapsed
		return pastPos + direction * distance
	end

	--Calculates tween time based on given speed
	function Simploid:CalculateTime(speed:number, pastPos:Vector3, nextPos:Vector3) : number
		local distance = (pastPos - nextPos).Magnitude
		return distance / speed
	end

	function Simploid:ShowPoint(point:Vector3, color:Color3) : nil
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Material = Enum.Material.Neon
		part.Position = point
		part.Size = Vector3.new(1,1,1)
		part.Color = color or Color3.new(1, 1, 1)
		part.Anchored = true
		part.CanTouch = false
		part.CanCollide = false
		part.CanQuery = false

		task.defer(function()
			task.wait(100)
			part:Destroy()
		end)
		part.Parent = workspace
	end

	--Cast ray to check the ground
	function Simploid:CastGroundCheck() : RaycastResult?
		return workspace:Raycast(
			self.AnchoredRoot.Position + self.HeightAdditive,					--ORIGIN
			Vector3.new(0, -Config.RAY_DOWN_DIST, 0),							--DIRECTION
			self.RayDownParams)														--RAY PARAMS
	end

	--Put Simploid to ground
	function Simploid:UpdateAnchoredWeldC0(result) : nil
		if result then
			local cf = self.AnchoredRoot.CFrame:ToObjectSpace(CFrame.new(result.Position + self.HeightAdditive))
			cf = CFrame.new(cf.Position)
			self.AnchoredRootWeld.C0 = cf
		else
			self.AnchoredRootWeld.C0 = CFrame.identity
		end
	end

	--Checks if the Simploid is inside terrain
	function Simploid:IsInsideTerrain() : boolean
		local pos = self.AnchoredRoot.Position
		local material = Terrain:ReadVoxels(Region3.new(pos - HALF, pos + HALF):ExpandToGrid(RESOLUTION), RESOLUTION)[1][1][1]
		-- If material isn’t Air, it's inside terrain
		return material ~= Enum.Material.Air
	end

	--Forces the Simploid to calculate where it is and position it in that current moment of time
	function Simploid:CancelMoveTo() : nil
		if self.CurrentTween then
			self.CurrentTween:Cancel()
		end
	end
	
	--Forces the Simploid to calculate where it is and position it in that current moment of time, with a fall timer constraint
	function Simploid:CancelMoveTo_FallConstrained() : nil
		if self:GetAttribute("CanFallUpdate") == false then return end
		self:SetAttribute("CanFallUpdate", false)
		self:CancelMoveTo()
		task.wait(Config.UPDATE_THROTTLE)
		self:SetAttribute("CanFallUpdate", true)
	end

	--Updates the position of the Simploid
	function Simploid:UpdatePosition(nextPosition:Vector3) : nil
		local AnchoredRoot = self.AnchoredRoot
		local result = workspace:Raycast(
			nextPosition + self.HeightAdditive,	
			Vector3.new(0, -Config.RAY_DOWN_DIST, 0),			
			self.RayDownParams)

		if result then
			local p = result.Position + self.HeightAdditive
			self.CurrentPastPosition = p
			self.CurrentPastTime = time()
			AnchoredRoot.Position = p
		else
			AnchoredRoot.Position = nextPosition
		end

		self:UpdateAnchoredWeldC0(result)

		if result then return end
		if self:IsInsideTerrain() then return end

		self.NormalState = false
		AnchoredRoot.CanCollide = true
		AnchoredRoot.Anchored = false
		AnchoredRoot:SetNetworkOwner(nil)

		while true do
			task.wait(Config.SERVER_FALLING_WAIT)
			result = self:CastGroundCheck()
			if result then
				AnchoredRoot.Position = result.Position + self.HeightAdditive
				AnchoredRoot.CanCollide = false
				AnchoredRoot.Anchored = true
				self:UpdateAnchoredWeldC0(result)
				self.NormalState = true
				break
			end
		end
	end

	--Runs a check to find an exit from a pathfind error spot
	function Simploid:GetExitErrorPoint() : Vector3?
		local origin = self.AnchoredRoot.Position
		local dir = Config.DIRECTIONS[math.random(1, 8)]
		local rayDirection = dir * Config.RAY_EXIT_DIST
		local result = workspace:Raycast(origin, rayDirection, self.RayDownParams)

		if not result then
			return (origin + dir * Config.RAY_EXIT_DIST) - Vector3.new(0, self.WaypointHeight, 0)
		end
		
		warn("SIMPLOID IS STUCK WITHOUT EXIT POINTS!")
		return nil
	end

	--Pathfinds and returns a path to a target position
	function Simploid:ComputePath(targetPosition:Vector3) : (Path | Vector3)?
		local path = self.Path

		local success, errorMessage = pcall(function()
			path:ComputeAsync(self.HumanoidRootPart.Position, targetPosition)
		end)

		if success and path.Status == Enum.PathStatus.Success then
			return path
		else
			return self:GetExitErrorPoint()
		end
	end
end
