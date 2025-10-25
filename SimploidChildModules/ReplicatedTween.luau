--!optimize 2
--[[
[FORKED] TweenService+ V1.1
@rek_kie on 8/9/20

Please read the devforum post here!
https://devforum.roblox.com/t/tweenservice-plus/716025

--

Forked by @cheesyhuman2
This is a heavily forked version of the original TweenService+ by @rek_kie, do not use for scripts outside simploid module.
]]--


local tweenService = {}

local clock = require(script.SyncedTime)
local GoodSignal = require(script.Parent.GoodSignal)

local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local http = game:GetService("HttpService")

local tEvent = script:WaitForChild("TweenCommunication")

export type LerpedTween = {
	Object: BasePart,
	Start: Vector3,
	Goal: Vector3,
	Elapsed: number,
	Duration: number,
	Cancel: (self: Tween) -> (),
}

if rs:IsServer() then 	
	if not clock:IsSynced() then -- make sure our clock is synced
		repeat 
			clock:Sync()
			task.wait(0.5)
		until clock:IsSynced()
	end
end

local RunService = game:GetService("RunService")

function tweenService:Construct(obj:Instance, tweenTime:number, position:Vector3, speed:number, timeThreshold:number)
	if not obj then warn("This object doesn't exist.") return end
	if timeThreshold and type(timeThreshold) ~= "number" then warn("Latency threshold must be a number!") return end
	
	local startProperties = {} 
	
	local tObject = {
		["IsCancelled"] = false, 
		["Completed"] = GoodSignal.new()
	}
	
	local tweenWait = function(n)
		n = n or 1/30
		local now = tick()
		repeat 
			rs.Heartbeat:Wait()
			if tObject.IsCancelled == true then 
				return true
			end 
		until tick() - now >= n
	end
	
	local function completionWait(t)
		task.defer(function()
			
			if tObject.IsCancelled then 
				tObject.IsCancelled = false
			end
							
			local cancelled = tweenWait(t)
						
			if not cancelled then 
				tObject.Completed:Fire(true)	
			end
			
			table.clear(tObject)
			tObject = nil
		end)
	end
	
	function tObject:Play(clients, range, rootPart, mainObject)
		
		rootPart = rootPart or "HumanoidRootPart" 
		
		if mainObject then 
			if not mainObject:IsA("BasePart") or not mainObject:IsDescendantOf(workspace) then warn("The mainObject must be a BasePart in the workspace.") return end
		end	
			
		mainObject = mainObject or obj
		
		if clients then 
			
			clients = (type(clients) == "table") and clients or {clients} -- If you only provide a single player, it turns it into a table for you
			
			if range then 
				for _, player in clients do
					
					if player and player:IsA("Player") and player.Character then 
						--Run tween
						task.defer(function() 
							local root = player.Character:FindFirstChild(rootPart)

							if root then
								
								local dist = (mainObject.Position - root.Position).Magnitude
								
								if dist <= range then  -- Tween it only for clients in the range
									tEvent:FireClient(player, obj, tweenTime, position, speed, clock:GetTime(), timeThreshold) -- Tell the client to tween the object and the timestamp of when it was sent
								end
							end
						end)
					end
				end
			else	
				
				for _, player in clients do
					if player and player:IsA("Player") and player.Character then 
						tEvent:FireClient(player, obj, tweenTime, position, speed, clock:GetTime(), timeThreshold)
					end
				end
			end
		else
			if range then 
				for _, player in game.Players:GetPlayers() do
					
					if player and player:IsA("Player") and player.Character then 
					 
						local root = player.Character:FindFirstChild(rootPart, true)

						if root then
							
							local dist = (mainObject.Position - root.Position).Magnitude
							
							if dist <= range then  -- Tween it only for clients in the range
								tEvent:FireClient(player, obj, tweenTime, position, speed, clock:GetTime(), timeThreshold) -- Tell the client to tween the object and the timestamp of when it was sent
							end
						end

					end
				end
			else
				tEvent:FireAllClients(obj, tweenTime, position, speed, clock:GetTime(), timeThreshold)
			end
		end
		
		completionWait(tweenTime)
		
	end
	
	function tObject:Cancel(clients)
		
		if clients then 
			clients = (type(clients) == "table") and clients or {clients}
			
			for _, client in clients do
				tEvent:FireClient(client, obj, nil, nil, nil, clock:GetTime(), nil, "Cancel")
			end	
		else
			tEvent:FireAllClients(obj, nil, nil, nil, clock:GetTime(), nil, "Cancel")
		end
		
		tObject.Completed:Fire(false)
		tObject.IsCancelled = true 		
	end
	
	return tObject
