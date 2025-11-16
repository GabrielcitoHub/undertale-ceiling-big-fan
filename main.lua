local controlleftalt
local controlrightalt
PLATFORM = love.system.getOS()
VERSION = 1
BUTTONS = require "objects.button" ()
EXITLIB = require "objects.exit" ()
--PLATFORM = "Wii"
--PLATFORM = "Android"

if PLATFORM == "Wii" then
	CONTROLS = {
		LEFT = "up",
		RIGHT = "down",
		UP = "right",
		DOWN = "left",
		SELECT = "2",
		CANCEL = "1",
		MENU = "home",
		EXIT = "home",
		EXTRA1 = "-",
		EXTRA2 = "+"
	}
elseif PLATFORM == "Android" then
	local startX = 30
	local startY = 50
	CONTROLS = {
		LEFT = BUTTONS:new("LEFT",startX,love.graphics:getHeight()-startY),
		RIGHT = BUTTONS:new("RIGHT",startX+70,love.graphics:getHeight()-startY),
		UP = BUTTONS:new("UP",startX+35,love.graphics:getHeight()-startY-20),
		DOWN = BUTTONS:new("DOWN",startX+35,love.graphics:getHeight()-startY+20),
		SELECT = BUTTONS:new("SELECT",love.graphics:getWidth()-startX-70,love.graphics:getHeight()-startY),
		CANCEL = BUTTONS:new("CANCEL",love.graphics:getWidth()-startX-35,love.graphics:getHeight()-startY),
		MENU = BUTTONS:new("MENU",love.graphics:getWidth()-startX,love.graphics:getHeight()-startY),
		EXIT = BUTTONS:new("EXIT",startX,startY),
		EXTRA1 = BUTTONS:new("EXTRA1",startX+40,startY),
		EXTRA2 = BUTTONS:new("EXTRA2",startX+80,startY)
	}
else
	controlleftalt = {
		SELECT = "return",
		CANCEL = "lshift",
		MENU = "lctrl"
	}
	controlrightalt = {
		SELECT = "kpenter",
		CANCEL = "rshift",
		MENU = "rctrl"
	}
	CONTROLS = {
		LEFT = "left",
		RIGHT = "right",
		UP = "up",
		DOWN = "down",
		SELECT = "z",
		CANCEL = "x",
		MENU = "c",
		EXIT = "escape",
		EXTRA1 = "f3",
		EXTRA2 = "f4"
	}
end
-- Sets the pressed keys to false
local pressed = {}
for key, value in pairs(CONTROLS) do
	pressed[key] = false
end

