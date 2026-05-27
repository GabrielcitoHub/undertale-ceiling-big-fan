local self = {}

self.consumeitem = true
function self:onclick(soul, state)
    PLAYSOUND "snd_laz.wav"

    local opponents = state.opponents
    for i,opp in pairs(opponents) do
        if opp.hp < 10 then
            opp.hp = opp.hp - 10
            self.consumeitem = true
        else
            opp.hp = opp.hp - opp.maxhp / 10
            self.consumeitem = false
        end
    end

    state:postattack()
end

function self:consume()
    return self.consumeitem
end

return self