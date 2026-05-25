local self = {}

function self:onclick(soul, item, state)
    soul = soul or {}
    item = item or {}
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