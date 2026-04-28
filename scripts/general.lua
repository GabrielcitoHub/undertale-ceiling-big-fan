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