local self = {}

function self:onclick(soul, item, state)
    PLAYSOUND "snd_hurt1.wav"
    soul.hp = soul.hp - 1

    return false
end

function self:consume()
    return false
end

return self