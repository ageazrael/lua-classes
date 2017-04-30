require "Classes"

UnitTest = class("UnitTest")
function UnitTest:Initialize()
	self.Succeed = true
	self.Messages = {}
end
function UnitTest:DoRun()
end
function UnitTest:Failed(Message)
	table.insert(self.Messages, debug.traceback(Message))
	self.Succeed = false
end

function UnitTest:Equal(A, B)
	if A ~= B then
		self:Failed(tostring(A).." not equal "..tostring(B))
	end
end

function UnitTest:NotEqual(A, B)
	if A == B then
		self:Failed(tostring(A).." equal "..tostring(B))
	end
end


StaticMemberError = class("StaticMemberError", UnitTest)
function StaticMemberError:DoRun()
	Sim = class("Sim")
	Sim.TB = {Value = 100}
	
	TestClass = class("TestClass")
	TestClass.SimInstance = Sim()
	
	TInstance1 = TestClass()
	TInstance2 = TestClass()
	
	TInstance1.SimInstance.TB.Value = 200
	
	-- 这很讨厌呢, 增加深度拷贝可以解决这个问题，但是会让类对象的初始化变的更加缓慢。
	-- 	而且很难控制类初始化复杂度，有别的方法代替他们
	--  定义类的时候定义的变量是静态变量啊
	self:Equal(TInstance1.SimInstance.Value, TInstance2.SimInstance.Value)
	self:Equal(Sim.Value, TInstance1.Static.SimInstance.Value)
end


function DoUnitTest()
	for UnitTestClass in Reflect.EnumSubclassOf(UnitTest) do
		local UnitTestInstance = UnitTestClass()
		
		UnitTestInstance:DoRun()
		
		if not UnitTestInstance.Succeed then
			print(UnitTestInstance.Messages)
			for _,Message in pairs(UnitTestInstance.Messages) do
				print(Message)
			end
		end
	end
end
DoUnitTest()