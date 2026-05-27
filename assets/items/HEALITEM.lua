local self = {}

---@param soul Soul
---@param state BattleState
function self:onclick(soul, state)
    PLAYSOUND "snd_heal_c.wav"
    soul.hp = math.min(soul.maxhp, soul.hp + 20)
    state:endturn({
        "* Tastes like debug code...",
        "* Some health was recovered."
    })

    return false
end

return self