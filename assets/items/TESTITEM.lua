local self = {}

---@param soul Soul
---@param state BattleState
function self:onclick(soul, state)
    PLAYSOUND "snd_hurt1.wav"
    soul:damage(1, 0)

    return false
end

function self:consume()
    return false
end

return self