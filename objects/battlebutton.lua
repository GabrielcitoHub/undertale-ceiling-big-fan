return function(x, y, col, highlightcol, spr, sprselected, onclick, sx, sy) local self = {}
    self.x = x
    self.y = y
    self.onclick = onclick or function() end
    self.col = col or {1, 0.5, 0.152941176}
    self.highlightcol = highlightcol or {1, 1, 0}
    self.image = IMAGE (spr or "fight_button")
    self.imageselected = IMAGE (sprselected or spr or "fight_button")
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.hover = false
    self.soulx = sx or 16
    self.souly = sy or (self.height / 2)

    function self:isOver(object)
        if not (
            self.x > object.x + object.width / 2
            or
            self.x + self.width < object.x - object.width / 2
            or
            self.y > object.y + object.height / 2
            or
            self.y + self.height < object.y - object.height / 2
        ) then
            return true
        else
            return false
        end
    end

    function self:update(battle)
        local soulsAmount = #battle.souls

        battle:queueSoulsAction(function(i, soul)
            -- print("TEST" .. i .. " / " .. soul.hp)
            if soul.hp > 0 and self:isOver(soul) then
                -- print("HOVER!")
                self.hover = true
            end

            if soulsAmount > 1 then
                if self.hover and ISPRESSED "SELECT" and not soul.queued then -- TO-DO: Replace "ISPRESSED "SELECT" with soul keybinds
                    PLAYSOUND "snd_select.wav"
                    for _, button in pairs(battle.buttons) do
                        button.hover = false
                    end

                    if self:isOver(soul) then
                        self:onclick()
                    end
                    
                    -- soul.queued = self.onclick
                end

                if soul.queued and ISPRESSED "CANCEL" then
                    soul.queued = nil
                end
            end
        end)

        -- Singleplayer interaction
        if (soulsAmount == 1 or #battle.aliveSouls <= 1) and self.hover and ISPRESSED "SELECT" then
            PLAYSOUND "snd_select.wav"
            self:onclick()
        end
    end

    function self:draw()
        if self.hover then
            love.graphics.setColor(self.highlightcol)
            love.graphics.draw(self.imageselected, self.x, self.y)
            self.hover = false
        else
            love.graphics.setColor(self.col)
            love.graphics.draw(self.image, self.x, self.y)
        end

        love.graphics.setColor(1, 1, 1)
    end
return self end