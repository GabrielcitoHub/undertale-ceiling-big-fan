return function(soul) local self = {}
    self.souls = {soul}
    self.soul = self.souls[1]
	self.name = "Chara"

	if self.soul then
		self.name = self.soul.name
	end

    self.fade = 0
    self.timer = 0
    self.fadeout = false
    self.dialogue = require "objects.dialogue" (nil, "fnt_default_big", 160, 322, "snd_txtasg.wav")
	self.dialogue.speed = 4
	self.dialogue.charwidthoverride = 20
    self.music = MUSIC "determination.mp3"
    self.music:play()
    self.music:setLooping(true)
	self.message = 0

    function self:update(dt)
        local old_t = self.timer
        self.timer = self.timer + (1 * 60) * dt

        if self.fadeout then
            if self.fade > 0 then
                self.fade = self.fade - (0.015 * 60) * dt
                self.music:setVolume(self.fade)
            else
                RELOAD()
            end
        else
            if self.fade < 1 then
                self.fade = self.fade + 0.01
            else
                self.fade = 1
            end
        end

        if old_t < 60 and self.timer >= 60 then
			self.message = 1
            self.dialogue:settext("You cannot give\nup just yet...", true)
        end

        if ISPRESSED "SELECT" and self.dialogue.text == self.dialogue.targettext then
			if self.message == 1 then
				self.message = 2
				self.dialogue:settext(self.name.."!\nStay determined!", true)
			elseif self.message == 2 then
				self.message = 0
				self.dialogue:settext("")
				self.fadeout = true
            	self.timer = 999
			end
        end

        for i, soul in ipairs(self.souls) do
            if soul then
                soul:update(dt)
            end
        end

        self.dialogue:update()
    end

    function self:draw()
        love.graphics.setColor(self.fade, self.fade, self.fade)
        love.graphics.draw(IMAGE "game_over", 320 - IMAGE "game_over":getWidth() / 2, 50)
        love.graphics.setColor(1, 1, 1)

        for i, soul in ipairs(self.souls) do
            if soul then
                soul:draw()
            end
        end

        self.dialogue:draw()
    end

	function self:debugdraw()
		love.graphics.setFont(FONT "fnt_default")
		love.graphics.print("Message "..self.message.."\nTimer: "..self.timer.."\nFadeout: "..tostring(self.fadeout))
	end
return self end