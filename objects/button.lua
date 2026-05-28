return function()local self = {}
    self.buttons = {}
---@param id string
---@param x number|nil
---@param y number|nil
---@param width number|nil
---@param height number|nil
---@return BUTTON
    function self:new(id,x,y,width,height)
        width = width or 75
        height = height or 75
        x = x or 0
        y = y or 0

        local manager = self
---@class BUTTON
        local button = {
            id = id,
            x = x,
            y = y,
            width = width,
            height = height,
            pressed = false,
            presses = 0
        }

        function button:update()
            manager:updateButton(self)
        end

        function button:draw()
            manager:drawButton(self)
        end

        -- Utils functions

---@return string
        function button:getID()
            return self.id
        end

---@return boolean
        function button:isDown()
            return self.pressed
        end

---@return number
        function button:getPresses()
            return self.presses
        end

---@return number, number
        function button:getPosition()
            return self.x, self.y
        end

---@return number
        function button:getX()
            return self.x
        end

        ---@return number
        function button:getY()
            return self.y
        end

---@return number, number
        function button:getSize()
            return self.width, self.height
        end

---@return number
        function button:getWidth()
            return self.width
        end

---@return number
        function button:getHeight()
            return self.width
        end

        self.buttons[id] = button

        return self.buttons[id]
    end

    ---@param button BUTTON
    function self:updateButton(button)
        local mx,my = MOUSEX(), MOUSEY()
        if mx >= button.x and mx <= button.x + button.width and
            my >= button.y and my <= button.y + button.height then
            button.pressed = love.mouse.isDown(1)
        else
            button.pressed = false
        end
    end

    function self:updatebuttons()
        for id,button in pairs(self.buttons) do
            self:updateButton(button)
        end
    end

    ---@param button BUTTON
    function self:drawButton(button)
        love.graphics.setFont(FONT "fnt_default")
        love.graphics.setColor(1, 1, button.pressed and 0 or 1,button.pressed and 1 or 0.4)

        local scaleX, scaleY = 1.4, 1.6

        if DEBUG then
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
            love.graphics.print(button.id, button.x, button.y, 0, button.width / 45, button.height / 45)
            love.graphics.print(tostring(button.pressed), button.x, button.y + 20, 0, button.width / 45, button.height / 45)
            love.graphics.print(tostring(button.presses), button.x, button.y + 40, 0, button.width / 45, button.height / 45)
        else
            local layout = IMAGE "mobile/layout"
            love.graphics.draw(layout, button.x, button.y, 0, button.width / layout:getWidth(), button.height / layout:getHeight())

            local id = string.lower(button.id)
            local special = {
                up = {
                    id = "arrow",
                    r = math.rad(-90),
                    ox = 16,
                },
                down = {
                    id = "arrow",
                    r = math.rad(90),
                    ox = -4,
                    oy = 14,
                },
                left = {
                    id = "arrow",
                    r = math.rad(180),
                    ox = 16,
                    oy = 16,
                },
                right = {
                    id = "arrow",
                    r = 0,
                }
            }
            
---@diagnostic disable-next-line: cast-local-type
            id = special[id] or id
            local image
            local r = 0
            local ox = 0
            local oy = 0
            if not id.id then
                image = IMAGE("mobile/" .. id)
            else
                image = IMAGE("mobile/" .. id.id)
                r = id.r
                ox = id.ox or ox
                oy = id.oy or oy
            end
            
            if image then
                love.graphics.draw(image, button.x + layout:getWidth() - image:getWidth() / 2, button.y + layout:getHeight() - image:getHeight() / 2, r, scaleX, scaleY, ox * scaleX, oy * scaleY)
            end
        end

        love.graphics.setColor(1, 1, 1, 1)
    end

    function self:drawbuttons()
        for id,button in pairs(self.buttons) do
            self:drawButton(button)
        end
    end

    function self:update(dt)
        self:updatebuttons()
    end

    function self:draw()
        self:drawbuttons()
    end

    -- Utils functions

    ---@param id string|nil
    ---@return BUTTON|nil
    function self:getButton(id)
        if type(id) == "string" then
            return self.buttons[id]
        end

        return id
    end

    ---@param id string|nil
    ---@return boolean
    function self:isDown(id)
        local button = self:getButton(id)
        if button.pressed == true then
            return true
        else
            return false
        end
    end

    ---@param id string|nil
    ---@return string|nil
    function self:getID(id)
        local button = self:getButton(id)
        if button then
            return button.id
        end
    end
return self end