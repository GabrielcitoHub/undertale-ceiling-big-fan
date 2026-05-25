---@param soul Soul
---@param x number|nil
---@param y number|nil
return function(soul, x, y)
---@class SoulName
    local self = {}
    self.x = x or 30
    self.y = y or 400
    self.hidden = false

    function self:update()
    end

    function self:draw()
        if self.hidden then return end
        love.graphics.setFont(FONT "fnt_karma_big")
        love.graphics.print(soul.name .. "   LV " .. soul.love, self.x, self.y)
    end
return self end