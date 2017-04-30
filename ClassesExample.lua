require "Classes"

--[[
	Example
]]--
Actor = class("Actor")
function Actor:Initialize()
	print("Actor:Initialize")
end
function Actor:Run()
	print("Actor:Run")
end

World = class("World")
World.Actors = {}
function World:AddActor(inActor)
	if not inActor:IsInstanceOf(Actor) then
		print("Error: World only add Actor type")
	end
	
	table.insert(self.Actors, inActor)
end
function World:Run()
	print("World:Run")
	for i,actor in pairs(self.Actors) do
		actor:Run()
	end
end

Game = class("Game");
Game.World = {}
function Game:Initialize()
	print("Game:Initialize")
	
	self.World = World();
end
function Game:Run()
	print("Game:Run")
	
	self.World:Run()
	
	self:DoRun()
end
function Game:DoRun()
	print("Game:DoRun")
end


StaticMeshActor = class("StaticMeshActor", Actor)
function StaticMeshActor:Initialize()
	print("StaticMeshActor:Initialize")
end
function StaticMeshActor:Run()
	print("StaticMeshActor:Run")
end

SkeletonMeshActor = class("SkeletonMeshActor", Actor)
function SkeletonMeshActor:Run()
	print("SkeletonMeshActor:Run")
end

RockActor = class("RockActor", StaticMeshActor)
function RockActor:Initialize()
	print("RockActor:Initialize")
end
function RockActor:Run()
	print("RockActor:Run")
end

Player = class("Player", SkeletonMeshActor)
function Player:Initialize()
	print("Player:Initialize")
end
function Player:Run()
	print("Player:Run")
end

RPGGame = class("RPGGame", Game)
function RPGGame:Initialize()
	print("RPGGame:Initialize")
	
	self.World:AddActor(RockActor())
	self.World:AddActor(Player())
end
function RPGGame:Run()
	print("RPGGame:Run")
	Game.Run(self)
end
function RPGGame:DoRun()
	print("RPGGame:DoRun")
end

GameClass = Reflect.GetClass("RPGGame")

--[[
RPGGame:Initialize
	Game:Initialize
		World:Initialize
	-RockActor:Initialize
		StaticMeshActor:Initialize
			Actor:Initialize
	World:AddActor
	
	-Player:Initialize
		Actor:Initialize
	World:AddActor
	
GameInstance = {
	Class [class RPGGame]
	Super = {
		Class [class Game]
		Super = nil
		InstanceMembers = {
			World = {
				Class [class World]
				Super = nil,
				InstanceMembers = {
					Actors [...]
					
					World.AddActor
					World.Run
				}
			}
			Game.Initialize
			Game.Run
			Game.DoRun
		}
	}
	InstanceMembers = {
		RPGGame.Initialize
		RPGGame.Run
		RPGGame.DoRun
	}
}
]]--
GameInstance = GameClass()

--[[
RPGGame:Run
	-Game.Run(self)
		World:Run
			RockActor:Run
			Player:Run
		*RPGame:DoRun
		
]]--
GameInstance:Run()



Reflect.DebugPrintClass(Actor)