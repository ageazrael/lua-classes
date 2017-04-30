--[[
	API
		Reflect.Classes
			- 所有类对象
		Reflect.RootClasses
			- 无父类的类
		Reflect.GetClass(inName)
			- 通过类名获取类对象
		Reflect.EnumSubclassOf(inClassObject)
			-- 遍历所有子类
			
		class(inName, inSuperClass)
			-- 创建一个新的类
			
		ClassObject.Name [string]
			-- 类名称
		ClassObject.Super [ClassObject]
			-- 父类对象
		ClassObject.Static [table] 
			-- 用于放置类系统内部函数[IsSubclassOf, Allocate, ...]
		ClassObject.Members [table]
			{
				[ThisClassMember], [ThisClassMember], [SuperClassMember]...
			}
		ClassObject.DeclaredMembers [table]
			{
				[ThisClassMember], [ThisClassMember], ...
			}
		ClassObject.Subclasses [table __mode='k']
			-- 继承自该类的子类
		ClassObject:IsSubclassOf(self, other)
		ClassObject:__call(...)
			-- 创建一个类实例，并调用Initialize
		ClassObject:OnSubclassed(inSubclass)
			-- 该类产生了一个新的子类
		ClassObject:Allocate(self)
			-- 创建一个新的类实例，但不调用Initialize
		ClassObject:Deattch(self)
			-- 移除掉该类  【实验】
		
		InstanceObject.Class
			-- 对象类型
		InstanceObject:Initialize(...)
			-- 对象初始化
		InstanceObject:IsInstanceOf(inClassObject)
			-- 对象是否从该类继承

]]--

--[[
	Reflect
]]--
Reflect = {
	Classes 	= {},
	RootClasses = {}
}
function Reflect.GetClass(inName)
	return Reflect.Classes[inName]
end
function Reflect.EnumSubclassOf(inClassObject)
	if nil == inClassObject or nil == inClassObject.Static then
		return nil
	end

	return coroutine.wrap(function()
		for Subclass in pairs(inClassObject.Subclasses) do
			for SubclassLeaf in Reflect.EnumSubclassOf(Subclass) do
				coroutine.yield(SubclassLeaf)
			end
			coroutine.yield(Subclass)
		end
	end)
end
function Reflect.DebugPrint(inClassObject)
	if nil == inClassObject or nil == inClassObject.Static then
		return
	end
	
	print(inClassObject)
	for key, value in pairs(inClassObject.Members) do
		if type(value) ~= 'function' and type(value) ~= 'table' then
			print('    '..key.."="..tostring(value).."("..type(value)..")")
		end
		
		if type(value) == 'table' and value.Class ~= nil then
			print('    '..tostring(key).."=".."("..tostring(value.Class)..")")
		end
	end
	
	for Subclass in Reflect.EnumSubclassOf(inClassObject) do
		print('  Subclass '..tostring(Subclass))
	end
end

