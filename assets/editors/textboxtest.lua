return function() local self = {}
    self.debug = require "objects.debug" ()
    self.textboxes = require "objects.textbox" ()
    self.maptextbox = self.textboxes:new(10,10,320,30)
    function self:load()
    end
    function self:update(dt)
        if ISPRESSED("EXIT") then
            --self.debug:print(DEBUG)
            --self.debug:print(self.textboxes.focused)
            if DEBUG and self.textboxes.focused == nil then
                RELOAD()
            end
        end
        self.textboxes:update(dt)
        self.debug:update(dt)
    end
    function self:textinput(t)
        self.textboxes:textinput(t)
    end
    function self:keypressed(key)
        self.textboxes:keypressed(key)
    end
    function self:keyreleased(key)
        self.textboxes:keyreleased(key)
    end
    function self:mousepressed(x,y,button)
        self.textboxes:mousepressed(x,y,button)
    end
    function self:draw()
        self.textboxes:draw()
        self.debug:draw()
    end
return self end