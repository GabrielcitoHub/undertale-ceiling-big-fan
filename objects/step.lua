return function(target)
---@class Step
    local self = {}
    self.speed = 10
    self.target = target or 10
    self.step = false
    self.steptime = 0

    -- *Override* Called when a step happens
	function self:stepped()
	end

    function self:update(dt)
        self.steptime = self.steptime + dt * self.speed  -- "speed" factor

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