local titles = {"DELTARUNE", "NUT DEALER", "ULTRA NEED", "DUAL ENTER", "ELDER TUNA", "RENTAL DUE", "TUNDRA EEL", "UN-ALTERED"}
love.window.setTitle(titles[math.floor(love.math.random() * #titles + 1)])

love.graphics.setDefaultFilter("nearest", "nearest")

local images = {}
local imagesdata = {}
local fonts = {}
local sounds = {}
local music = {}

TIME = 0

DEBUG = false

DT = 0

function CLEARCACHE()
	images = {}
	imagesdata = {}
	fonts = {}
	sounds = {}
	music = {}
end

---@return love.Image
function ABSIMAGE(path)
	if images[path] == nil then
		xpcall(function()
			images[path] = love.graphics.newImage(path..".png")
			imagesdata[path] = love.image.newImageData(path..".png")
		end, function()
			images[path] = false
		end)
	end
	return images[path]
end

---@return love.Image
function IMAGE(path)
	return ABSIMAGE("assets/sprites/"..path)
end

---@return love.ImageData
function ABSIMAGEDATA(path)
	if imagesdata[path] == nil then
		xpcall(function()
			imagesdata[path] = love.image.newImageData(path..".png")
		end, function()
			imagesdata[path] = false
		end)
	end
	return imagesdata[path]
end

---@return love.ImageData
function IMAGEDATA(path)
	return ABSIMAGEDATA("assets/sprites/"..path)
end

---@return love.Font
function FONT(path)
	if not fonts[path] then
		local data = love.filesystem.read("string", "assets/sprites/"..path..".txt")
		fonts[path] = love.graphics.newImageFont("assets/sprites/"..path..".png", data, 1)
	end
	return fonts[path]
end

---@return love.Source
function SOUND(path)
	if not sounds[path] then
		sounds[path] = love.audio.newSource("assets/sounds/"..path, "static")
	end
	return sounds[path]
end

function PLAYSOUND(path)
	local sound = SOUND(path)
	sound:stop()
	sound:seek(0)
	sound:play()
end

function STOPSOUND(path)
	local sound = SOUND(path)
	sound:stop()
	sound:seek(0)
end

---@return love.Source
function MUSIC(path)
	if not music[path] then
		music[path] = love.audio.newSource("assets/music/"..path, "stream")
	end
	return music[path]
end

function CHECKALT(alt, id, wiimote)
	local down
	if PLATFORM == "Wii" then
		if alt and (alt[id] ~= nil and alt[id] ~= "") then
			down = wiimote:isDown(alt[id])
		end
	else
		if alt and (alt[id] ~= nil and alt[id] ~= "") then
			down = love.keyboard.isDown(alt[id])
		end
	end
	return down
end

function TRIGGERPLATFORMBUTTON(platform, id, control)
	if platform == "Wii" then
		if love.wiimote then
			local altl = CHECKALT(controlleftalt, id, control) if altl then return altl end
			local altr = CHECKALT(controlrightalt, id, control) if altr then return altr end
			return control:isDown(CONTROLS[id])
		else
			return false
		end
	elseif platform == "Android" then
		-- Not needed
	else
		local altl = CHECKALT(controlleftalt, id) if altl then return altl end
		local altr = CHECKALT(controlrightalt, id) if altr then return altr end
		return love.keyboard.isDown(CONTROLS[id])
	end
end

function ISDOWN(id,joystick)
	joystick = joystick or 1
	if PLATFORM == "Wii" then
		if love.wiimote then
			local wiimote = love.wiimote.getWiimote(joystick)
			return TRIGGERPLATFORMBUTTON(PLATFORM, id, wiimote)
		else
			return TRIGGERPLATFORMBUTTON(love.system.getOS(), id)
		end
	elseif PLATFORM == "Android" then
		local buttonID = CONTROLS[id].id
		return BUTTONS:isDown(buttonID)
	else
		return TRIGGERPLATFORMBUTTON(PLATFORM, id)
	end
end

function ISPRESSED(id, joystick)
	joystick = joystick or 1
	if PLATFORM == "Wii" then
		if love.wiimote then
			local wiimote = love.wiimote.getWiimote(joystick)
			return not pressed[id] and TRIGGERPLATFORMBUTTON(PLATFORM, id, wiimote)
		else
			return not pressed[id] and TRIGGERPLATFORMBUTTON(love.system.getOS(), id)
		end
	elseif PLATFORM == "Android" then
		local button = CONTROLS[id]
		local buttonID = button.id
		local isDown = BUTTONS:isDown(buttonID)
		-- Return true only on transition from not-pressed to pressed
		if isDown == true then
			if not pressed[id] then 
				button.presses = (button.presses or 0) + 1
			end
			return not pressed[id] and isDown
		end
		return false
	else
		return not pressed[id] and TRIGGERPLATFORMBUTTON(PLATFORM, id)
	end
end

function GETKEY(key, from)
	key = string.upper(key)
	local replacements = {
		["return"] = "enter",
		["lshift"] = "shift",
		["rshift"] = "shift",
		["lctrl"] = "ctrl",
		["rctrl"] = "ctrl",
		["escape"] = "esc"
	}
	local gotKey
	if PLATFORM == "Android" then
		if not from then
			gotKey = BUTTONS:getID(key)
		else
			return
		end
	else
		if not from then
			gotKey = CONTROLS[key]
		elseif from == 1 then
			if not controlleftalt then return end
			gotKey = controlleftalt[key]
		elseif from == 2 then
			if not controlrightalt then return end
			gotKey = controlrightalt[key]
		end
	end
	if gotKey ~= "" then
		return replacements[gotKey] or gotKey
	end
end

local scenestack = {}

function SETSCENE(scene)
	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end
	scenestack = {scene}
	scene:update(DT)
end

function PUSHSCENE(scene)
	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end
	scenestack[#scenestack+1] = scene
	scene:update(DT)
end

function POPSCENE()
	for key, value in pairs(pressed) do
		pressed[key] = ISDOWN(key)
	end
	scenestack[#scenestack] = nil
	if #scenestack == 0 then
		RELOAD(false)
	end
end

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
	BUTTONS:update(dt)
	DT = dt
	local scalex = love.graphics.getWidth() / 640
	local scaley = love.graphics.getHeight() / 480
	scale = math.min(scalex, scaley)
	translatex = scalex / scale * 320 - 320
	translatey = scaley / scale * 240 - 240
	if paused then return end
	if #scenestack > 0 then
		scenestack[#scenestack]:update(dt)
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
	love.graphics.scale(scale)
	love.graphics.translate(translatex, translatey)
	love.graphics.setScissor(translatex * scale, translatey * scale, 640 * scale, 480 * scale)
	if #scenestack > 0 then
		scenestack[#scenestack]:draw()
	end
	if DEBUG and scenestack[#scenestack].debugdraw then
		scenestack[#scenestack]:debugdraw()
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
	if scenestack[#scenestack].focus then
		scenestack[#scenestack]:focus()
	end
end

function love.keypressed(key)
	if key == "f2" then
		love.window.setFullscreen(false)
		local width, height, mode = love.window.getMode()
		mode.resizable = not mode.resizable
		love.window.updateMode(640, 480, mode)
	end
	if key == "f8" then
		paused = not paused
	end
	if key == "r" and love.keyboard.isDown("lctrl") and love.keyboard.isDown("lshift") then
		RELOAD(false)
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