-- PLATFORM = "Wii"
-- PLATFORM = "Android"
local controlleftalt
local controlrightalt

love.wiimote = love.wiimote or nil

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
local pressed = Game.pressed
for key, value in pairs(CONTROLS) do
	pressed[key] = false
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