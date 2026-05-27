local self = {}

function self:onclick(soul, state)
    soul = soul or {}
    local item = self or {}
    state = state or {}
    print(soul.name or "nosoul")
    print(item.name or "noitem")
    print(state.souls or "nostate")

    return false
end

function self:consume()
    return false
end

return self