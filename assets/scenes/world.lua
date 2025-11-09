return function() local self = {}
    function self:update()
        if ISPRESSED "CANCEL" then
            RELOAD()
        end
    end
    function self:draw()
    end
return self end