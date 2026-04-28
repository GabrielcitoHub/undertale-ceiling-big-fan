Game = require "game"

VERSION = 1
PLATFORM = love.system.getOS()
BUTTONS = require "objects.button" ()
EXITLIB = require "objects.exit" ()


local titles = {"DELTARUNE", "NUT DEALER", "ULTRA NEED", "DUAL ENTER", "ELDER TUNA", "RENTAL DUE", "TUNDRA EEL", "UN-ALTERED"}
love.window.setTitle(titles[math.floor(love.math.random() * #titles + 1)])

love.graphics.setDefaultFilter("nearest", "nearest")

require "scripts.general"
require "scripts.input"
require "scripts.scenes"

local pressed = Game.pressed
local scenestack = Game.scenestack

local scale = 1
local translatex = 0
local translatey = 0

function MOUSEX()
	return math.floor(love.mouse.getX() / scale - translatex)
end

function MOUSEY()
	return math.floor(love.mouse.getY() / scale - translatey)
end

local programargs
local mounted

local function exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
		  	return true
	   	end
	end

	return ok, err
end

--- Check if a directory exists in this path
local function isdir(path)
	if not path then return end
	-- "/" works on both Unix and Windows
	return exists(path.."/")
end

local function copyall(from, to)
end

local function copytotemp(from, to)
	local file = io.open(from, "rb")
	local contents = file:read("*a")
	file:close()

	return love.filesystem.write(to, contents)
end

function LOADMOD(path)
	TIME = 0
	love.audio.stop()

	if type(path) == "boolean" then
		CLEARCACHE()
	end

	scenestack = {}

	if path ~= nil then
		if not isdir(path) then
			if mounted and path ~= true then
				love.filesystem.unmount(mounted)
			end
			if type(path) == "string" then
				love.filesystem.mount(path, "assets", false)
				mounted = path
			end
		else
		end
	end

	for key, value in pairs(package.loaded) do
		package.loaded[key] = nil
	end
end

function RELOAD(path)
	LOADMOD(path)
	love.load(programargs)
end

local loadfromarg = false
function love.load(args)
	love.filesystem.createDirectory("mods")
	love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "mods", true)

	local path = args[1]
	if path and not loadfromarg then
		print("Mod path provided")
		if isdir(path) then
			print("Mod is a folder, cant deal with yet, no zip library")
		elseif exists(path) then
			print("Mod is a file")
			loadfromarg = true
			copytotemp(path, "temp.zip")
		else
			print("Mod does not exist")
		end
	end

	if loadfromarg then
		LOADMOD("temp.zip")
	end

	programargs = args
	require "assets.main"
end

local paused = false

function love.update(dt)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]

	BUTTONS:update(dt)
	DT = dt

	local scalex = love.graphics.getWidth() / 640
	local scaley = love.graphics.getHeight() / 480
	scale = math.min(scalex, scaley)
	translatex = scalex / scale * 320 - 320
	translatey = scaley / scale * 240 - 240

	if paused then return end

	if #scenestack > 0 then
		scene:update(dt)
	end

	if ISPRESSED "EXTRA2" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end

	if ISPRESSED "EXTRA1" then
		DEBUG = not DEBUG
	end

	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end

	TIME = TIME + 1
	EXITLIB:update(dt)
end

function love.draw()
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]

	love.graphics.scale(scale)
	love.graphics.translate(translatex, translatey)
	love.graphics.setScissor(translatex * scale, translatey * scale, 640 * scale, 480 * scale)

	if #scenestack > 0 then
		scene:draw()
	end

	if DEBUG and scene.debugdraw then
		scene:debugdraw()
	end

	EXITLIB:draw()

	love.graphics.setScissor()

	BUTTONS:draw()

	love.graphics.origin()

	if paused then
		love.graphics.scale(2, 2)
		love.graphics.setFont(FONT "fnt_karma_big")
		love.graphics.setColor(0.25, 0, 0)
		love.graphics.print("PAUSED", 9, 9)
		love.graphics.setColor((math.sin(love.timer.getTime()*5)+1)/2, 0, 0)
		love.graphics.print("PAUSED", 6, 6)
		love.graphics.setColor(1, 1, 1)
	end
end

function love.focus()
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.focus then
		scene:focus()
	end
	print(#scenestack)
end

function love.keypressed(key)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.keypressed then
		scene:keypressed(key)
	end

	if key == "f2" then
		love.window.setFullscreen(false)

		local width, height, mode = love.window.getMode()

		mode.resizable = not mode.resizable
		love.window.updateMode(640, 480, mode)
	elseif key == "f8" then
		paused = not paused
	elseif key == "r" and love.keyboard.isDown("lctrl") and love.keyboard.isDown("lshift") then
		RELOAD(false)
	end
end

function love.keyreleased(key)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.keyreleased then
		scene:keyreleased(key)
	end
end

function love.mousepressed(mx, my, button)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.mousepressed then
		scene:mousepressed(mx, my, button)
	end
end

function love.mousemoved(mx, my, dx, dy)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.mousemoved then
		scene:mousemoved(mx, my, dx, dy)
	end
end

function love.mousereleased(mx, my, button)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.mousereleased then
		scene:mousereleased(mx, my, button)
	end
end

function love.textinput(t)
	local scenestack = Game.scenestack
	local scene = scenestack[#scenestack]
	if scene and scene.textinput then
		scene:textinput(t)
	end
end

function love.graphics.outline(obj, color, modx, mody, shrinkbox)
	local size = 1 / scale
	local shrink = shrinkbox or 0
	local col = {love.graphics.getColor()}

	love.graphics.setColor(color)

	if obj.width and obj.height then
		local offsetx = (modx or 0) * obj.width + shrink
		local offsety = (mody or 0) * obj.height + shrink
		love.graphics.rectangle("fill", obj.x + offsetx, obj.y + offsety, obj.width - shrink * 2, size)
		love.graphics.rectangle("fill", obj.x + offsetx, obj.y + offsety, size, obj.height - shrink * 2)
		love.graphics.rectangle("fill", obj.x + offsetx, obj.y + offsety + obj.height - size - shrink * 2, obj.width - shrink * 2, size)
		love.graphics.rectangle("fill", obj.x + offsetx + obj.width - size - shrink * 2, obj.y + offsety, size, obj.height - shrink * 2)
	else
		love.graphics.rectangle("fill", obj.x + (1 - size) / 2, obj.y - 10, size, 21)
		love.graphics.rectangle("fill", obj.x - 10, obj.y + (1 - size) / 2, 21, size)
	end

	love.graphics.rectangle("fill", obj.x-1, obj.y-1, 2, 2)

	if obj.xv or obj.yv then
		local xv = obj.xv or 0
		local yv = obj.yv or 0
		local invcol = color
		invcol[1] = 1 - invcol[1]
		invcol[2] = 1 - invcol[2]
		invcol[3] = 1 - invcol[3]
		love.graphics.setColor(invcol)
		love.graphics.setLineWidth(size)
		love.graphics.line(obj.x, obj.y, obj.x + xv * 3, obj.y + yv * 3)
	end

	love.graphics.setColor(col)
end

PLAYSOUND "mus_intronoise.ogg"