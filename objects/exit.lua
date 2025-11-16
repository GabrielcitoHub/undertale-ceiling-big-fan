return function(decay) local self = {}
    self.decay = decay or 3
    self.timer = 0
    function self:update(dt)
        if ISDOWN "EXIT" then
            self.timer = self.timer + self.decay * dt
        else
            if self.timer > 0 then
                self.timer = self.timer - self.decay * dt
            end
        end
        if self.timer > 3.1 then
            love.event.quit()
        end
    end
    function self:draw()
        local dots
        if self.timer < 0.5 then
            dots = ""
        elseif self.timer < 1 then
            dots = "."
        elseif self.timer < 2 then
            dots = ".."
        else
            dots = "..."
        end
        love.graphics.setColor(1,1,1,1/(3/self.timer))
        love.graphics.print("Exiting"..dots)
        love.graphics.setColor(1,1,1,1)
    end
return self end