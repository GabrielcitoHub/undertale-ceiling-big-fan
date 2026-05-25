local images = {}
local imagesdata = {}
local fonts = {}
local sounds = {}
local music = {}

function CLEARCACHE()
	images = {}
	imagesdata = {}
	fonts = {}
	sounds = {}
	music = {}
end

---@param path string
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

---@param path string
---@return love.Image
function IMAGE(path)
	return ABSIMAGE("assets/sprites/"..path)
end

---@param path string
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

---@param path string
---@return love.ImageData
function IMAGEDATA(path)
	return ABSIMAGEDATA("assets/sprites/"..path)
end

---@param path string
---@return love.Font
function FONT(path)
	if not fonts[path] then
		local data = love.filesystem.read("string", "assets/sprites/fonts/"..path..".txt")
		fonts[path] = love.graphics.newImageFont("assets/sprites/fonts/"..path..".png", data, 1)
	end

	return fonts[path]
end

---@param path string
---@return love.Source
function SOUND(path)
	if not sounds[path] then
		sounds[path] = love.audio.newSource("assets/sounds/"..path, "static")
	end

	return sounds[path]
end

---@param path string|love.Source
function PLAYSOUND(path)
	local sound
	if type(path) == "string" then
		sound = SOUND(path)
	else
		sound = path
	end

	sound:stop()
	sound:seek(0)
	sound:play()
end

---@param path string|love.Source
function STOPSOUND(path)
	local sound
	if type(path) == "string" then
		sound = SOUND(path)
	else
		sound = path
	end
	sound:stop()
	sound:seek(0)
end

---@param path string
---@return love.Source
function MUSIC(path)
	if not music[path] then
		music[path] = love.audio.newSource("assets/music/"..path, "stream")
	end

	return music[path]
end

---@param path string|love.Source
function PLAYMUSIC(path)
	local music
	if type(path) == "string" then
		music = MUSIC(path)
	else
		music = path
	end

	music:stop()
	music:seek(0)
	music:play()
	music:setLooping(true)
end

---@param path string|love.Source
function STOPMUSIC(path)
	local music
	if type(path) == "string" then
		music = MUSIC(path)
	else
		music = path
	end
	music:stop()
	music:seek(0)
end