return function() local self = {}
    self.rooms = {}
    function self:getroom(path, active)
        local room = require(path) ()
        room.active = room.active or active or true
        return room
    end
    function self:room(name)
        self.rooms[name] = self:getroom()
    end
    function self:forrooms(func, active)
        if type(active) ~= "boolean" then active = true end
        for _,room in pairs(self.rooms) do
            if room.active == active then
                func(room)
            end
        end
    end
    function self:update(dt)
        self:forrooms(function(room)
            room:update(dt)
        end)
    end
    function self:draw()
        self:forrooms(function(room)
            room:draw()
        end)
    end
return self end