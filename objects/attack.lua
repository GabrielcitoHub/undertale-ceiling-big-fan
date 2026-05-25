---@param w number
---@param h number
---@param img love.Image
---@param cre function|nil
---@param upd function|nil
---@param dra function|nil
return function(w, h, img, cre, upd, dra)
---@class AttackConstructor
    return function()
---@class Attack
        local self = {}
        self.x = 0
        self.y = 0
        self.vx = 0
        self.vy = 0
        self.xv = 0
        self.yv = 0
        self.width = w or 16
        self.height = h or 16
        self.image = img or IMAGE "attack_default"
        self.damage = 0
        self.iframes = nil
        self.disabled = false
        self.no_hit_destroy = false
---@param self Attack
---@param battle BattleState
        self.update = upd or function(self, battle, dt)
            self.x = self.x + self.xv
            self.y = self.y + self.yv
            
            if self.x < battle.box.x + self.width / 2 and self.xv < 0 then
                self.x = battle.box.x + self.width / 2
                self.xv = 2
            end

            if self.x > battle.box.x + battle.box.width - self.width / 2 and self.xv > 0 then
                self.x = battle.box.x + battle.box.width - self.width / 2
                self.xv = -2
            end

            if self.y < battle.box.y + self.height / 2 and self.yv < 0 then
                self.y = battle.box.y + self.height / 2
                self.yv = 3
            end

            if self.y > battle.box.y + battle.box.height - self.height / 2 and self.yv > 0 then
                self.y = battle.box.y + battle.box.height - self.height / 2
                self.yv = -3
            end
        end

---@param self Attack
---@param battle BattleState
        self.draw = dra or function(self, battle)
            love.graphics.draw(self.image, self.x - self.image:getWidth() / 2, self.y - self.image:getHeight() / 2)
        end

---@param self Attack
---@param battle BattleState
        self.spawned = cre or function(self, battle)
            self.xv = 2
            self.yv = 3
        end

        return self
    end
end