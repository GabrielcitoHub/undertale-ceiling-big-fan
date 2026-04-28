local function multiply(tbl, val)
	local ret = {}

	for key, value in pairs(tbl) do
		ret[key] = value * val
	end

	return ret
end

return function(x, y, maxhp, iframes) local self = {}
	self.image = IMAGE "soul"
	self.x = math.floor(x or 0)
	self.y = math.floor(y or 0)
	self.maxiframes = iframes or 60
	self.iframes = 0
	self.maxhp = maxhp or 20
	self.hp = self.maxhp
	self.width = 8
	self.height = 8
	self.color = {1, 0, 0}
	self.displayColor = nil
	self.deathtimer = 0
	self.love = 1
	self.name = "LOVE2D"
	self.at = 10
	self.df = 10
	self.fleetimer = 0
	self.speed = 2
	self.shards = {}
	self.active = true
	self.locked = false
	self.can_gameover = true
	self.can_flee = true

	-- *Override* Gets the soul color
	function self:getColor()
		return self.color or self.displayColor
	end

	-- *Override* Gets the soul display color
	function self:getDisplayColor()
		return self.displayColor or self.color
	end

	function self:setlove(val)
		self.love = val
		self:calcstats()
		self.hp = self.maxhp
	end

	function self:increaselove()
		self.love = self.love + 1
		self:calcstats()
	end

	function self:takedamage(bullet)
		if not (
			self.x - self.width / 2 > bullet.x + bullet.width / 2
			or
			self.x + self.width / 2 < bullet.x - bullet.width / 2
			or
			self.y - self.height / 2 > bullet.y + bullet.height / 2
			or
			self.y + self.height / 2 < bullet.y - bullet.height / 2
		) and self.iframes == 0 then
			local hp = self.hp
			local damage = (bullet.damage or 4)

			if damage < hp then
				self.hp = self.hp - damage
			else
				self.hp = 0
			end

			self.iframes = bullet.iframes or self.maxiframes
			PLAYSOUND "snd_hurt1.wav"

			return true
		end
	end

	function self:calcstats()
		self.maxhp = 16 + self.love*4

		if self.love == 20 then
			self.maxhp = 99
		end

		self.at = 8 + 2 * self.love
		self.df = 10 + math.floor((self.love - 1) / 4)
	end

	function self:deathsequence(dt)
		local old_deathTimer = self.deathtimer
		self.deathtimer = self.deathtimer + (1 * 60) * dt

		if old_deathTimer < 5 and self.deathtimer >= 5 and self.can_gameover then
			love.audio.stop()
		end

		if old_deathTimer < 30 and self.deathtimer >= 30 then
			PLAYSOUND "snd_break1.wav"
		end

		if old_deathTimer < 120 and self.deathtimer >= 120 then
			PLAYSOUND "snd_break2.wav"
			for i = 1, 6 do
				self.shards[#self.shards+1] = {
					x = self.x - 4,
					y = self.y - 4,
					xv = (math.random()-0.5) * 8,
					yv = math.floor(math.random() * 9) - 6
				}
			end
		end

		for index, shard in ipairs(self.shards) do
			shard.x = shard.x + shard.xv
			shard.y = shard.y + shard.yv
			shard.yv = shard.yv + 0.1
		end

		if old_deathTimer < 210 and self.deathtimer >= 210 and self.can_gameover then
			SETSCENE(require "assets.scenes.game_over" (self))
		end

		if old_deathTimer < 1200 and self.deathtimer >= 1200 then
			self.unloaded = true
		end
	end

	function self:updateDeath(dt)
		if self.hp <= 0 then
			self:deathsequence(dt)

			return
		end
	end

	function self:updateFleeing()
		if self.fleetimer > 0 then
			self.fleetimer = self.fleetimer + 1
			if self.fleetimer > 90 and self.can_flee then
				POPSCENE()
			end
			
			return
		end
	end

	function self:updateMovement()
		local speed = self.speed
		if ISDOWN "CANCEL" then
			speed = speed/2
		end

		if ISDOWN "LEFT" then
			self.x = self.x - speed
		end

		if ISDOWN "RIGHT" then
			self.x = self.x + speed
		end

		if ISDOWN "UP" then
			self.y = self.y - speed
		end

		if ISDOWN "DOWN" then
			self.y = self.y + speed
		end
	end

	function self:updateIFrames()
		if self.iframes > 0 then
			self.iframes = self.iframes - 1
		end
	end

	function self:updateImage()
		if self.hp > 0 then
			local image
			if self.fleetimer > 0 then
				if self.fleetimer%10 < 5 then
					image = IMAGE "soul_flee_1"
				else
					image = IMAGE "soul_flee_2"
				end
			else
				if love.system.hasBackgroundMusic() then
					image = IMAGE "soul_headphones"
				else
					image = IMAGE "soul"
				end
			end

			self.image = image
		else
			local image
			if self.deathtimer < 30 then
				image = IMAGE "soul"
			elseif self.deathtimer < 120 then
				image = IMAGE "soulbreak"
			else
				for index, shard in ipairs(self.shards) do
					shard.image = IMAGE ("soul_shard"..(math.floor(index/2 + self.deathtimer / 10))%3)
				end
			end

			self.image = image
		end
	end

	function self:update(dt)
		self:updateDeath(dt)
		self:updateImage()
		if self.unloaded then return end

		self:updateFleeing()
		self:updateIFrames()

		if self.active then
			self:updateMovement()
		end
	end

	function self:flee()
		self.fleetimer = 1
		PLAYSOUND "snd_escaped.wav"
	end

	function self:draw()
		if self.unloaded then return end
		if self.hp > 0 then
			love.graphics.setColor(self:getDisplayColor())

			if self.iframes % 10 <= 5 and self.iframes > 0 then
				love.graphics.setColor(multiply(self.color, 0.5))
			end

			love.graphics.draw(self.image, self.x - self.image:getWidth() / 2 - self.fleetimer * 1.5, self.y - self.image:getHeight() / 2)
			love.graphics.setColor(1, 1, 1)
		else
			love.graphics.setColor(self:getColor())
			
			if self.deathtimer < 30 then
				love.graphics.draw(self.image, self.x - 8, self.y - 8)
			elseif self.deathtimer < 120 then
				love.graphics.draw(self.image, self.x - 10, self.y - 8)
			else
				for index, shard in ipairs(self.shards) do
					-- print("This code runs!")
					-- print(tostring(shard.image))
					love.graphics.draw(
						shard.image,
						shard.x,
						shard.y
					)
				end
			end

			love.graphics.setColor(1, 1, 1)
		end
	end
return self end