local self = {}

---@param soul Soul
---@param state BattleState
function self:onclick(soul, state)
    PLAYSOUND "snd_heal_c.wav"
    soul.hp = soul.maxhp
    self.soul = soul
    self.state = state
end

function self:consume()
    self.enabled = false

    return false
end

function self:step()
    local soul = self.soul
    local state = self.state:getState()
    if state == "menu" then
        if soul.hp > 1 then
            soul:damage(1, 0)
        end
    end
end

return self