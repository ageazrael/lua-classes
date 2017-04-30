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

```
```

