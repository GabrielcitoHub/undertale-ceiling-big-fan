-- PLATFORM = "Wii"
-- PLATFORM = "Android"
local controlleftalt
local controlrightalt

love.wiimote = love.wiimote or {
	---@param joystick number
	getWiimote = function(joystick)
		return
	end,
}

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
	local startY = 20
	local offsetY = 60
	local gamepadOffsetY = 55
	CONTROLS = {
		LEFT = BUTTONS:new("LEFT",startX,love.graphics:getHeight()-startY-offsetY-gamepadOffsetY),
		RIGHT = BUTTONS:new("RIGHT",startX+110,love.graphics:getHeight()-startY-offsetY-gamepadOffsetY),
		UP = BUTTONS:new("UP",startX+110/2,love.graphics:getHeight()-startY-offsetY-gamepadOffsetY-40),
		DOWN = BUTTONS:new("DOWN",startX+110/2,love.graphics:getHeight()-startY-offsetY-gamepadOffsetY+40),
		SELECT = BUTTONS:new("SELECT",love.graphics:getWidth()-startX-160,love.graphics:getHeight()-startY-offsetY),
		CANCEL = BUTTONS:new("CANCEL",love.graphics:getWidth()-startX-80,love.graphics:getHeight()-startY-offsetY),
		MENU = BUTTONS:new("MENU",love.graphics:getWidth()-startX,love.graphics:getHeight()-startY-offsetY),
		EXIT = BUTTONS:new("EXIT",startX,startY),
		EXTRA1 = BUTTONS:new("EXTRA1",startX+80,startY),
		EXTRA2 = BUTTONS:new("EXTRA2",startX+160,startY)
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

---@param alt table
---@param id string
---@return boolean
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

---@param platform string
---@param id string
---@param control number|BUTTON|nil
---@return boolean|nil
function TRIGGERPLATFORMBUTTON(platform, id, control)
	if platform == "Wii" then
		if love.wiimote and type(control) == "table" and control.isDown then
			local altl = CHECKALT(controlleftalt, id, control) if altl then return altl end
			local altr = CHECKALT(controlrightalt, id, control) if altr then return altr end

			return control:isDown()
		elseif type(control) == "boolean" then
			return control
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

---@param id string
---@param joystick number|nil
---@return boolean|nil
function ISDOWN(id,joystick)
	joystick = joystick or 1
	if PLATFORM == "Wii" then
		local wiimote = love.wiimote.getWiimote(joystick)
		if wiimote then
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

---@param id string
---@param joystick number|nil
---@return boolean|nil
function ISPRESSED(id, joystick)
	joystick = joystick or 1
	if PLATFORM == "Wii" then
		local wiimote = love.wiimote.getWiimote(joystick)
		if wiimote then
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

---@param id string
---@param from number|nil
---@return string|nil
function GETKEY(id, from)
	id = string.upper(id)
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
			gotKey = BUTTONS:getID(id)
		else
			return
		end
	else
		if not from then
			gotKey = CONTROLS[id]
		elseif from == 1 then
			if not controlleftalt then return end
			gotKey = controlleftalt[id]
		elseif from == 2 then
			if not controlrightalt then return end
			gotKey = controlrightalt[id]
		end
	end

	if gotKey ~= "" then
		return replacements[gotKey] or gotKey
	end
end