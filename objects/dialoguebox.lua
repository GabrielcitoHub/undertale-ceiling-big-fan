return function(x, y, w, h) local self = {}
	self.x = x or 250
	self.y = y or 250
	self.r = 0
	self.width = w or 140
	self.height = h or 140
    self.enabled = true
    self.outline = 5

    function self:draw()
		if not self.enabled or self.hidden then
			return
		end

		local image = self.image
		if image then
			love.graphics.setColor(1, 1, 1)
			local imgW, imgH = image:getWidth(), image:getHeight()
			love.graphics.draw(image, self.x, self.y, self.r, self.width / imgW, self.height / imgH)
			return
		end

		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.outline)
		love.graphics.rectangle("fill", self.x, self.y, self.outline, self.height)
		love.graphics.rectangle("fill", self.x, self.y + self.height - self.outline, self.width, self.outline)
		love.graphics.rectangle("fill", self.x + self.width - self.outline, self.y, self.outline, self.height)
	end
return self end