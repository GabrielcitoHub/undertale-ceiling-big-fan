return function() local self = {}
    function self:load()
        self.character = require "objects.character"
        local char = self.character()
        char.canrun = true
        self.characters = {char}
    end
    function self:update(dt)
        if ISPRESSED "CANCEL" then
            if DEBUG then
                RELOAD()
            end
        end
        for i,char in ipairs(self.characters) do
            char:update(dt)
        end
    end
    function self:draw()
        for i,char in ipairs(self.characters) do
            char:draw()
        end
    end
return self end