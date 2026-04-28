return function(x, y, soul, sprite) local self = {}
    self.debug = require "objects.debug" ()
    self.sprite = sprite or "frisk"
    self.x = math.floor(x or 0)
	self.y = math.floor(y or 0)
    self.rotation = 0
    self.width = 20
	self.height = 30
    self.scale = 2
    self.controller = nil
    self.speed = 2.8
    self.walkspeed = self.speed
    self.runspeed = self.speed * 1.2
    self.soul = soul or require "objects.soul" (self.x, self.y)
    self.color = {1, 1, 1}
    self.canrun = false
    self.anim = require "objects.animations" ()
    self.animations = self.anim:getCharacterAnimations(self.sprite)
    self.animtrack = require "objects.animationtrack" (self.x, self.y, self.width, self.height, self.rotation, self.scale)
    self.debug:print(self.animtrack:play(self.animations["d"]))
    self.cutscene = false
    self.stopframe = 2
    function self:updatemovement(dt)
        -- movement speed handling
        if self.canrun then
            if ISDOWN "CANCEL" then
                self.speed = self.runspeed
            else
                self.speed = self.walkspeed
            end
        else
            self.speed = self.walkspeed
        end

        local speed = self.speed * self.scale * 30

        -- movement direction
        local dx, dy = 0, 0

        if ISDOWN "LEFT"  then dx = dx - 1 end
        if ISDOWN "RIGHT" then dx = dx + 1 end
        if ISDOWN "UP"    then dy = dy - 1 end
        if ISDOWN "DOWN"  then dy = dy + 1 end

        -- normalize diagonal movement
        if dx ~= 0 or dy ~= 0 then
            local len = math.sqrt(dx*dx + dy*dy)
            dx, dy = dx / len, dy / len
        end

        -- apply movement
        self.x = self.x + dx * speed * dt
        self.y = self.y + dy * speed * dt
    end
    function self:updateanimations()
        self.animspeed = self.speed / 6

        -- initialize tracking vars
        self._prevInput = self._prevInput or {up = false, down = false, left = false, right = false}
        self._lastHorizontal = self._lastHorizontal or "r" -- default facing

        -- current states
        local up = ISDOWN "UP"
        local down = ISDOWN "DOWN"
        local left = ISDOWN "LEFT"
        local right = ISDOWN "RIGHT"

        local upP = ISPRESSED "UP"
        local downP = ISPRESSED "DOWN"
        local leftP = ISPRESSED "LEFT"
        local rightP = ISPRESSED "RIGHT"

        -- update last horizontal when left/right is pressed
        if leftP then self._lastHorizontal = "l" end
        if rightP then self._lastHorizontal = "r" end

        -- 1) If a vertical key was just pressed, play vertical immediately (priority)
        if upP then
            self.animtrack:play(self.animations["u"], self.animspeed)
        elseif downP then
            self.animtrack:play(self.animations["d"], self.animspeed)
        else
            -- 2) If vertical is currently held (even if it wasn't just pressed), ensure vertical animation is playing.
            -- We only call play for vertical if it's not already playing to avoid restarting each frame.
            if up and not (self.animtrack.animation == self.animations["u"]) then
                self.animtrack:play(self.animations["u"], self.animspeed)
            elseif down and not (self.animtrack.animation == self.animations["d"]) then
                self.animtrack:play(self.animations["d"], self.animspeed)
            end
        end

        -- 3) Handle horizontal presses when vertical NOT held
        if (leftP or rightP) and not (up or down) then
            if leftP then
                self.animtrack:play(self.animations["l"], self.animspeed)
            elseif rightP then
                self.animtrack:play(self.animations["r"], self.animspeed)
            end
        end

        -- 4) Transition: vertical was held, now released — but horizontal is still held.
        -- Use prev state to detect the release moment (one-time).
        local prevUp = self._prevInput.up
        local prevDown = self._prevInput.down

        if (prevUp or prevDown) and not (up or down) and (left or right) then
            -- choose which horizontal to play:
            local which = nil
            if left then which = "l" elseif right then which = "r" end
            -- prefer lastHorizontal if that still matches a held key
            if self._lastHorizontal and ( (self._lastHorizontal == "l" and left) or (self._lastHorizontal == "r" and right) ) then
                which = self._lastHorizontal
            end
            if which then
                self.animtrack:play(self.animations[which], self.animspeed)
            end
        end

        -- 5) Stop if nothing is held
        if not (left or right or up or down) then
            self.animtrack:stop(self.stopframe)
        end

        -- save current inputs for next frame
        self._prevInput.up = up
        self._prevInput.down = down
        self._prevInput.left = left
        self._prevInput.right = right
    end
    function self:update(dt)
        self.soul.x = self.x + (self.width / 2) * self.scale
        self.soul.y = self.y + (self.height / 2) * self.scale
        if not self.cutscene then
            self:updatemovement(dt)
            self:updateanimations()
        end
        self.animtrack:update(dt)
        self.debug:update(dt)
    end
    function self:draw()
        love.graphics.setColor(self.color)
        self.animtrack:draw(self.x, self.y, self.width, self.height, self.rotation, self.scale)
        --self.debug:print(self.animtrack.animation)
        self.soul:draw()
        self.debug:draw()
    end
    function self:debugdraw()
        local sw = self.width*self.scale
        local sh = self.height*self.scale
        love.graphics.setColor(self.color)
        love.graphics.rectangle("line",self.x,self.y,self.rotation,sw,sh)
    end
return self end