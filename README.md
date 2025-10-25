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
