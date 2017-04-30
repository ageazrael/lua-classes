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
function Reflect.DebugPrintClass(inClassObject)
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
	
	--[[
		Reflect
	]]--
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
	
	local function DeclareInstanceMethod(inClassObject, inName, inMember)
		--print(inClassObject.Name.." DescaredMember:"..inName)
		inClassObject.DeclaredMembers[inName] = inMember
		
		-- TODO: 是否允许覆盖类自己包含的函数呢？
		inClassObject.Static[inName] = inMember
	end
	
	local function DefaultInitialize(self, ...)
	end
	local function DefaultSubclassed(self, other)
	end
	
	local function ConstructInstance(inInstance, ...)
		if nil ~= inInstance.Super then
			ConstructInstance(inInstance.Super, ...)
		end
		if DefaultInitialize ~= inInstance.Initialize then
			inInstance:Initialize(...)
		end
		return inInstance
	end
	
	-- TODO: 针对对象深度拷贝
	local function DepthCopy(Value)
		return Value
	end
	
	local function CreateInstance(inClassObject)
		local InstanceSuper = nil
		if nil ~= inClassObject.Super then
			InstanceSuper = CreateInstance(inClassObject.Super)
		end
		
		local InstanceMembers 	= {}
		local instance = {
			Class			= inClassObject,
			Super   		= InstanceSuper,
			InstanceMembers = InstanceMembers
		}
		
		for MemberName, MemberValue in pairs(inClassObject.DeclaredMembers) do
			InstanceMembers[MemberName] = DepthCopy(MemberValue);
		end
		setmetatable(instance, {
			__index = function(_, key)
				local Value = rawget(InstanceMembers, key)
				if nil == Value and nil ~= InstanceSuper then
					return InstanceSuper[key]
				end
				return Value
			end,
			__newindex = function(_, key, value)
				InstanceMembers[key] = value
			end,
			__tostring = function(self)
				return "instance of "..tostring(inClassObject)
			end
		})
		return instance
	end
	
	
	local function InitializeClassMetatable(inClassObject)
		setmetatable(inClassObject, {
			__index 	= inClassObject.Static,
			__newindex 	= DeclareInstanceMethod,
			__call 		= function(self, ...)
				return ConstructInstance(self:Allocate(), ...)
			end,
			
			__tostring  = function(self)
				return "class: "..self.Name
			end
		})
	end
	local function InitializeClassStaticMethod(inClassObject)
		inClassObject.Static.OnSubclassed = DefaultSubclassed
		inClassObject.Static.Allocate     = function(self)
			return CreateInstance(self)
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

		InitializeClassMetatable(ClassObject)
		InitializeClassStaticMethod(ClassObject)
		
		ReflectRegister(ClassObject)
		
		return ClassObject
	end
	function CreateNoneclass(inName)
		assert(type(inName) == "string", "You must provide a name(string) for your class")
		
		local ClassObject = CreateClass(inName)
		ClassObject.Initialize   		= DefaultInitialize
		ClassObject.IsInstanceOf 		= function(self, other)
			return type(other) == 'table' and (self.Class == other or self.Class:IsSubclassOf(other))
		end
		return ClassObject
	end

	function CreateSubclass(inName, inSuperClass)
		assert(type(inName) == "string", "You must provide a name(string) for your class")

		local Subclass = CreateClass(inName, inSuperClass)

		Subclass.Initialize = DefaultInitialize

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