end

if rs:IsClient() then	
	--Calculates tween time based on given speed
	local function calculateTime(speed:number, pastPos:Vector3, nextPos:Vector3) : number
		local distance = (pastPos - nextPos).Magnitude
		return distance / speed
	end
	
	local player = game.Players.LocalPlayer 

	local tweens = {}
	tweenService.Tweens = tweens

	local function tweenPosition(object:Part, goal:Vector3, duration:number, speed:number)
		local parent = object.Parent
		if not parent then return end
		local LaggedRoot = parent:FindFirstChild("LaggedRoot")
		local tween:LerpedTween = {}
		
		tween.Object = object
		tween.Start = object.Position
		tween.Elapsed = 0
		tween.Goal = goal
		tween.Duration = duration
		
		local rootConnection = nil
		if LaggedRoot then
			tween.LaggedRoot = LaggedRoot
			rootConnection = LaggedRoot:GetPropertyChangedSignal("Position"):Connect(function()
				tween.Start = LaggedRoot.Position
				tween.Duration = calculateTime(speed, tween.Start, goal)
				tween.Elapsed = 0
			end)
		end

		function tween:Cancel()
			tweens[object] = nil
			tween = nil
			if not rootConnection then return end
			rootConnection:Disconnect()
		end
		return tween
	end

	tEvent.OnClientEvent:Connect(function(obj, tweenTime, position, speed, timestamp, threshold, modify)

		if modify then 
			local tweenToEdit = tweens[obj]

			if not tweenToEdit then -- if the tween doesn't exist, just return and give a warning
				--warn("The tween you tried to modify does not exist.")
				return 
			end

			if modify == "Cancel" then
				tweenToEdit:Cancel()
				return 	
			end
		end

		local latency = clock:GetTime() - timestamp

		local newtime = tweenTime - latency   -- If enabled, this syncs the tween up based on latency. 
																	-- Ex. If the server told a client to do a 10 second tween and it
																	-- took .7 seconds to get to the client, then the time for the 
																	-- client's tween would be 10 - .7 = 9.3 seconds. 
																	-- I'm using Quenty's module to get a global timestamp, so
																	-- that server and client time are synced. This results in a 
																	-- perfect sync between client and server tween completion.
																	-- To better see this for yourself, turn on debug mode and 
																	-- look at the output to see how the server prints exactly
																	-- when the client tween ends. (If you are in Studio, Make sure you  
																	-- stay watching only on the client though, because switching to 
																	-- the server  view pauses the client's game session on Play Solo)

		threshold = threshold or 0 -- Defaults to 0. When you set this, this basically means the amount of time 
		-- the new tween time (after calculating latency) needs to be greater than 
		-- for the tween to play. If the new tween time after calculating latency is less than 
		-- or equal to than the threshold, the tween will not play.


		if newtime > threshold and obj and position then -- some checks
			if tweens[obj] then
				tweens[obj]:Cancel()
			end
			tweens[obj] = tweenPosition(obj, position, newtime, speed)
		end
	end)
	
	RunService.RenderStepped:Connect(function(dt)
		for _, tween:LerpedTween in tweens do
			tween.Elapsed += dt 
			local alpha = math.clamp(tween.Elapsed / tween.Duration, 0, 1)
			tween.Object.Position = tween.Start:Lerp(tween.Goal, alpha)
			if alpha >= 1 then
				tween:Cancel()
			end
		end
	end)
end

return tweenService