--[[
	class
]]--
function class(inName, inSuperClass)
	assert(type(inName) == 'string', "A name (string) is needed for the new class");
	
	local function ReflectRegister(inClassObject)
		if nil == inClassObject or nil == inClassObject.Static then
			return
		end
		
		Reflect.Classes[inClassObject.Name] = inClassObject
		if nil == inClassObject.Super then
			Reflect.RootClasses[inClassObject.Name] = inClassObject
		end
	end
	local function ReflectUnregister(inClassObject)
		if nil == inClassObject or nil == inClassObject.Static then
			return
		end
		
		Reflect.Classes[inClassObject.Name] 	= nil
		Reflect.RootClasses[inClassObject.Name] = nil
	end
	
	local function CreateIndexWrapper(inClassObject, inMember)
		if inMember == nil then
			return inClassObject.Members
		else
			return function(self, inName)
				local Member = inClassObject.Members[inName]
				if Member ~= nil then
					return Member
				elseif type(inMember) == "function" then
					return (f(self, inName))
				else
					return inMember[inName]
				end
			end
		end
	end
	local function PropagateInstanceMethod(inClassObject, inName, inMember)
		inMember = name == "__index" and CreateIndexWrapper(inClassObject, inMember) or inMember
		
		print("Update "..inClassObject.Name.." Member:"..inName)
		inClassObject.Members[inName] = inMember

		for SubClass in pairs(inClassObject.Subclasses) do
			if rawget(SubClass.DeclaredMembers, inName) == nil then
				PropagateInstanceMethod(SubClass, inName, inMember)
			end
		end
	end
	local function DeclareInstanceMethod(inClassObject, inName, inMember)
		print(inClassObject.Name.." DescaredMember:"..inName)
		inClassObject.DeclaredMembers[inName] = inMember

		if inMember == nil and inClassObject.Super then
			inMember = inClassObject.Super.Members[inName]
		end

		PropagateInstanceMethod(inClassObject, inName, inMember)
	end
	function InitializeClassMetatable(inClassObject)
		setmetatable(inClassObject, {
			__index 	= inClassObject.Static,
			__newindex 	= DeclareInstanceMethod,
			__call 		= function(self, ...)
				local instance = self:Allocate()
				instance:Initialize(...)
				return instance
			end,
			
			__tostring  = function(self)
				return "class: "..self.Name
			end
		})
	end

	local function InitializeClassStaticMethod(inClassObject)
		
		inClassObject.Static.OnSubclassed = function(self, other)
			
		end
		inClassObject.Static.Allocate     = function(self)
			local instance = setmetatable({Class = self}, self.Members)
			instance.__tostring = function(self)
				return "instance of "..tostring(self.Class)
			end
			return instance
		end
		inClassObject.Static.IsSubclassOf = function(self, other)
			return type(self) == 'table' and type(other) == 'table' and
				(self == other or (nil ~= self.Super and self.Super:IsSubclassOf(other)))
		end
		inClassObject.Static.Deattch	  = function(self)
			setmetatable(self, {})
			ReflectUnregister(self)
		end
	end
	local function InitializeClassMethod(inClassObject)
		inClassObject.Initialize   		= function(self, ...) end
		inClassObject.IsInstanceOf 		= function(self, other)
			return type(other) == 'table' and (self.Class == other or self.Class:IsSubclassOf(other))
		end
	end
	local function CreateClass(inName, inSuperClass)
		local MembersTable = {}
		MembersTable.__index = MembersTable

		-- Members: 计算继承、覆盖后该类包含的成员
		-- DeclaredMembers: 该类字定的成员
		local ClassObject = {
			Name			= inName,	Super		= inSuperClass,
			Static			= {},		Members		= MembersTable,
			DeclaredMembers	= {},		Subclasses	= setmetatable({}, {__mode='k'})
		}

		if inSuperClass then
			setmetatable(ClassObject.Static, { 
				__index = function(_,k)
					print("__index:"..tostring(k))
					print( debug.traceback() )
					return rawget(MembersTable,k) or inSuperClass.Static[k]
			end})
		else
			setmetatable(ClassObject.Static, { 
				__index = function(_,k)
				 	print("__index: none parent "..tostring(k))
					print( debug.traceback() )
					return rawget(MembersTable,k)
			end})
		end
		InitializeClassMetatable(ClassObject)
		InitializeClassStaticMethod(ClassObject)
		
		ReflectRegister(ClassObject)
		
		return ClassObject
	end
	function CreateNoneclass(inName)
		assert(type(inName) == "string", "You must provide a name(string) for your class")
		
		local Noneclass = CreateClass(inName)
		
		InitializeClassMethod(Noneclass)
		
		return Noneclass
	end

	function CreateSubclass(inName, inSuperClass)
		assert(type(inName) == "string", "You must provide a name(string) for your class")

		local Subclass = CreateClass(inName, inSuperClass)

		for MemberName, Member in pairs(inSuperClass.Members) do
			print(inName..".AddMember "..inSuperClass.Name.."."..MemberName)
			PropagateInstanceMethod(Subclass, MemberName, Member)
		end
		Subclass.Initialize = function(inInstance, ...)
			inSuperClass.Initialize(inInstance, ...)
		end

		inSuperClass.Subclasses[Subclass] = true
		inSuperClass:OnSubclassed(Subclass)

		return Subclass
	end
	
	if nil == inSuperClass then
		return CreateNoneclass(inName)
	else
		return CreateSubclass(inName, inSuperClass)
	end
	
end



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
	if not inActor:IsSubclassOf(Actor) then
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
end


StaticMeshActor = class("StaticMeshActor", Actor)
function StaticMeshActor:Initialize()
	---StaticMeshActor.Super:Initialize()
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
function RockActor:Run()
	print("RockActor:Run")
end

Player = class("Player", SkeletonMeshActor)
function Player:Run()
	print("Player:Run")
end

RPGGame = class("RPGGame", Game)
function RPGGame:Initialize()
	--RPGGame.Super:Initialize()
	print("RPGGame:Initialize")
	
	self.World:AddActor(RockActor())
	self.World:AddActor(Player())
end

GameClass = Reflect.GetClass("RPGGame")
GameInstance = GameClass()
GameInstance:Run()


--Reflect.DebugPrint(Actor)