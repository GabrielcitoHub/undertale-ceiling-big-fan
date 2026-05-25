return function()
---@class Debug
    local self = {}
    self.prints = {}

    function self:print(...)
        local i = 1
        local msg = tostring(...)
        local printdata = {
            text = msg,
            duration = 2 + (0.5 * #self.prints)
        }
        
        table.insert(self.prints,i,printdata)
    end

---@param dt number
    function self:update(dt)
        local removemsgs = {}
        for i,msg in pairs(self.prints) do
            msg.duration = msg.duration - 1 * dt
            if msg.duration < 0 then
                table.insert(removemsgs,i)
            end
        end

        for _,rmsgi in pairs(removemsgs) do
            table.remove(self.prints,rmsgi)
        end
    end

    function self:draw()
        for i,msg in ipairs(self.prints) do
            love.graphics.setColor(1,1,1,msg.duration/1)
            love.graphics.print(msg.text,0,20*(i-1))
        end

        love.graphics.setColor(1,1,1,1)
    end
return self end