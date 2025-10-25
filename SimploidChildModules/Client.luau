--!optimize 2
--CLIENT SIMPLOID CLASS HELPER

--Services
local ReplicatedStorage = game.ReplicatedStorage
local RunService = game:GetService("RunService")

--Module Dependencies: Change path if wanted
local Simploid = script.Parent
local Janitor = require(Simploid.Janitor)
local Config = require(Simploid.Config)


--********************************************************************************************************
--CLIENT SIMPLOID HELPER METHODS
--********************************************************************************************************
return function(Simploid)
	--Loads an animation
	function Simploid:LoadAnimation(animation:Animation) : AnimationTrack
		return self.Animator:LoadAnimation(animation)
	end
	
	--Sets Simploid attribute (NOT REPLICATED)
	function Simploid:SetAttribute(attributeName:string, value:any) : nil
		self.AnchoredRoot:SetAttribute(attributeName, value)
	end

	--Gets Simploid attribute
	function Simploid:GetAttribute(attributeName:string) : any
		return self.AnchoredRoot:GetAttribute(attributeName)
	end
	
	--Death method (NOT REPLICATED)
	function Simploid:Death() : nil
		self.Janitor:Cleanup()
		
		if Config.DEATH_MODE == "BreakJoints" then
			for _, descendant in self.Character:GetDescendants() do
				if descendant:IsA("Motor6D") then
					descendant:Destroy()
				end
			end
		elseif Config.DEATH_MODE == "Ragdoll" then
			local ragdoll = self.Character:Clone()
			self.Character:Remove()
			for _, descendant in ragdoll:GetDescendants() do
				if descendant:IsA("Motor6D") then
					local socket = Instance.new("BallSocketConstraint")
					local a1 = Instance.new("Attachment")
					local a2 = Instance.new("Attachment")
					a1.Parent = descendant.Part0
					a2.Parent = descendant.Part1
					socket.Parent = descendant.Parent
					socket.Attachment0 = a1
					socket.Attachment1 = a2
					a1.CFrame = descendant.C0
					a2.CFrame = descendant.C1
					socket.LimitsEnabled = true
					socket.TwistLimitsEnabled = true
					descendant:Destroy()
				elseif descendant:IsA("BasePart") then
					descendant.CanCollide = true
					descendant.Anchored = false
				end
			end
			ragdoll.Parent = workspace
		elseif Config.DEATH_MODE == "Destroy" then
			self:Destroy()
			return
		end

		task.wait(Config.SIMPLOID_RAGDOLL_TIME)
		self:Destroy()
	end

	--Cleanup method
	function Simploid:Destroy() : nil
		self.Animations = nil
		self.Janitor:Destroy()
		self.Janitor = nil
		self = nil
	end
end

