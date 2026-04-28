local scenestack = Game.scenestack
local pressed = Game.pressed

function ReloadScene(scene)
	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end

	if scene.load then
		scene:load()
	end
end

function SETSCENE(scene)
	ReloadScene(scene)
	scenestack = {scene}
	scene:update(DT)
    
    Game.scenestack = scenestack
end

function PUSHSCENE(scene)
	ReloadScene(scene)
	scenestack[#scenestack+1] = scene
	scene:update(DT)

    Game.scenestack = scenestack
end

function POPSCENE()
	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end

	scenestack[#scenestack] = nil

	if #scenestack == 0 then
		RELOAD(false)
	end

    Game.scenestack = scenestack
end