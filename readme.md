lua-classes
----------

在lua中实现面像对象概念，参考middleclass实现。

```lua
require "classes"

Game = class("Game")
function Game:Initialize()
end
function Game:Run()
    print("Game:Run")
end

RPGGame = class("RPGGame", Game)
function RPGGame:Initialize()
end

function RPGGame:Run()
    print("RPGGame:Run")
end


GameClass = Reflect.GetClass("RPGGame")
GameInstance = GameClass()
-- RPGGame:Initialize
--  Game:Initialize

GameInstance:Run()
-- RPGGame:Run

```

## 类静态变量
```lua
Game = class("Game")
Game.kRunThreadCount = 100
```
## 类成员变量
```lua
Game = class("Game")
function Game:Initialize()
    Game.RunTime = 0;
end
```

## 覆盖父类函数
```lua
Game = class("Game")
function Game:Run()
    self:OverrideFunction()
end
function Game:OverrideFunction()
    print("Game:OverrideFunction")
end

RPGGame = class("RPGGame", Game)
function RPGGame:OverrideFunction()
    print("RPGGame:OverrideFunction")
end

GameInstance = RPGGame()
GameInstance:Run()
-- RPGGame:OverrideFunction()
```
## 调用父类方法
```lua
Game = class("Game")
function Game:Run()
    print("Game:Run")
    self:OverrideFunction()
end
function Game:OverrideFunction()
    print("Game:OverrideFunction")
end

RPGGame = class("RPGGame", Game)
function RPGGame:Run()
    Game.Run(self)
    print("RPGGame:Run")
end
function RPGGame:OverrideFunction()
    print("RPGGame:OverrideFunction")
end

GameInstance = RPGGame()
GameInstance:Run()
-- Game:Run
-- RPGGame:OverrideFunction()
-- RPGGame:Run
```
