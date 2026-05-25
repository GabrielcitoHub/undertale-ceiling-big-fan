local self = {}

function self:onclick(soul, item, state)
    PLAYSOUND "snd_heal_c.wav"
    soul.hp = soul.maxhp
    self.soul = soul
    self.state = state
end

function self:consume(item)
    item.enabled = false

    return false
end

function self:step()
    local soul = self.soul
    local state = self.state
    if state == "menu" then
        if soul.hp > 0 then
            PLAYSOUND "snd_hurt1.wav"
            soul.hp = soul.hp - 1
        end
    end
end

return self