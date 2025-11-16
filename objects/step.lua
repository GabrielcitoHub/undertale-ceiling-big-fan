return function(target)
    local self = {}
    self.target = target or 10
    self.step = false
    self.steptime = 0

    function self:update(dt)
        self.steptime = self.steptime + dt * 10  -- "speed" factor

        if self.steptime > self.target then
            self.steptime = self.steptime - self.target
            self.step = true
            if self.stepped then
                self:stepped()
            end
            self.step = false
        end
    end

return self end
