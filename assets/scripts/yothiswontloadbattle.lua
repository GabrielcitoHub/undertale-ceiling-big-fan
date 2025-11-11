-- example battle with more than 3 opponents
return function(self)
    local testbullet = self:makebullet {
        spawned = function(self)
            self.damage = 1
        end,
        update = function(self, battle)
            self.y = self.y + 2
        end,
        width = 8,
        height = 8,
    }
    function self:onenemyturn(turncount)
        self:startattack(function()
			-- for each remaining opponent, given they arent dead or spared, spawn 10 bullets
			for i = 1, 10 do
				for index, value in ipairs(self.opponents) do
					if not (self.opponents[index].killed or self.opponents[index].spared) then
						local x = self.box.x + math.random() * self.box.width
						self:queuespawn(testbullet, x, self.box.y - 150)
					end
				end
				self:wait(0.5)
			end
			-- queue the end of the attack
			self:queue(function()
				self:endattack("* Dummies stand everywhere....")
			end)
        end)
    end
	-- starting dialogue
    -- definde the (holyy) dummies
    self.dialogue:settext("* WHAT THE HELL.")
    for i = 1,1000 do
        self:makeopponent("Dummy " .. i, "dummy", 5, {
            canspare = love.math.random(2) == 1,
            fleechance = 1,
        }):makeacts("%\n* A cotton heart and a button eye\n* You are the apple of my eye")
    end
end