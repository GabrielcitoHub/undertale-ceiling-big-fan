return function()
    local self = {}
    self.textboxes = {}
    self.focused = nil

    ------------------------------------------------------------
    -- HELPERS
    ------------------------------------------------------------
    local function splitLines(str)
        local t = {}
        for line in str:gmatch("([^\n]*)\n?") do
            table.insert(t, line)
        end
        return t
    end

    ------------------------------------------------------------
    -- LOOP HELPERS
    ------------------------------------------------------------
    function self:fortextboxes(func, enabled)
        if enabled == nil then enabled = true end
        for i, textbox in ipairs(self.textboxes) do
            if textbox.enabled == enabled then
                func(textbox, i)
            end
        end
    end

    ------------------------------------------------------------
    -- CREATE TEXTBOX
    ------------------------------------------------------------
    function self:new(x, y, w, h, extra)
        extra = extra or {}
        extra.tb = extra.tb or {}

        local text = {
            text = extra.text or "",
            lines = { extra.text or "" }, -- MULTILINE
            scale = 1
        }

        local textbox = {
            x = extra.tb.x or x,
            y = extra.tb.y or y,
            r = extra.tb.rotation or 0,
            w = extra.tb.w or w,
            h = extra.tb.h or h,
            enabled = extra.tb.enabled or true,
            text = text,
            caret = #text.text + 1,
            blink = 0,
            blinkState = true
        }

        table.insert(self.textboxes, textbox)
        return self.textboxes[#self.textboxes]
    end

    ------------------------------------------------------------
    -- UPDATE TEXTBOXES (scale text)
    ------------------------------------------------------------
    function self:update(dt)
        self:fortextboxes(function(tb)
            local text = tb.text
            text.lines = splitLines(text.text)

            local font = love.graphics.getFont()

            -- Caculate longest line
            local maxWidth = 0
            for _, line in ipairs(text.lines) do
                maxWidth = math.max(maxWidth, font:getWidth(line))
            end

            -- Total height
            local totalH = #text.lines * font:getHeight()

            local sx = tb.w / (maxWidth + 10)
            local sy = tb.h / totalH

            text.scale = math.min(sx, sy, 1)
            tb.caret = math.max(1, math.min(#tb.text.text + 1, tb.caret))
            tb.blink = tb.blink + dt
            if tb.blink >= 0.5 then
                tb.blink = 0
                tb.blinkState = not tb.blinkState
            end
        end)
    end

    ------------------------------------------------------------
    -- DRAW
    ------------------------------------------------------------
    function self:draw()
        self:fortextboxes(function(tb, i)
            local text = tb.text
            local scale = text.scale or 1

            -- highlight
            if i == self.focused then
                love.graphics.setColor(1,1,0)
            else
                love.graphics.setColor(1,1,1)
            end
            love.graphics.rectangle("line", tb.x, tb.y, tb.w, tb.h)

            love.graphics.setColor(1,1,1)
            love.graphics.push()
            love.graphics.translate(tb.x + 4, tb.y + 4)
            love.graphics.scale(scale, scale)
            
            -- caret drawing
            if i == self.focused and tb.blinkState then
                local before = text.text:sub(1, tb.caret - 1)
                local cx = love.graphics.getFont():getWidth(before)
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle(
                    "fill",
                    cx, 0,
                    2, love.graphics.getFont():getHeight()
                )
            end

            local font = love.graphics.getFont()
            local lineHeight = font:getHeight()

            -- MULTILINE DRAW
            for li, line in ipairs(text.lines) do
                love.graphics.print(line, 0, (li - 1) * lineHeight)
            end

            love.graphics.pop()
        end)
    end

    ------------------------------------------------------------
    -- CLICK FOCUS
    ------------------------------------------------------------
    function self:mousepressed(mx, my, button)
        if button ~= 1 then return end
        mx, my = MOUSEX(), MOUSEY()
        self.focused = nil

        self:fortextboxes(function(tb, i)
            if mx >= tb.x and mx <= tb.x + tb.w and
               my >= tb.y and my <= tb.y + tb.h then
                self.focused = i
            end
        end)
    end

    ------------------------------------------------------------
    -- TEXT INPUT (normal characters)
    ------------------------------------------------------------
    function self:textinput(t)
        if not self.focused then return end
        local tb = self.textboxes[self.focused]
        local text = tb.text.text

        tb.text.text =
            text:sub(1, tb.caret - 1) ..
            t ..
            text:sub(tb.caret)

        tb.caret = tb.caret + #t
        tb.blink = 0 -- reset blink
    end

    ------------------------------------------------------------
    -- KEY HANDLING
    ------------------------------------------------------------
    function self:keypressed(key)
        if not self.focused then return end
        local tb = self.textboxes[self.focused]
        local text = tb.text.text
        local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

        tb.blinkState = true
        tb.blink = 0

        -- Move caret left
        if key == "left" then
            if ctrl then
                -- skip to previous word
                local pos = tb.caret - 1
                while pos > 1 and text:sub(pos,pos) == " " do pos = pos - 1 end
                while pos > 1 and text:sub(pos,pos) ~= " " do pos = pos - 1 end
                tb.caret = pos
            else
                tb.caret = math.max(1, tb.caret - 1)
            end

        -- Move caret right
        elseif key == "right" then
            if ctrl then
                -- skip to next word
                local pos = tb.caret
                while pos <= #text and text:sub(pos,pos) ~= " " do pos = pos + 1 end
                while pos <= #text and text:sub(pos,pos) == " " do pos = pos + 1 end
                tb.caret = pos
            else
                tb.caret = math.min(#text + 1, tb.caret + 1)
            end

        -- Backspace
        elseif key == "backspace" and tb.caret > 1 then
            tb.text.text =
                text:sub(1, tb.caret - 2) ..
                text:sub(tb.caret)
            tb.caret = tb.caret - 1

        -- Delete
        elseif key == "delete" and tb.caret <= #text then
            tb.text.text =
                text:sub(1, tb.caret - 1) ..
                text:sub(tb.caret + 1)

        -- Clipboard stuff
        elseif key == "c" and ctrl then
            love.system.setClipboardText(text)
        elseif key == "v" and ctrl then
            local paste = love.system.getClipboardText()
            tb.text.text =
                text:sub(1, tb.caret - 1) ..
                paste ..
                text:sub(tb.caret)
            tb.caret = tb.caret + #paste
        end
    end

    function self:keyreleased(key)
        if not self.focused then return end
        if key == "backspace" then
            love.keyboard.setKeyRepeat(false)
        end
    end

    return self
end